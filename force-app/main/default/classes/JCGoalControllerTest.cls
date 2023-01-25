@isTest
public with sharing class JCGoalControllerTest {
	static final String TEST_PERMISSION_SET = 'Career_Management_User';
	static final String TEST_PROVIDER_FIRSTNAME = 'Provider';
	static final String TEST_RECEIVER_FIRSTNAME = 'Receiver';
	static final String TEST_USER_LASTNAME = 'Test';
	static final String TEST_USER_EMAIL = '@email.com';

	@TestSetup
	static void testSetup() {
		//Add test setup data here
		Profile testProfile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce Platform' LIMIT 1];

		User providerTestUser = new User(
			Alias = 'tuser',
			Email = TEST_PROVIDER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_PROVIDER_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_PROVIDER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL
		);
		User receiverTestUser = new User(
			Alias = 'tuser',
			Email = TEST_RECEIVER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_RECEIVER_FIRSTNAME,
			LastName = TEST_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_RECEIVER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL
		);
		List<User> testUsers = new List<User>{ providerTestUser, receiverTestUser };
		insert testUsers;

		Boolean providerHasPermissionSet =
			[
				SELECT Id, PermissionSet.Name, AssigneeId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :providerTestUser.Id AND PermissionSet.Name = :TEST_PERMISSION_SET
			]
			?.PermissionSet.Name == TEST_PERMISSION_SET;

		Boolean receiverHasPermissionSet =
			[
				SELECT Id, PermissionSet.Name, AssigneeId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :receiverTestUser.Id AND PermissionSet.Name = :TEST_PERMISSION_SET
			]
			?.PermissionSet.Name == TEST_PERMISSION_SET;

		if (providerHasPermissionSet != true || receiverHasPermissionSet != true) {
			PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :TEST_PERMISSION_SET];
			List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

			if (providerHasPermissionSet != true) {
				assignments.add(
					new PermissionSetAssignment(
						PermissionSetId = testPermissionSet.Id,
						AssigneeId = providerTestUser.Id
					)
				);
			}

			if (receiverHasPermissionSet != true) {
				assignments.add(
					new PermissionSetAssignment(
						PermissionSetId = testPermissionSet.Id,
						AssigneeId = receiverTestUser.Id
					)
				);
			}

			insert assignments;
		}
	}

	@isTest
	static void getGoalsTest() {
		JCGoalController.GoalResponse response = new JCGoalController.GoalResponse();
		User testUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		System.runAs(testUser) {
			insert new Goal__c(Name = 'Test Priority', Status__c = 'Not Started');
		}

		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Goal__c',
			'Id, Name, Status__c, CreatedDate'
		);
		queryObject.addFilter('CreatedDate', 'THIS_FISCAL_YEAR');
		queryObject.addFilter('CreatedById', testUser.Id, 'AND', '=');

		Test.startTest();
		response = JCGoalController.getGoals(queryObject);
		System.assertEquals(1, response.results.size(), 'getGoalsTest results.size() Test: failed');
		System.assertEquals('Test Priority', response.results[0].Name, 'getGoalsTest name Test: failed');
		Test.stopTest();
	}

	@isTest
	static void getGoalsThrowExceptionTest() {
		JCGoalController.GoalResponse response = new JCGoalController.GoalResponse();
		User testUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		System.runAs(testUser) {
			insert new Goal__c(Name = 'Test Priority', Status__c = 'Not Started');
		}

		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject('Goal__c');
		queryObject.addFilter('CreatedById', testUser.Id, 'AND', '=');

		Test.startTest();
		response = JCGoalController.getGoals(queryObject);
		System.assertEquals(1, response.messages.size(), 'getGoalsThrowExceptionTest messages.size() Test: failed');
		System.assertEquals(
			'There was an error while processing your request. Please take note of the time and contact your system administrator.',
			response.messages[0],
			'getGoalsThrowExceptionTest message Test: failed'
		);
		Test.stopTest();
	}

	@isTest
	public static void sendNotificationsTest() {
		User testUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		Goal__c testGoal = new Goal__c(Name = 'Test Priority', Status__c = 'Not Started');
		insert testGoal;

		Test.startTest();
		JCUtils.shareRecord(testGoal.Id, testUser.Id);
		Goal__Share shareRecord = [
			SELECT Id, UserOrGroupId, ParentId
			FROM Goal__Share
			WHERE UserOrGroupId = :testUser.Id AND ParentId = :testGoal.Id
		];
		System.assertEquals(
			testUser.Id,
			shareRecord.UserOrGroupId,
			'JCGoalController.sendNotificationsTest Assert Fail: Incorrect UserOrGroupId'
		);
		System.assertEquals(
			testGoal.Id,
			shareRecord.ParentId,
			'JCGoalController.sendNotificationTest Assert Fail: Incorrect ParentId'
		);
		Test.stopTest();
	}

	@isTest
	public static void getSharedGoalsTest() {
		JCGoalController.GoalResponse response = new JCGoalController.GoalResponse();

		User testUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		Goal__c testGoal = new Goal__c(Name = 'Test Priority', Status__c = 'Not Started');

		System.runAs(testUser) {
			insert testGoal;
		}

		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject(
			'Goal__Share',
			new List<String>{ 'Id', 'ParentId', 'Parent.Title__c', 'Parent.Name', 'LastModifiedDate' },
			5,
			0
		);
		searchOptions.addFilter('UserOrGroupId', receiverTestUser.Id);
		searchOptions.addFilter('RowCause', 'Manual');

		Test.startTest();
		JCUtils.shareRecord(testGoal.Id, receiverTestUser.Id);
		response = JCGoalController.getSharedGoals(searchOptions);
		System.assertEquals(
			true,
			response.success,
			'JCGoalController.getSharedGoalsTest Assert Fail: Incorrect success'
		);
		System.assertEquals(
			1,
			response.totalResults,
			'JCGoalController.getSharedGoalsTest Assert Fail: Incorrect totalResults'
		);
		System.assertEquals(
			'Provider\'s Priority: Test Priority',
			response.results[0].name,
			'JCGoalController.getSharedGoalsTest Assert Fail: Incorrect name'
		);
		Test.stopTest();
	}
}
