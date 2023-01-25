@isTest
public with sharing class JCRosterControllerTest {
	static final String TEST_PERMISSION_SET = 'Career_Management_User';
	static final String TEST_PERMISSION_SET_HR = 'Career_Management_HR_Admin';
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
				WHERE AssigneeId = :testUsers[0].Id AND PermissionSet.Name = :TEST_PERMISSION_SET
			]
			?.PermissionSet.Name == TEST_PERMISSION_SET;

		Boolean userHasPermissionSetHR =
			[
				SELECT Id, PermissionSet.Name, AssigneeId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :testUsers[0].Id AND PermissionSet.Name = :TEST_PERMISSION_SET
			]
			?.PermissionSet.Name == TEST_PERMISSION_SET_HR;

		List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

		if (userHasPermissionSet != true) {
			PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :TEST_PERMISSION_SET];
			assignments.add(
				new PermissionSetAssignment(PermissionSetId = testPermissionSet.Id, AssigneeId = testUsers[0].Id)
			);
		}
		if (userHasPermissionSetHR != true) {
			PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :TEST_PERMISSION_SET_HR];
			assignments.add(
				new PermissionSetAssignment(PermissionSetId = testPermissionSet.Id, AssigneeId = testUsers[0].Id)
			);
		}
		insert assignments;
	}
	@isTest
	public static void rosterkResponseTest() {
		JCRosterController.RosterResponse test = new JCRosterController.RosterResponse();
		System.assertEquals(test.results.size(), 0, 'JCRosterController.RosterResponse results Assert Fail: failed');
		System.assertEquals(test.success, true, 'JCRosterController.RosterResponse success Assert Fail: failed');
		System.assertEquals(test.messages.size(), 0, 'JCRosterController.RosterResponse messages Assert Fail: failed');
	}

	@isTest
	public static void feedbackResponseTestFalse() {
		JCRosterController.RosterResponse test = new JCRosterController.RosterResponse();
		test.success = false;
		test.messages.add('Testing');
		test.results = new List<JCRosterController.RosterWrapper>();
		System.assertEquals(test.success, false, 'JCRosterController.RosterResponse Assert Fail: Success assert');
		System.assertEquals(test.messages.size(), 1, 'JCRosterController.RosterResponse Assert Fail: messages assert');
		System.assertEquals(
			test.messages[0],
			'Testing',
			'JCRosterController.RosterResponse Assert Fail: messages value'
		);
		System.assertEquals(test.results.size(), 0, 'JCRosterController.RosterResponse Assert Fail: results assert');
	}

	@isTest
	public static void rosterWrapperTest() {
		JCRosterController.RosterWrapper testWrapper = new JCRosterController.RosterWrapper();
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME];
		System.runAs(testUser) {
			insert new Roster__c(
				Name = 'Test Roster',
				isPublic__c = false,
				isReleased__c = false,
				Performance_Period__c = 'Annual ' + Date.today().year()
			);
		}
		Test.startTest();
		Roster__c testRoster = [
			SELECT Id, Name, isPublic__c, isReleased__c, Performance_Period__c
			FROM Roster__c
			WHERE CreatedById = :testUser.Id
			LIMIT 1
		];

		testWrapper.id = testRoster.Id;
		testWrapper.name = testRoster?.Name;
		testWrapper.isPublic = testRoster?.isPublic__c;
		testWrapper.isReleased = testRoster?.isReleased__c;
		testWrapper.performancePeriod = testRoster?.Performance_Period__c;
		System.assertEquals(
			'Test Roster',
			testWrapper.name,
			'JCRosterControllerTest.rosterWrapperTest Assert Fail: name'
		);
		System.assertEquals(
			false,
			testWrapper.isPublic,
			'JCRosterControllerTest.rosterWrapperTest Assert Fail: isPublic'
		);
		System.assertEquals(
			false,
			testWrapper.isReleased,
			'JCRosterControllerTest.rosterWrapperTest Assert Fail: isReleased'
		);
		System.assertEquals(
			'Annual ' + Date.today().year(),
			testWrapper.performancePeriod,
			'JCRosterControllerTest.rosterWrapperTest Assert Fail: performancePeriod'
		);
		Test.stopTest();
	}

	@isTest
	public static void getRostersTest() {
		JCRosterController.RosterResponse response = new JCRosterController.RosterResponse();
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME];
		String recordTypeId = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Talent_Decision' AND SobjectType = 'Roster__c'
		]
		.Id;

		System.runAs(testUser) {
			insert new Roster__c(
				RecordTypeId = recordTypeId,
				Name = 'Test Roster',
				isPublic__c = false,
				isReleased__c = false,
				Performance_Period__c = 'Annual ' + Date.today().year()
			);
			JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject(
				'Roster__c',
				'Id, Name, isPublic__c, isReleased__c, Performance_Period__c'
			);

			Test.startTest();
			response = JCRosterController.getRosters(searchOptions);
			System.assertEquals(
				true,
				response.success,
				'JCRosterControllerTest.getRostersTest Assert Fail: success --> ' + response
			);
			System.assertEquals(
				1,
				response.totalResults,
				'JCRosterControllerTest.getRostersTest Assert Fail: totalResults'
			);
			System.assertEquals(
				0,
				response.messages.size(),
				'JCRosterControllerTest.getRostersTest Assert Fail: messages'
			);
			System.assertEquals(
				'Test Roster',
				response.results[0].name,
				'JCRosterControllerTest.getRostersTest Assert Fail: name'
			);
			Test.stopTest();
		}

	}

	@isTest
	public static void getRostersExceptionTest() {
		JCRosterController.RosterResponse response = new JCRosterController.RosterResponse();
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME];
		String recordTypeId = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Talent_Decision' AND SobjectType = 'Roster__c'
		]
		.Id;

		System.runAs(testUser) {
			insert new Roster__c(
				RecordTypeId = recordTypeId,
				Name = 'Test Roster',
				isPublic__c = false,
				isReleased__c = false,
				Performance_Period__c = 'Annual ' + Date.today().year()
			);
		}

		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject(
			'Roster__c',
			'Id, Name, isPublic__c, isReleased__c'
		);

		Test.startTest();
		response = JCRosterController.getRosters(searchOptions);
		System.assertEquals(false, response.success, 'JCRosterControllerTest.getRostersTest Assert Fail: success');
		System.assertEquals(
			0,
			response.totalResults,
			'JCRosterControllerTest.getRostersTest Assert Fail: totalResults'
		);
		System.assertEquals(1, response.messages.size(), 'JCRosterControllerTest.getRostersTest Assert Fail: messages');
		System.assertEquals(
			'SObject row was retrieved via SOQL without querying the requested field: Roster__c.Performance_Period__c',
			response.messages[0],
			'JCRosterControllerTest.getRostersTest Assert Fail: messages[0]'
		);
		Test.stopTest();
	}

	@isTest
	public static void getUniquePerformancePeriodsTest() {
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME];
		String recordTypeId = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Talent_Decision' AND SobjectType = 'Roster__c'
		]
		.Id;

		System.runAs(testUser) {
			List<Roster__c> testRosters = new List<Roster__c>();
			testRosters.add(
				new Roster__c(
					RecordTypeId = recordTypeId,
					Name = 'Test Roster',
					isPublic__c = false,
					isReleased__c = false,
					Performance_Period__c = 'Annual ' + Date.today().year()
				)
			);
			testRosters.add(
				new Roster__c(
					RecordTypeId = recordTypeId,
					Name = 'Test Roster',
					isPublic__c = false,
					isReleased__c = false,
					Performance_Period__c = 'Mid Year ' + Date.today().year()
				)
			);
			insert testRosters;
		}

		List<String> uniquePerformancePeriods = new List<String>();

		Test.startTest();
		uniquePerformancePeriods = JCRosterController.getUniquePerformancePeriods();
		System.assertEquals(
			new List<String>{ 'Annual ' + Date.today().year(), 'Mid Year ' + Date.today().year() },
			uniquePerformancePeriods,
			'JCRosterControllerTest.getUniquePerformancePeriodsTest Assert Fail: uniquePerformancePeriods'
		);
		Test.stopTest();
	}
}
