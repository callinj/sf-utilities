@isTest
public with sharing class JCPeopleLeadCleanupTest {
	static final String TEST_PERMISSION_SET = 'People_Lead';
	static final String TEST_LEAD_FIRSTNAME = 'Lead';
	static final String TEST_COUNSELEE_1_FIRSTNAME = 'Counselee1';
	static final String TEST_COUNSELEE_2_FIRSTNAME = 'Counselee2';
	static final String TEST_USER_LASTNAME = 'Test';
	static final String TEST_USER_EMAIL = '@email.com';

	@testSetup
	static void setup() {
		// Profile testProfile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce Platform' LIMIT 1];
		Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

		// insert new PermissionSet(Name = TEST_PERMISSION_SET, Label = TEST_PERMISSION_SET);

		User leadTestUser = new User(
			Alias = 'tuser',
			Email = TEST_LEAD_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_LEAD_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_LEAD_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			IsActive = true
		);
		insert leadTestUser;
		User counselee1TestUser = new User(
			Alias = 'tuser',
			Email = TEST_COUNSELEE_1_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_COUNSELEE_1_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_COUNSELEE_1_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			People_Lead__c = leadTestUser.Id,
			IsActive = true
		);
		insert counselee1TestUser;
		User counselee2TestUser = new User(
			Alias = 'tuser',
			Email = TEST_COUNSELEE_2_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_COUNSELEE_2_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_COUNSELEE_2_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			People_Lead__c = leadTestUser.Id,
			IsActive = true
		);
		insert counselee2TestUser;
		// List<User> testUsers = new List<User>{ counselee1TestUser, counselee2TestUser };
		// insert testUsers;
	}

	@isTest
	public static void testBatch() {
		Test.startTest();
		User testUser = [
			SELECT Id, Name
			FROM User
			WHERE FirstName = :TEST_LEAD_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
			LIMIT 1
		];

		JCPeopleLeadCleanup cleanupBatch = new JCPeopleLeadCleanup();
		database.executeBatch(cleanupBatch, 200);
		Test.stopTest();

		PermissionSet permissionSet = [SELECT Id, Name, Label FROM PermissionSet WHERE Name = 'People_Lead' LIMIT 1];
		List<PermissionSetAssignment> assignments = [
			SELECT Id, PermissionSet.Name, AssigneeId, Assignee.Name
			FROM PermissionSetAssignment
			WHERE PermissionSetId = :permissionSet.Id AND AssigneeId = :testUser.Id
		];

		System.assertEquals('Lead Test', testUser.Name, 'lead test fail');
		System.assertEquals('People_Lead', permissionSet.Name, 'JCPeopleLeadCleanupTest.testBatch Assert Fail: Name');
		System.assertEquals(1, assignments.size(), 'JCPeopleLeadCleanupTest.testBatch Assert Fail: Size');
		System.assertEquals(
			testUser.Id,
			assignments[0].AssigneeId,
			'JCPeopleLeadCleanupTest.testBatch Assert Fail: AssigneeId'
		);
	}
}
