@isTest
public with sharing class JCFeedbackDigestTest {
	@TestSetup
	static void testSetup() {
		// Grab Profile
		Id profileId = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce Platform' LIMIT 1].Id;

		// Create 1 Test User
		User testUser = new User();
		testUser.ProfileId = profileId;
		testUser.FirstName = 'Test';
		testUser.LastName = 'User';
		testUser.Email = 'test.user@accenturefederal.com';
		testUser.Username = 'test.user.apextestclass@accenturefederal.com';
		testUser.Alias = 'tuser';
		testUser.TimeZoneSidKey = 'America/Los_Angeles';
		testUser.LocaleSidKey = 'en_US';
		testUser.EmailEncodingKey = 'UTF-8';
		testUser.LanguageLocaleKey = 'en_US';
		testUser.IsActive = true;
		insert testUser;

		String userId = UserInfo.getUserId();
		System.runAs(testUser) {
			Feedback__c feedbackItem = new Feedback__c();
			feedbackItem.RecordTypeId = getRecordTypeId('Feedback');
			feedbackItem.Receiver__c = UserInfo.getUserId();
			feedbackItem.Provider__c = userId;
			insert feedbackItem;

			// Create 1 Feedback Request
			Feedback_Request__c feedbackRequest = new Feedback_Request__c();
			feedbackRequest.Reviewer__c = UserInfo.getUserId();
			feedbackRequest.Requester__c = userId;
			insert feedbackRequest;
			Datetime lastWeek = Datetime.now().addDays(-7);
			Test.setCreatedDate(feedbackItem.Id, lastWeek);
			Test.setCreatedDate(feedbackRequest.Id, lastWeek);
		}

	}

	// public static User getTestUser() {
	//     return [SELECT Id, Name, Email FROM User WHERE Username = 'test.user.apextestclass@accenturefederal.com'];
	// }
	public static String getRecordTypeId(String recordType) {
		return [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Feedback__c' AND DeveloperName = :recordType
		]
		.Id;
	}

	@isTest
	static void testBatch() {
		Test.startTest();
		JCFeedbackDigest digest = new JCFeedbackDigest();
		Id batchId = Database.executeBatch(digest);
		Test.stopTest();
		System.assertEquals(
			1,
			Limits.getEmailInvocations(),
			'JCFeedbackDigestTest.testBatch Assert Fail: email not sent'
		);
	}
}
