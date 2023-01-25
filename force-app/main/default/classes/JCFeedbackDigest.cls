public with sharing class JCFeedbackDigest implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		// collect the batches of records or objects to be passed to execute
		return Database.getQueryLocator(
			'SELECT Id, Name, Email FROM User WHERE isActive = TRUE AND Email LIKE \'%@accenturefederal.com\'' +
			(Test.isRunningTest() ? ' LIMIT 200' : '')
		);
	}
	public void execute(Database.BatchableContext bc, List<User> records) {
		// process each batch of records
		List<String> userIds = new List<String>();
		Map<String, List<Feedback__c>> feedbackItemsMap = new Map<String, List<Feedback__c>>(); // Map<userId, feedbackItems>
		Map<String, List<Feedback_Request__c>> feedbackRequestsMap = new Map<String, List<Feedback_Request__c>>(); // Map<userId, feedbackRequests>

		for (User user : records) {
			userIds.add(user.Id);
		}

		List<Feedback__c> feedbackItems = [
			SELECT Id, Title__c, Receiver__c
			FROM Feedback__c
			WHERE Receiver__c IN :userIds AND CreatedDate = LAST_N_DAYS:7
		];
		List<Feedback_Request__c> feedbackRequests = [
			SELECT Id, Feedback__c, Feedback__r.Title__c, Reviewer__c
			FROM Feedback_Request__c
			WHERE Reviewer__c IN :userIds AND CreatedDate = LAST_N_DAYS:7
		];

		for (Feedback__c feedbackItem : feedbackItems) {
			if (feedbackItemsMap.containsKey(feedbackItem.Receiver__c)) {
				feedbackItemsMap.get(feedbackItem.Receiver__c).add(feedbackItem);
			} else {
				feedbackItemsMap.put(feedbackItem.Receiver__c, new List<Feedback__c>{ feedbackItem });
			}
		}

		for (Feedback_Request__c feedbackRequest : feedbackRequests) {
			if (feedbackRequestsMap.containsKey(feedbackRequest.Reviewer__c)) {
				feedbackRequestsMap.get(feedbackRequest.Reviewer__c).add(feedbackRequest);
			} else {
				feedbackRequestsMap.put(feedbackRequest.Reviewer__c, new List<Feedback_Request__c>{ feedbackRequest });
			}
		}

		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

		EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name = 'Digest Email Template'];
		String emailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'My JC Notification Tool']?.Id;

		for (User user : records) {
			if (feedbackItemsMap.get(user.Id) != null || feedbackRequestsMap.get(user.Id) != null) {
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setToAddresses(new List<String>{ user.Email });
				mail.setTargetObjectId(user.Id);
				mail.setTemplateID(emailTemplate.Id);
				mail.setSaveAsActivity(false);
				mail.setOrgWideEmailAddressId(emailId);
				emails.add(mail);
			}
		}

		Messaging.sendEmail(emails); // TODO | Uncomment to send emails
	}
	public void finish(Database.BatchableContext bc) {
		// execute any post-processing operations
	}
}
