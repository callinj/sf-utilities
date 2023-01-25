public with sharing class JCGoalController {
	public class GoalResponse extends JCResponse {
		@AuraEnabled
		public List<GoalWrapper> results { get; set; }
		@AuraEnabled
		public Integer totalResults { get; set; }
		public GoalResponse() {
			super();
			results = new List<GoalWrapper>();
			totalResults = 0;
		}
	}
	// TODO | Change to RecordWrapper
	public class GoalWrapper {
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String status { get; set; }
		@AuraEnabled
		public String recordUrl { get; set; }
		@AuraEnabled
		public Datetime createdDate { get; set; }
	}
	@AuraEnabled(cacheable=true)
	public static GoalResponse getGoals(JCQueryHelper.QueryObject searchOptions) {
		GoalResponse response = new GoalResponse();
		try {
			for (Goal__c item : (List<Goal__c>) searchOptions.getResults()) {
				GoalWrapper wrapper = new GoalWrapper();
				wrapper.id = item.Id;
				wrapper.name = item?.Name;
				wrapper.status = item.Status__c;
				wrapper.recordUrl = '/detail/' + item.Id;
				wrapper.createdDate = item.CreatedDate;
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
	public static GoalResponse getSharedGoals(JCQueryHelper.QueryObject searchOptions) {
		GoalResponse response = new GoalResponse();

		try {
			for (Goal__Share item : (List<Goal__Share>) searchOptions.getResults()) {
				GoalWrapper wrapper = new GoalWrapper();
				wrapper.id = item.Id;
				wrapper.name = item?.Parent.Title__c + ': ' + item?.Parent.Name;
				wrapper.createdDate = item?.LastModifiedDate;
				wrapper.recordUrl = '/detail/' + item.ParentId;
				response.results.add(wrapper);
			}
			response.totalResults = searchOptions.getTotalResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
		}

		return response;
	}

	public static void sendNotifications(String parentId, String userId) {
		// Grab share record associated to parentId and userId
		Goal__Share shareRecord = [
			SELECT Id, Parent.RecordType.DeveloperName, UserOrGroup.Name, LastModifiedBy.Name
			FROM Goal__Share
			WHERE ParentId = :parentId AND UserOrGroupId = :userId AND RowCause = 'Manual'
		];

		CustomNotificationType notificationType = [
			SELECT Id, DeveloperName
			FROM CustomNotificationType
			WHERE DeveloperName = 'Feedback_Notification'
		];
		EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name = 'Goal Share Email Template'];

		JCUtils.sendNotification(
			'JC Performance Tool: New Shared ' + shareRecord.Parent.RecordType.DeveloperName + ' Item',
			shareRecord.LastModifiedBy.Name +
				' has granted you access to view a ' +
				shareRecord.Parent.RecordType.DeveloperName.toLowerCase() +
				' item.',
			notificationType.Id,
			parentId,
			userId
		);
		JCUtils.sendEmail(new List<String>{ userId }, userId, emailTemplate.Id, parentId);
	}
}
