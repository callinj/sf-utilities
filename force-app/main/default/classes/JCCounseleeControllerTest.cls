@isTest
public with sharing class JCCounseleeControllerTest {
	static final String TEST_PEOPLE_LEAD_FIRSTNAME = 'PeopleLead';
	static final String TEST_USER_1_FIRSTNAME = 'User1';
	static final String TEST_USER_2_FIRSTNAME = 'User2';
	static final String TEST_USER_LASTNAME = 'Test';
	static final String TEST_USER_EMAIL = '@email.com';
	@testSetup
	public static void setup() {
		//Add test setup data here
		Profile testProfile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce Platform' LIMIT 1];

		User peopleLeadTestUser = new User(
			Alias = 'tuser',
			Email = TEST_PEOPLE_LEAD_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_PEOPLE_LEAD_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_PEOPLE_LEAD_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			IsActive = true
		);
		insert peopleLeadTestUser;

		User testUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PEOPLE_LEAD_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		User testUser1 = new User(
			Alias = 'tuser',
			Email = TEST_USER_1_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_USER_1_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_USER_1_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			People_Lead__c = testUser.Id,
			IsActive = true
		);
		insert testUser1;
		User testUser2 = new User(
			Alias = 'tuser',
			Email = TEST_USER_2_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_USER_2_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_USER_2_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			People_Lead__c = testUser.Id,
			IsActive = true
		);
		insert testUser2;
		// List<User> testUsers = new List<User>{ testUser1, testUser2 };
		// insert testUsers;
	}

	@isTest
	public static void getCounseleesTest() {
		User peopleLeadTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PEOPLE_LEAD_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject('User', 'Id, Name');
		searchOptions.addFilter('People_Lead__c', peopleLeadTestUser.Id, 'AND', '=');
		searchOptions.addFilter('IsActive', true, 'AND', '=');

		JCCounseleeController.CounseleeResponse response = new JCCounseleeController.CounseleeResponse();

		System.runAs(peopleLeadTestUser) {
			Test.startTest();
			response = JCCounseleeController.getCounselees(searchOptions);
			System.assertEquals(
				true,
				response.success,
				'JCCounseleeControllerTest.getCounseleesTest() Assert Fail: success'
			);
			System.assertEquals(
				2,
				response.totalResults,
				'JCCounseleeControllerTest.getCounseleesTest() Assert Fail: totalResults'
			);
			System.assertEquals(
				'User1 Test',
				response.results[0].name,
				'JCCounseleeControllerTest.getCounseleesTest() Assert Fail: name'
			);
			System.assertEquals(
				'User2 Test',
				response.results[1].name,
				'JCCounseleeControllerTest.getCounseleesTest() Assert Fail: name'
			);
			Test.stopTest();
		}
	}

	@isTest
	public static void getCounseleesExceptionTest() {
		User peopleLeadTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PEOPLE_LEAD_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject('User', 'Id');
		searchOptions.addFilter('People_Lead__c', peopleLeadTestUser.Id, 'AND', '=');
		searchOptions.addFilter('IsActive', true, 'AND', '=');

		JCCounseleeController.CounseleeResponse response = new JCCounseleeController.CounseleeResponse();

		System.runAs(peopleLeadTestUser) {
			Test.startTest();
			response = JCCounseleeController.getCounselees(searchOptions);
			System.assertEquals(
				false,
				response.success,
				'JCCounseleeControllerTest.getCounseleesExceptionTest() Assert Fail: success'
			);
			System.assertEquals(
				1,
				response.messages.size(),
				'JCCounseleeControllerTest.getCounseleesExceptionTest() Assert Fail: messages.size()'
			);
			System.assertEquals(
				'SObject row was retrieved via SOQL without querying the requested field: User.Name',
				response.messages[0],
				'JCCounseleeControllerTest.getCounseleesExceptionTest() Assert Fail: message'
			);
			Test.stopTest();
		}
	}
}
