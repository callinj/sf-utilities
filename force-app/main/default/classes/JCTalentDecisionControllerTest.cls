@isTest
public with sharing class JCTalentDecisionControllerTest {
	static final String TEST_PERMISSION_SET = 'Career_Management_User';
	static final String TEST_USER_FIRSTNAME = 'Employee';
	static final String TEST_USER_LASTNAME = 'Test';
	static final String TEST_USER_EMAIL = '@email.com';

	@TestSetup
	static void testSetup() {
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
		insert testUser;

		Boolean ownerHasPermissionSet =
			[
				SELECT Id, PermissionSet.Name, AssigneeId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :testUser.Id AND PermissionSet.Name = :TEST_PERMISSION_SET
			]
			?.PermissionSet.Name == TEST_PERMISSION_SET;

		if (ownerHasPermissionSet != true) {
			PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :TEST_PERMISSION_SET];
			insert new PermissionSetAssignment(PermissionSetId = testPermissionSet.Id, AssigneeId = testUser.Id);
		}
	}

	@isTest
	static void getTalentDecisionsTest() {
		JCTalentDecisionController.TalentDecisionResponse response = new JCTalentDecisionController.TalentDecisionResponse();

		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME];

		List<Talent_Decision__c> talentDecisions = new List<Talent_Decision__c>();
		for (Integer i = 1; i <= 5; i++) {
			Talent_Decision__c decision = new Talent_Decision__c();
			decision.Performance_Type__c = 'Annual';
			decision.Performance_Year__c = String.valueOf(Date.today().year());
			decision.Decision__c = 'Continue to grow and learn';
			decision.Effective_Date__c = Date.today().addDays(i);
			decision.Employee__c = testUser.Id;
			talentDecisions.add(decision);
		}
		insert talentDecisions;

		List<Talent_Decision__c> testDecisions = [SELECT Id FROM Talent_Decision__c WHERE Employee__c = :testUser.Id];
		List<Talent_Decision__Share> shareRecords = new List<Talent_Decision__Share>();
		for (Talent_Decision__c testDecision : testDecisions) {
			Talent_Decision__Share shareRecord = new Talent_Decision__Share();
			shareRecord.ParentId = testDecision.Id;
			shareRecord.UserOrGroupId = testUser.Id;
			shareRecord.RowCause = 'Manual';
			shareRecord.AccessLevel = 'Read';
			shareRecords.add(shareRecord);
		}
		insert shareRecords;

		Test.startTest();
		System.runAs(testUser) {
			JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
				'Talent_Decision__c',
				'Id, Performance_Period__c, Decision__c, Effective_Date__c, Growth_Actions__c'
			);
			queryObject.addFilter('Employee__c', testUser.Id);

			response = JCTalentDecisionController.getTalentDecisions(queryObject);
			System.assertEquals(5, response.results.size(), 'getTalentDecisionsTest results.size() Test: failed');
			System.assertEquals(
				'Annual ' + Date.today().year(),
				response.results[0].period,
				'getTalentDecisionsTest period Test: failed'
			);
			System.assertEquals(
				'Continue to grow and learn',
				response.results[0].decision,
				'getTalentDecisionsTest decision Test: failed'
			);
		}
		Test.stopTest();
	}

	@isTest
	static void getTalentDecisionsThrowExceptionTest() {
		JCTalentDecisionController.TalentDecisionResponse response = new JCTalentDecisionController.TalentDecisionResponse();

		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME];

		List<Talent_Decision__c> talentDecisions = new List<Talent_Decision__c>();
		for (Integer i = 1; i <= 5; i++) {
			Talent_Decision__c decision = new Talent_Decision__c();
			decision.Performance_Type__c = 'Annual';
			decision.Performance_Year__c = String.valueOf(Date.today().year());
			decision.Decision__c = 'Continue to grow and learn';
			decision.Effective_Date__c = Date.today().addDays(i);
			decision.Employee__c = testUser.Id;
			talentDecisions.add(decision);
		}
		insert talentDecisions;

		List<Talent_Decision__c> testDecisions = [SELECT Id FROM Talent_Decision__c WHERE Employee__c = :testUser.Id];
		List<Talent_Decision__Share> shareRecords = new List<Talent_Decision__Share>();
		for (Talent_Decision__c testDecision : testDecisions) {
			Talent_Decision__Share shareRecord = new Talent_Decision__Share();
			shareRecord.ParentId = testDecision.Id;
			shareRecord.UserOrGroupId = testUser.Id;
			shareRecord.RowCause = 'Manual';
			shareRecord.AccessLevel = 'Read';
			shareRecords.add(shareRecord);
		}
		insert shareRecords;

		Test.startTest();
		System.runAs(testUser) {
			JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
				'Talent_Decision__c',
				'Id, Decision__c, Effective_Date__c, Growth_Actions__c'
			);
			queryObject.addFilter('Employee__c', testUser.Id);

			response = JCTalentDecisionController.getTalentDecisions(queryObject);
			System.assertEquals(
				1,
				response.messages.size(),
				'getTalentDecisionsThrowExceptionTest messages.size() Test: failed'
			);
			System.assertEquals(
				'SObject row was retrieved via SOQL without querying the requested field: Talent_Decision__c.Performance_Period__c',
				response.messages[0],
				'getTalentDecisionsThrowExceptionTest messages[0] Test: failed'
			);
		}
		Test.stopTest();
	}
}
