public with sharing class JCTalentDecisionUpdateBatch implements Database.Batchable<sObject> {
	private List<String> rosterIds;
	private String actionType;

	public JCTalentDecisionUpdateBatch(List<String> ids, String type) {
		rosterIds = ids;
		actionType = type;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject(
			'Talent_Decision__c',
			'Id, Finalized__c'
		);
		searchOptions.addFilter('Roster__c', rosterIds, 'AND', 'IN');

		if (Test.isRunningTest()) {
			searchOptions.queryLimit = 200;
		}

		// collect the batches of records or objects to be passed to execute
		return Database.getQueryLocator(searchOptions.queryString());
	}

	public void execute(Database.BatchableContext bc, List<Talent_Decision__c> records) {
		try {
			List<Talent_Decision__c> updatedRecords = new List<Talent_Decision__c>();

			for (Talent_Decision__c decision : records) {
				decision.Finalized__c = !decision.Finalized__c;
				updatedRecords.add(decision);
			}

			update updatedRecords;
		} catch (Exception e) {
			System.debug('JCTalentDecisionUpdateBatch Exception: ' + e.getMessage());
		}
	}

	public void finish(Database.BatchableContext bc) {
		String adminConsole = '{ type: \'standard__app\', attributes: { appTarget: \'c__PA_Admin_Console\',}}';

		CustomNotificationType notificationType = [
			SELECT Id, DeveloperName
			FROM CustomNotificationType
			WHERE DeveloperName = 'Feedback_Notification'
		];
		EmailTemplate emailTemplate = [
			SELECT Id
			FROM EmailTemplate
			WHERE DeveloperName = 'Talent_Decision_Update_Confirmation'
		];

		String title = 'JC Performance Tool: ' + actionType + ' Talent Decisions';
		String body =
			'Talent Decisions have been successfully ' + (actionType == 'Release' ? 'released.' : 'rollbacked.');
		String userId = UserInfo.getUserId();

		Messaging.CustomNotification notification = new Messaging.CustomNotification();
		notification.setTitle(title);
		notification.setBody(body);
		notification.setNotificationTypeId(notificationType.Id);
		notification.setTargetPageRef(adminConsole);
		notification.send(new Set<String>{ userId });

		JCUtils.sendEmail(new List<String>{ userId }, userId, emailTemplate.Id, null);
	}
}
