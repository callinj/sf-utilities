@isTest
public with sharing class JCUserTriggerHandlerTest {
	static final String TEST_PERMISSION_SET = 'Career_Management_User';
	static final String TEST_USER_FIRSTNAME = 'Employee';
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
		insert testUser;
	}
	@isTest
	static void onBeforeInsertTest() {
		String testUserEmail = TEST_USER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL;
		UserRole jcRole = [SELECT Id, Name FROM UserRole WHERE Name = 'JC' LIMIT 1];
		User updatedUser = [
			SELECT Id, UserRoleId, UserPermissionsInteractionUser, UserPermissionsMarketingUser
			FROM User
			WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME AND Email = :testUserEmail
			LIMIT 1
		];
		Test.startTest();
		System.assertEquals(
			jcRole.Id,
			updatedUser.UserRoleId,
			'JCUserTriggerHandlerTest.onBeforeInsertTestAssert Fail: user role'
		);
		System.assertEquals(
			true,
			updatedUser.UserPermissionsInteractionUser,
			'JCUserTriggerHandlerTest.onBeforeInsertTestAssert Fail: UserPermissionsInteractionUser'
		);
		System.assertEquals(
			false,
			updatedUser.UserPermissionsMarketingUser,
			'JCUserTriggerHandlerTest.onBeforeInsertTestAssert Fail: UserPermissionsMarketingUser'
		);
		Test.stopTest();
	}
	@isTest
	static void beforeUpdateTest() {
		String testUserEmail = TEST_USER_FIRSTNAME + TEST_USER_LASTNAME + TEST_USER_EMAIL;
		UserRole jcRole = [SELECT Id, Name FROM UserRole WHERE Name = 'JC' LIMIT 1];
		User updatedUser = [
			SELECT Id, UserRoleId, UserPermissionsInteractionUser, UserPermissionsMarketingUser
			FROM User
			WHERE FirstName = :TEST_USER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME AND Email = :testUserEmail
			LIMIT 1
		];
		updatedUser.UserRoleId = null;
		Test.startTest();
		update updatedUser;
		System.assertEquals(
			jcRole.Id,
			updatedUser.UserRoleId,
			'JCUserTriggerHandlerTest.beforeUpdateTest Assert Fail: user role'
		);
		System.assertEquals(
			true,
			updatedUser.UserPermissionsInteractionUser,
			'JCUserTriggerHandlerTest.beforeUpdateTest Assert Fail: UserPermissionsInteractionUser'
		);
		System.assertEquals(
			false,
			updatedUser.UserPermissionsMarketingUser,
			'JCUserTriggerHandlerTest.beforeUpdateTest Assert Fail: UserPermissionsMarketingUser'
		);
		Test.stopTest();
	}
}
