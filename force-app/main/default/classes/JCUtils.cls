public with sharing class JCUtils {
	public class FiscalYearResponse extends JCResponse {
		@AuraEnabled
		public String fiscalYear { get; set; }
		public FiscalYearResponse() {
			super();
		}
	}
	public class TypeException extends Exception {
	}
	public static String getType(Object variable) {
		String variableType = variable != null ? 'Object' : '';
		if (variable instanceof SObject) {
			variableType = ((SObject) variable).getSObjectType().getDescribe().getName() + '';
		} else if (variable instanceof Boolean) {
			variableType = 'Boolean';
		} else if (variable instanceof Id) {
			variableType = 'Id';
		} else if (variable instanceof String) {
			String variableString = (String) variable;
			String variableUpperString = variableString.toUpperCase();
			if (variableUpperString.contains('SELECT') && variableUpperString.contains('FROM')) {
				variableType = 'SOQL';
			} else {
				variableType = 'String';
			}
		} else if (variable instanceof Blob) {
			variableType = 'Blob';
		} else if (variable instanceof Date) {
			variableType = 'Date';
		} else if (variable instanceof Datetime) {
			variableType = 'Datetime';
		} else if (variable instanceof Time) {
			variableType = 'Time';
		} else if (variable instanceof Integer) {
			variableType = 'Integer';
		} else if (variable instanceof Long) {
			variableType = 'Long';
		} else if (variable instanceof Decimal) {
			variableType = 'Decimal';
		} else if (variable instanceof Double) {
			variableType = 'Double';
		} else {
			if (variableType != '') {
				variableType = getCollectionType(variable);
			}
		}
		return variableType;
	}
	public static String getCollectionType(Object input) {
		String response = 'Object';
		Object test;
		try {
			test = (List<Object>) input;
			response = 'List';
		} catch (System.TypeException ex) {
			String message = ex.getMessage();
			if (message.contains('Set<')) {
				response = 'Set';
			} else if (message.contains('Map<')) {
				response = 'Map';
			}
		}
		return response;
	}
	public static String stripQuotes(String stringValue) {
		return stringValue.replaceAll('"', '\'').replaceAll('\'', '');
	}
	public static String addQuotes(String stringValue) {
		String tempValue = stringValue.replaceAll('"', '\'');
		return !Pattern.matches('^\'[^"]+\'$', tempValue) ? '\'' + tempValue + '\'' : tempValue;
	}
	// TODO | Add this method to FeedbackController and GoalController and then call this - return shareRecord
	@AuraEnabled
	public static JCResponse shareRecord(Id parentId, Id userId) {
		JCResponse response = new JCResponse();
		try {
			// if (JCPermissionUtils.recordPermissionsForUser(parentId, userId)?.results?.get(parentId).hasRead) {
			// 	throw new JCPermissionUtils.PermissionException('User already has access to this record');
			// }
			String objectName = String.valueOf(parentId.getSobjectType());
			Boolean isCustom = objectName.contains('__c');
			String shareObjectName = objectName.replaceAll('__c', '__') + 'Share';
			SObject shareObject = Schema.getGlobalDescribe().get(shareObjectName).newSObject(null, true);
			shareObject.put('UserOrGroupId', userId);
			if (isCustom) {
				shareObject.put('ParentId', parentId);
				shareObject.put('AccessLevel', 'Read');
			} else {
				shareObject.put(objectName + 'Id', parentId);
				shareObject.put(objectName + 'AccessLevel', 'Read');
			}
			insert Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ shareObject }).getRecords();
			switch on shareObjectName {
				when 'Goal__Share' {
					// TODO | Pass shareObject instead of parentId
					JCGoalController.sendNotifications(parentId, userId);
				}
				when 'Feedback__Share' {
					// TODO | Pass shareObject instead of parentId
					JCFeedbackController.sendNotifications(parentId, userId);
				}
			}
		} catch (Exception e) {
			System.debug('Error creating share record: ' + e.getMessage());
			response.success = false;
			response.messages.add(e.getMessage());
		}
		return response;
	}

	// TODO | Create test method for this - How can you assert a custom notification?
	public static void sendNotification(
		String title,
		String body,
		String notificationTypeId,
		String recordId,
		String userId
	) {
		try {
			Messaging.CustomNotification notification = new Messaging.CustomNotification();
			notification.setTitle(title);
			notification.setBody(body);
			notification.setNotificationTypeId(notificationTypeId);
			notification.setTargetId(recordId);
			notification.send(new Set<String>{ userId });
		} catch (Exception e) {
			System.debug('Error sending notification: ' + e.getMessage());
		}
	}

	public static void sendEmail(List<String> toAddresses, String targetObjectId, String templateId, String whatId) {
		String emailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'My JC Notification Tool']?.Id;

		try {
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
			mail.setTargetObjectId(targetObjectId);
			mail.setTemplateID(templateId);
			mail.setSaveAsActivity(false);
			mail.setWhatId(whatId);
			mail.setOrgWideEmailAddressId(emailId);
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
		} catch (Exception e) {
			System.debug('Error sending email: ' + e.getMessage());
		}
	}
	public static List<String> convertToStringList(Object data) {
		List<String> stringList = new List<String>();
		String type = JCUtils.getType(data);
		switch on type {
			when 'String', 'Id' {
				stringList = String.valueOf(data).replace(' ', '').split(',');
			}
			when 'List' {
				stringList = (List<String>) data;
			}
			when else {
				throw new TypeException(
					'There was an error while processing your request. recordIds must be of type List<String>, String or Id.'
				);
			}
		}
		return stringList;
	}

	@AuraEnabled(cacheable=true)
	public static FiscalYearResponse getFiscalYear() {
		FiscalYearResponse response = new FiscalYearResponse();
		try {
			FiscalYearSettings fiscalYear = [
				SELECT Name
				FROM FiscalYearSettings
				WHERE StartDate = THIS_FISCAL_YEAR
				LIMIT 1
			];
			response.fiscalYear = 'FY' + String.valueOf(fiscalYear.get('Name')).substring(2);
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage() + ' - Line Numbers: ' + e.getLineNumber());
		}
		return response;
	}
	/**
	 * This method checks if a field on a record has changed.
	 *
	 * @author Joe Callin
	 * @param oldRecord This is the record with the previous values set
	 * @param oldRecord This is the record with the new values set
	 * @param fieldAPIName This is string of the field api name that should be checked if changed
	 * @return Boolean value of whether the specified field was changed
	 * @since 1.0
	 */
	public static Boolean fieldChanged(SObject oldRecord, SObject newRecord, String fieldAPIName) {
		return oldRecord.get(fieldAPIName) != newRecord.get(fieldAPIName);
	}
}
