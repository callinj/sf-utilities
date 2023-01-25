public with sharing class JCFeedbackController {
	// TODO Write test class
	public class FeedbackResponse extends JCResponse {
		@AuraEnabled
		public List<FeedbackWrapper> results { get; set; }
		@AuraEnabled
		public FeedbackStats stats { get; set; }
		@AuraEnabled
		public Integer totalResults { get; set; }
		@AuraEnabled
		public Map<String, Integer> offsets { get; set; }
		public FeedbackResponse() {
			super();
			results = new List<FeedbackWrapper>();
			totalResults = 0;
			offsets = new Map<String, Integer>();
		}
	}
	// TODO | Change to RecordWrapper
	public class FeedbackWrapper implements Comparable {
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String recordUrl { get; set; }
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String provider { get; set; }
		@AuraEnabled
		public String receiver { get; set; }
		@AuraEnabled
		public String information { get; set; }
		@AuraEnabled
		public Datetime createdDate { get; set; } // TODO | Update this to 'date'
		@AuraEnabled
		public Datetime mainDate { get; set; }
		@AuraEnabled
		public String objectName { get; set; }

		public Integer compareTo(Object compareTo) {
			FeedbackWrapper otherWrapper = (FeedbackWrapper) compareTo;
			Integer returnValue = 0;
			if (createdDate < otherWrapper.createdDate) {
				returnValue = 1;
			} else if (createdDate > otherWrapper.createdDate) {
				returnValue = -1;
			}
			return returnValue;
		}
	}
	public class FeedbackStats {
		@AuraEnabled
		public Integer given { get; set; }
		@AuraEnabled
		public Integer received { get; set; }
	}

	// TODO Write try catch for method
	// TODO Add Javadoc
	@AuraEnabled(cacheable=true)
	public static FeedbackResponse getFeedbackItems(JCQueryHelper.QueryObject searchOptions) {
		FeedbackResponse response = new FeedbackResponse();
		try {
			for (Feedback__c item : (List<Feedback__c>) searchOptions.getResults()) {
				FeedbackWrapper wrapper = new FeedbackWrapper();
				wrapper.id = item.Id;
				wrapper.name = item?.Title__c;
				wrapper.provider = item?.Provider__r.Name;
				wrapper.receiver = item?.Receiver__r.Name;
				wrapper.createdDate = item?.CreatedDate;
				wrapper.mainDate = item?.InteractionDate__c;
				wrapper.recordUrl = '/detail/' + item.Id;
				response.results.add(wrapper);
			}
			response.totalResults = searchOptions.getTotalResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(
				'There was an error while processing your request. Please take note of the time and contact your system administrator.'
			);
		}
		return response;
	}

	@AuraEnabled(cacheable=true)
	public static FeedbackResponse getSharedFeedback(JCQueryHelper.QueryObject searchOptions) {
		FeedbackResponse response = new FeedbackResponse();

		try {
			for (Feedback__Share item : (List<Feedback__Share>) searchOptions.getResults()) {
				FeedbackWrapper wrapper = new FeedbackWrapper();
				wrapper.id = item.Id;
				wrapper.name = item?.Parent.Title__c;
				wrapper.createdDate = item?.LastModifiedDate;
				wrapper.recordUrl = '/detail/' + item.ParentId;
				wrapper.objectName = searchOptions.objectName;
				response.results.add(wrapper);
			}
			response.totalResults = searchOptions.getTotalResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
		}

		return response;
	}

	// TODO - Refactor - Select one option from below
	// TODO - (1) Change to getShareRecords(List<JCQueryHelper.QueryObject>, userId); if userId is null, get currentUser
	// TODO - (2) Change to getShareRecords(List<JCQueryHelper.QueryObject>);
	@AuraEnabled(cacheable=true)
	public static FeedbackResponse getSharedWithMe(
		JCQueryHelper.QueryObject feedbackOptions,
		JCQueryHelper.QueryObject goalOptions
	) {
		FeedbackResponse response = new FeedbackResponse();
		Map<String, Integer> offsetMap = new Map<String, Integer>();
		List<FeedbackWrapper> wrappers = new List<FeedbackWrapper>();

		Integer queryLimit = Integer.valueOf(feedbackOptions.queryLimit);

		try {
			// TODO | Change to RecordWrapper types
			// Query through Feedback records
			for (Feedback__Share item : (List<Feedback__Share>) feedbackOptions.getResults()) {
				FeedbackWrapper wrapper = new FeedbackWrapper();
				wrapper.id = item.Id;
				wrapper.name = item?.Parent.Title__c;
				wrapper.createdDate = item?.LastModifiedDate;
				wrapper.recordUrl = '/detail/' + item.ParentId;
				wrapper.objectName = feedbackOptions.objectName;
				wrappers.add(wrapper);
			}

			// TODO | Change to RecordWrapper types
			// Query through Goal records
			for (Goal__Share item : (List<Goal__Share>) goalOptions.getResults()) {
				FeedbackWrapper wrapper = new FeedbackWrapper();
				wrapper.id = item.Id;
				wrapper.name = item?.Parent.Title__c + ': ' + item?.Parent.Name;
				wrapper.createdDate = item?.LastModifiedDate;
				wrapper.recordUrl = '/detail/' + item?.ParentId;
				wrapper.objectName = goalOptions.objectName;
				wrappers.add(wrapper);
			}
			wrappers.sort();

			Integer loopSize = wrappers.size() < queryLimit ? wrappers.size() : queryLimit;

			for (Integer i = 0; i < loopSize; i++) {
				response.results.add(wrappers[i]);
				final String currentObjectName = wrappers[i].objectName;

				if (offsetMap.containsKey(currentObjectName)) {
					offsetMap.put(currentObjectName, offsetMap.get(currentObjectName) + 1);
				} else {
					offsetMap.put(currentObjectName, 1);
				}
			}

			response.offsets = offsetMap;
			response.totalResults = feedbackOptions.getTotalResults() + goalOptions.getTotalResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage() + ' - Line Numbers: ' + e.getLineNumber());
		}

		return response;
	}

	@AuraEnabled(cacheable=true)
	public static FeedbackResponse getMyFeedbackStats(String type) {
		FeedbackResponse response = new FeedbackResponse();
		try {
			type = type?.toLowerCase();
			List<String> fields = new List<String>{ 'Id' };
			JCQueryHelper.QueryObject receivedQueryObject = JCQueryHelper.createQueryObject('Feedback__c', fields);
			JCQueryHelper.QueryObject givenQueryObject = JCQueryHelper.createQueryObject('Feedback__c', fields);
			List<JCQueryHelper.QueryFilter> additionalFilters = new List<JCQueryHelper.QueryFilter>();

			receivedQueryObject.addFilter('Receiver__c', UserInfo.getUserId(), 'AND', '=');
			givenQueryObject.addFilter('Provider__c', UserInfo.getUserId(), 'AND', '=');

			if (type == 'feedback') {
				additionalFilters.add(
					new JCQueryHelper.QueryFilter('RecordType.DeveloperName', 'Feedback', 'AND', '=')
				);
				// additionalFilters.add(new JCQueryHelper.QueryFilter('CreatedDate', 'THIS_FISCAL_YEAR', 'AND', '='));
			} else {
				// additionalFilters.add(new JCQueryHelper.QueryFilter('InteractionDate__c', 'THIS_FISCAL_YEAR', 'AND', '='));
				additionalFilters.add(
					new JCQueryHelper.QueryFilter('RecordType.DeveloperName', 'Conversation', 'AND', '=')
				);
			}
			receivedQueryObject.addFilters(additionalFilters);
			givenQueryObject.addFilters(additionalFilters);
			FeedbackStats stats = new FeedbackStats();

			stats.received = receivedQueryObject.getTotalResults();
			stats.given = givenQueryObject.getTotalResults();
			response.stats = stats;
		} catch (Exception e) {
			response.success = false;
			response.messages.add(
				'There was an error while processing your request. Please take note of the time and contact your system administrator.'
			);
		}

		return response;
	}

	@AuraEnabled(cacheable=true)
	public static FeedbackResponse pendingRequests(JCQueryHelper.QueryObject searchOptions) {
		FeedbackResponse response = new FeedbackResponse();

		for (Feedback_Request__c item : (List<Feedback_Request__c>) searchOptions.getResults()) {
			FeedbackWrapper wrapper = new FeedbackWrapper();
			wrapper.id = item.Id;
			wrapper.name = item.Name;
			wrapper.information = item.RequestText__c;
			wrapper.createdDate = item.CreatedDate;
			wrapper.recordUrl = '/detail/' + item.Id;
			response.results.add(wrapper);
		}
		response.totalResults = searchOptions.getTotalResults();
		return response;
	}

	public static void sendNotifications(String parentId, String userId) {
		// Grab share record associated to parentId and userId
		Feedback__Share shareRecord = [
			SELECT Id, Parent.RecordType.DeveloperName, UserOrGroup.Name, LastModifiedBy.Name
			FROM Feedback__Share
			WHERE ParentId = :parentId AND UserOrGroupId = :userId AND RowCause = 'Manual'
		];

		CustomNotificationType notificationType = [
			SELECT Id, DeveloperName
			FROM CustomNotificationType
			WHERE DeveloperName = 'Feedback_Notification'
		];
		EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name = 'Feedback Share Email Template'];

		JCUtils.sendNotification(
			'JC Performance Tool: New Shared ' +
			(shareRecord.Parent.RecordType.DeveloperName == 'Self'
				? 'Self-Reflection'
				: shareRecord.Parent.RecordType.DeveloperName),
			shareRecord.LastModifiedBy.Name +
				' has granted you access to view a ' +
				(shareRecord.Parent.RecordType.DeveloperName == 'Self'
					? 'self-reflection.'
					: shareRecord.Parent.RecordType.DeveloperName.toLowerCase() + ' item.'),
			notificationType.Id,
			parentId,
			userId
		);
		JCUtils.sendEmail(new List<String>{ userId }, userId, emailTemplate.Id, parentId);
		QueryResult qResult = connection.queryAll(
			'SELECT Id, SystemModstamp FROM ' + 'Account WHERE IsDeleted=true ' + 'ORDER BY SystemModstamp DESC LIMIT 5'
		);

		String[] Ids = new List<String>(qResult.getSize());
		// Get the IDs of the deleted records
		for (int i = 0; i < qResult.getSize(); i++) {
			Ids[i] = qResult.getRecords()[i].getId();
		}

		// Restore the records
		UndeleteResult[] undelResults = connection.undelete(Ids);

		// Check the results
		for (UndeleteResult result : undelResults) {
			if (result.isSuccess()) {
				System.out.println('Undeleted Account ID: ' + result.getId());
			} else {
				if (result.getErrors().length > 0) {
					System.out.println('Error message: ' + result.getErrors()[0].getMessage());
				}
			}
		}
	}
}
