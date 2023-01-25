@isTest
public with sharing class JCFeedbackScheduleTest {
	@TestSetup
	static void testSetup() {
		// Grab Profile
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

		// Create 1 User
		User user = new User();
		user.ProfileId = profileId;
		user.FirstName = 'Test';
		user.LastName = 'User';
		user.Email = 'test.user@accenturefederal.com';
		user.Username = 'test.user.apextestclass@accenturefederal.com';
		user.Alias = 'tuser';
		user.TimeZoneSidKey = 'America/Los_Angeles';
		user.LocaleSidKey = 'en_US';
		user.EmailEncodingKey = 'UTF-8';
		user.LanguageLocaleKey = 'en_US';
		insert user;

		String userId = getTestUsers()[0].Id;

		// Create 1 Feedback Item for 1 User
		Feedback__c feedbackItem = new Feedback__c();
		feedbackItem.RecordTypeId = getRecordTypeId('Feedback');
		feedbackItem.Provider__c = UserInfo.getUserId();
		feedbackItem.Receiver__c = userId;
		insert feedbackItem;
	}

	public static List<User> getTestUsers() {
		return [SELECT Id, Name, Email FROM User WHERE Username LIKE '%apextestclass@accenturefederal.com'];
	}
	public static String getRecordTypeId(String recordType) {
		return [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Feedback__c' AND DeveloperName = :recordType
		]
		.Id;
	}

	@isTest
	static void myTestMethod() {
		Test.startTest();
		JCFeedbackSchedule scheduleClass = new JCFeedbackSchedule();
		String chron = '0 0 23 * * ?';
		System.schedule('Test Sched', chron, scheduleClass);
		Test.stopTest();
	}
}
