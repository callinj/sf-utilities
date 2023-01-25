public with sharing class JCPermissionUtils {
	static Set<String> shareSortOrder = new Set<String>();
	public class PermissionResponse extends JCResponse {
		@AuraEnabled
		public Map<String, PermissionWrapper> results { get; set; }
		public PermissionResponse() {
			super();
			results = new Map<String, PermissionWrapper>();
		}
	}
	public class ShareResponse extends JCResponse {
		@AuraEnabled
		public List<ShareWrapper> results { get; set; }
		public String shareObjectName { get; set; }
		public ShareResponse() {
			super();
			results = new List<ShareWrapper>();
			shareObjectName = null;
		}
	}
	public class PermissionWrapper {
		@AuraEnabled
		public Boolean hasAll { get; set; }
		@AuraEnabled
		public Boolean hasDelete { get; set; }
		@AuraEnabled
		public Boolean hasEdit { get; set; }
		@AuraEnabled
		public Boolean hasTransfer { get; set; }
		@AuraEnabled
		public Boolean hasRead { get; set; }
		@AuraEnabled
		public Boolean hasShare { get; set; }
		public PermissionWrapper() {
			hasAll = false;
			hasDelete = false;
			hasEdit = false;
			hasTransfer = false;
			hasRead = false;
			hasShare = false;
		}
	}
	public class ShareWrapper implements Comparable {
		@AuraEnabled
		public JCWrapper.Person sharedWith { get; set; }
		@AuraEnabled
		public String level { get; set; }
		@AuraEnabled
		public ShareReason reason { get; set; }
		@AuraEnabled
		public JCWrapper.Person whoShared { get; set; }
		@AuraEnabled
		public Datetime sharedDatetime { get; set; }
		public ShareWrapper() {
			sharedWith = new JCWrapper.Person();
			whoShared = new JCWrapper.Person();
			level = 'Read';
			reason = new ShareReason();
			sharedDatetime = null;
		}
		public Integer compareTo(Object compareObject) {
			ShareWrapper compared = (ShareWrapper) compareObject;
			List<String> sortList = new List<String>(shareSortOrder);
			Integer returnValue = 0;
			if (sortList.contains(reason.value)) {
				if (sortList.indexOf(reason.value) < sortList.indexOf(compared.reason.value)) {
					returnValue = -1;
				} else {
					returnValue = 1;
				}
			} else {
				returnValue = 1;
			}
			return returnValue;
		}
	}
	public class ShareReason {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }
		public ShareReason(String reasonLabel, String reasonValue) {
			label = reasonLabel;
			value = reasonValue;
		}
		public ShareReason() {
			label = null;
			value = null;
		}
	}
	public class PermissionException extends Exception {
	}
	@AuraEnabled(cacheable=true)
	public static PermissionResponse recordPermissionsForUser(Object recordIds, String userId) {
		PermissionResponse response = new PermissionResponse();
		try {
			List<String> recordIdList = JCUtils.convertToStringList(recordIds);
			userId = userId != null ? userId : UserInfo.getUserId();
			List<String> fields = new List<String>{
				'RecordId',
				'HasAllAccess',
				'HasDeleteAccess',
				'HasEditAccess',
				'HasTransferAccess',
				'HasReadAccess'
			};
			JCQueryHelper.QueryObject queryInfo = JCQueryHelper.createQueryObject('UserRecordAccess', fields);
			queryInfo.addFilter('UserId', userId, 'AND', '=');
			queryInfo.addFilter('RecordId', recordIdList, 'AND', 'IN');
			for (UserRecordAccess recordAccess : (List<UserRecordAccess>) queryInfo.getResults()) {
				PermissionWrapper wrapper = new PermissionWrapper();
				wrapper.hasAll = recordAccess.HasAllAccess;
				wrapper.hasDelete = recordAccess.HasDeleteAccess;
				wrapper.hasEdit = recordAccess.HasEditAccess;
				wrapper.hasTransfer = recordAccess.HasTransferAccess;
				wrapper.hasRead = recordAccess.HasReadAccess;
				response.results.put(recordAccess.RecordId, wrapper);
			}
		} catch (JCUtils.TypeException te) {
			response.success = false;
			response.messages.add(te.getMessage());
		} catch (Exception e) {
			response.success = false;
			response.messages.add(
				'There was an error while processing your request. Please take note of the time and contact your system administrator.'
			);
		}
		return response;
	}
	@AuraEnabled(cacheable=true)
	public static PermissionResponse checkUserCanShare(
		String recordId,
		String userId,
		String validLevel,
		List<String> validReasons
	) {
		PermissionResponse response = new PermissionResponse();
		try {
			// List<String> validReasonsList = JCUtils.convertToStringList(validReasons);
			userId = userId != null ? userId : UserInfo.getUserId();
			if (validReasons.indexOf('Manual') != -1) {
				validReasons.remove(validReasons.indexOf('Manual'));
			}
			JCQueryHelper.QueryObject shareQueryObject = getShareQueryObject(recordId, validReasons, validLevel);
			shareQueryObject.queryLimit = 1;
			shareQueryObject.addFilter('UserOrGroupId', userId);
			List<SObject> results = shareQueryObject.getResults();
			if (results.size() > 0) {
				PermissionWrapper wrapper = new PermissionWrapper();
				wrapper.hasShare = true;
				response.results.put(recordId, wrapper);
			}
		} catch (JCUtils.TypeException te) {
			response.success = false;
			response.messages.add(te.getMessage());
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
		}

		return response;
	}
	@AuraEnabled(cacheable=true)
	public static ShareResponse recordPermissionList(String recordId, List<String> customSortOrder) {
		ShareResponse response = new ShareResponse();
		if (customSortOrder != null) {
			shareSortOrder = new Set<String>(customSortOrder);
		}
		// sortOrder.add('Manual');
		try {
			List<String> sortList = new List<String>(shareSortOrder);
			Map<String, ShareWrapper> userShareMap = new Map<String, ShareWrapper>();
			JCQueryHelper.QueryObject shareQueryObject = getShareQueryObject(recordId, sortList, null);
			List<Schema.PicklistEntry> rowCauses = Schema.getGlobalDescribe()
				.get(shareQueryObject.objectName)
				.getDescribe()
				.fields.getMap()
				.get('rowCause')
				.getDescribe()
				.getPicklistValues();
			for (SObject shareRecord : shareQueryObject.getResults()) {
				Map<String, Object> castedRecord = (Map<String, Object>) JSON.deserializeUntyped(
					JSON.serialize(shareRecord)
				);
				ShareWrapper wrapper = new ShareWrapper();
				wrapper.sharedWith = new JCWrapper.Person((Map<String, Object>) castedRecord.get('UserOrGroup'));
				wrapper.whoShared = new JCWrapper.Person((Map<String, Object>) castedRecord.get('LastModifiedBy'));
				// BUG Fix to support out of the box objects
				wrapper.level = (String) shareRecord.get('AccessLevel');
				wrapper.sharedDatetime = (Datetime) shareRecord.get('LastModifiedDate');
				for (Schema.PicklistEntry cause : rowCauses) {
					String shareCause = (String) shareRecord.get('RowCause');
					if (cause.getValue() == shareCause) {
						wrapper.reason = new ShareReason(cause.getLabel(), shareCause);
					}
				}
				String mapKey = wrapper.sharedWith.id;
				if (!userShareMap.containsKey(mapKey)) {
					userShareMap.put(mapKey, wrapper);
				} else {
					if (
						sortList.indexOf(userShareMap.get(mapKey)?.reason?.value) <
						sortList.indexOf(wrapper.reason?.value)
					) {
						userShareMap.get(mapKey).reason = wrapper.reason;
					}
				}
			}
			response.results = userShareMap.values();
			response.results.sort();
		} catch (JCUtils.TypeException te) {
			response.success = false;
			response.messages.add(te.getMessage());
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
			throw e;
		}
		return response;
	}
	@TestVisible
	private static JCQueryHelper.QueryObject getShareQueryObject(
		String recordId,
		List<String> sortList,
		String validLevel
	) {
		// Schema.DescribeSObjectResult objectDescribe = Id.valueOf(recordId)?.getSObjectType().getDescribe();
		String objectName = Id.valueOf(recordId)?.getSObjectType().getDescribe().getName();
		String accessField = 'AccessLevel';
		String parentField = '';
		String accessFieldHolder;
		if (objectName.contains('__c')) {
			objectName = objectName.replaceAll('__c', '__');
			parentField = 'ParentId';
		} else {
			accessField = objectName + accessField;
			parentField = objectName + 'Id';
		}
		String shareObjectName = objectName + 'Share';
		JCQueryHelper.QueryObject shareQueryObject = JCQueryHelper.createQueryObject(
			shareObjectName,
			'Id, RowCause, UserOrGroup.Name, LastModifiedBy.Name, LastModifiedDate, ' + accessField
		);
		shareQueryObject.addFilter(parentField, recordId);
		// BUG Fix to support out of the box objects
		if (validLevel != null) {
			shareQueryObject.addFilter(accessField, getValidLevels(validLevel), 'AND', 'IN');
		}
		if (sortList != null) {
			shareQueryObject.addFilter('RowCause', sortList, 'And', 'IN');
		}
		return shareQueryObject;
	}
	private static List<String> getValidLevels(String validLevel) {
		List<String> validLevels = new List<String>();
		List<Schema.PicklistEntry> levels = UserRecordAccess.sObjectType.getDescribe()
			.fields.getMap()
			.get('MaxAccessLevel')
			.getDescribe()
			.getPicklistValues();
		Boolean found = false;
		for (Schema.PicklistEntry level : levels) {
			String levelValue = level.getValue();
			if (!found) {
				found = levelValue == validLevel;
			}
			if (found) {
				validLevels.add(levelValue);
			}
		}
		return validLevels;
	}
}
