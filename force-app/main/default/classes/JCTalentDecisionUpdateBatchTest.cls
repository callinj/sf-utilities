@isTest
public with sharing class JCTalentDecisionUpdateBatchTest {
	static final String TEST_PERMISSION_SET = 'Career_Management_User';
	static final String TEST_USER_FIRSTNAME = 'Owner';
	static final String TEST_USER_LASTNAME = 'Test';
	static final String TEST_USER_EMAIL = '@email.com';
	@testSetup
	static void setup() {
		//Add test setup data here
		Profile testProfile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce Platform' LIMIT 1];

		User testUser = new User(
			Alias = 'tuser',
			Email = TEST_USER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_USER_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_USER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL
		);
		List<User> testUsers = new List<User>{ testUser };
		insert testUsers;

		Boolean userHasPermissionSet =
			[
				SELECT Id, PermissionSet.Name, AssigneeId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :testUser.Id AND PermissionSet.Name = :TEST_PERMISSION_SET
			]
			?.PermissionSet.Name == TEST_PERMISSION_SET;

		if (userHasPermissionSet != true) {
			PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :TEST_PERMISSION_SET];
			List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
			assignments.add(
				new PermissionSetAssignment(PermissionSetId = testPermissionSet.Id, AssigneeId = testUser.Id)
			);
			insert assignments;
		}
	}

	@isTest
	public static void executeBatchTest() {
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME];
		System.runAs(testUser) {
			insert new Roster__c(
				Name = 'Test Roster',
				isPublic__c = false,
				isReleased__c = false,
				Performance_Period__c = 'Annual ' + Date.today().year()
			);
		}

		Roster__c testRoster = [SELECT Id FROM Roster__c WHERE Name = 'Test Roster'];
		List<Talent_Decision__c> testDecisions = new List<Talent_Decision__c>();
		for (Integer i = 0; i < 2; i++) {
			Talent_Decision__c decision = new Talent_Decision__c();
			decision.Performance_Type__c = 'Annual';
			decision.Performance_Year__c = String.valueOf(Date.today().year());
			decision.Decision__c = 'Continue to grow and learn';
			decision.Effective_Date__c = Date.today().addDays(i);
			decision.Employee__c = testUser.Id;
			decision.Roster__c = testRoster.Id;
			decision.Finalized__c = false;
			testDecisions.add(decision);
		}
		insert testDecisions;

		testRoster.IsReleased__c = true;
		update testRoster;

		Test.startTest();
		JCTalentDecisionUpdateBatch talentDecisionBatch = new JCTalentDecisionUpdateBatch(
			new List<String>{ testRoster.Id },
			'Release'
		);
		database.executeBatch(talentDecisionBatch, 200);
		Test.stopTest();

		List<Talent_Decision__c> updatedDecisions = [
			SELECT Id, Employee__c, Roster__c, Finalized__c
			FROM Talent_Decision__c
			WHERE Roster__c = :testRoster.Id
		];
		System.assertEquals(2, updatedDecisions.size(), 'executeBatchTest updatedDecisions.size() Test: failed');
		System.assertEquals(testUser.Id, updatedDecisions[0].Employee__c, 'executeBatchTest Employee Test: failed');
		System.assertEquals(true, updatedDecisions[0].Finalized__c, 'executeBatchTest Finalized Test: failed');
		System.assertEquals(testUser.Id, updatedDecisions[1].Employee__c, 'executeBatchTest Employee Test: failed');
		System.assertEquals(true, updatedDecisions[1].Finalized__c, 'executeBatchTest Finalized Test: failed');
	}
}
