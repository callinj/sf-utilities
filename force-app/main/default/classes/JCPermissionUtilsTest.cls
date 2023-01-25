@isTest
public class JCPermissionUtilsTest {
	// TODO Update test to use test factory
	static final String TEST_FIRSTNAME = 'Apex';
	static final String TEST_LASTNAME = 'Test';
	static final String TEST_EMAIL = 'apextest@email.com';
	@testSetup
	static void setup() {
		//Add test setup data here
		//Add test setup data here
		String receiverId = UserInfo.getUserId();
		Profile testProfile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce Platform' LIMIT 1];
		User testUser = new User(
			Alias = 'tuser',
			Email = TEST_EMAIL,
			EmailEncodingKey = 'UTF-8',
			FirstName = TEST_FIRSTNAME,
			LastName = TEST_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = TEST_EMAIL
		);
		insert testUser;
		ApexClass helper = [SELECT Id, Name FROM ApexClass WHERE Name = 'JCFeedbackDigestHelper' LIMIT 1];
		PermissionSet testPermissionSet = new PermissionSet(
			Name = 'Apex_Test_Permission_Set',
			Label = 'Apex_Test_Permission_Set'
		);
		insert testPermissionSet;
		insert new ObjectPermissions(
			SobjectType = 'Feedback__c',
			ParentId = testPermissionSet.Id,
			PermissionsCreate = true,
			PermissionsDelete = true,
			PermissionsEdit = true,
			PermissionsRead = true
		);
		insert new SetupEntityAccess(ParentId = testPermissionSet.Id, SetupEntityId = helper.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = testPermissionSet.Id);
		System.runAs(testUser) {
			insert new Feedback__c(Provider__c = testUser.Id, Receiver__c = receiverId, Comments__c = 'Test Comments');
		}
	}
	@isTest
	public static void permissionResponseTest() {
		JCPermissionUtils.PermissionResponse test = new JCPermissionUtils.PermissionResponse();
		System.assertEquals(
			test.results.size(),
			0,
			'JCPermissionUtilsTest.permissionResponseTest results Assert Fail: failed'
		);
		System.assertEquals(
			test.success,
			true,
			'JCPermissionUtilsTest.permissionResponseTest success Assert Fail: failed'
		);
		System.assertEquals(
			test.messages.size(),
			0,
			'JCPermissionUtilsTest.permissionResponseTest messages Assert Fail: failed'
		);
	}

	@isTest
	public static void permissionResponseFalseTest() {
		JCPermissionUtils.PermissionResponse test = new JCPermissionUtils.PermissionResponse();
		test.success = false;
		test.messages.add('Testing');
		System.assertEquals(
			test.success,
			false,
			'JCPermissionUtilsTest.permissionResponseFalseTest Assert Fail: Success assert'
		);
		System.assertEquals(
			test.messages.size(),
			1,
			'JCPermissionUtilsTest.permissionResponseFalseTest Assert Fail: messages assert'
		);
		System.assertEquals(
			test.messages[0],
			'Testing',
			'JCPermissionUtilsTest.permissionResponseFalseTest Assert Fail: messages value'
		);
		System.assertEquals(
			test.results.size(),
			0,
			'JCPermissionUtilsTest.permissionResponseFalseTest Assert Fail: results assert'
		);
	}
	@isTest
	public static void shareResponseTest() {
		JCPermissionUtils.ShareResponse testWrapper = new JCPermissionUtils.ShareResponse();
		System.assertEquals(
			testWrapper.results.size(),
			0,
			'JCPermissionUtilsTest.shareResponseTest results Assert Fail: failed'
		);
		System.assertEquals(
			testWrapper.success,
			true,
			'JCPermissionUtilsTest.shareResponseTest success Assert Fail: failed'
		);
		System.assertEquals(
			testWrapper.messages.size(),
			0,
			'JCPermissionUtilsTest.shareResponseTest messages Assert Fail: failed'
		);
	}
	@isTest
	public static void permissionWrapperTest() {
		JCPermissionUtils.PermissionWrapper testWrapper = new JCPermissionUtils.PermissionWrapper();
		System.assertEquals(
			false,
			testWrapper.hasAll,
			'JCPermissionUtilsTest.permissionWrapperTest Assert Fail: hasAll'
		);
		System.assertEquals(
			false,
			testWrapper.hasDelete,
			'JCPermissionUtilsTest.permissionWrapperTest Assert Fail: hasDelete'
		);
		System.assertEquals(
			false,
			testWrapper.hasEdit,
			'JCPermissionUtilsTest.permissionWrapperTest Assert Fail: hasEdit'
		);
		System.assertEquals(
			false,
			testWrapper.hasTransfer,
			'JCPermissionUtilsTest.permissionWrapperTest Assert Fail: hasTransfer'
		);
		System.assertEquals(
			false,
			testWrapper.hasRead,
			'JCPermissionUtilsTest.permissionWrapperTest Assert Fail: hasRead'
		);
		System.assertEquals(
			false,
			testWrapper.hasShare,
			'JCPermissionUtilsTest.permissionWrapperTest Assert Fail: hasShare'
		);
	}
	@isTest
	public static void shareWrapperSetTest() {
		JCPermissionUtils.ShareWrapper testWrapper = new JCPermissionUtils.ShareWrapper();
		JCWrapper.Person testPerson = new JCWrapper.Person(UserInfo.getUserId(), UserInfo.getName());
		List<Schema.PicklistEntry> rowCauses = Schema.SObjectType.Feedback__Share.fields.getMap()
			.get('rowCause')
			.getDescribe()
			.getPicklistValues();
		for (Schema.PicklistEntry entry : rowCauses) {
			if (entry.getValue() == 'Manual') {
				testWrapper.reason = new JCPermissionUtils.ShareReason(entry.getLabel(), entry.getValue());
			}
		}

		testWrapper.level = 'Edit';
		testWrapper.sharedWith = testPerson;
		testWrapper.whoShared = testPerson;
		testWrapper.sharedDatetime = date.today();
		Test.startTest();
		System.assertEquals(
			UserInfo.getUserId(),
			testWrapper.sharedWith.id,
			'JCPermissionUtilsTest.shareWrapperSetTest Assert Fail: sharedWith,id'
		);
		System.assertEquals(
			UserInfo.getName(),
			testWrapper.sharedWith.name,
			'JCPermissionUtilsTest.shareWrapperSetTest Assert Fail: sharedWith.name'
		);
		System.assertEquals('Edit', testWrapper.level, 'JCPermissionUtilsTest.shareWrapperSetTest Assert Fail: level');
		System.assertEquals(
			'Manual Sharing',
			testWrapper.reason.label,
			'JCPermissionUtilsTest.shareWrapperSetTest Assert Fail: reason'
		);
		System.assertEquals(
			UserInfo.getUserId(),
			testWrapper.whoShared.id,
			'JCPermissionUtilsTest.shareWrapperSetTest Assert Fail: whoShared'
		);
		System.assertEquals(
			date.today(),
			testWrapper.sharedDatetime,
			'JCPermissionUtilsTest.shareWrapperSetTest Assert Fail: sharedDatetime'
		);
		Test.stopTest();
	}
	@isTest
	public static void recordPermissionsForUserTest() {
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_FIRSTNAME AND LastName = :TEST_LASTNAME];
		Feedback__c testFeedback = [SELECT id FROM Feedback__c WHERE OwnerId = :testUser.Id LIMIT 1];
		System.runAs(testUser) {
			Test.startTest();
			JCPermissionUtils.PermissionResponse testResponse = JCPermissionUtils.recordPermissionsForUser(
				new List<String>{ testFeedback.Id },
				UserInfo.getUserId()
			);
			System.assertEquals(
				true,
				testResponse.success,
				'JCFilesControllerTest.assignFilesToRecordTest Assert Fail: success'
			);
			for (String key : testResponse.results.keySet()) {
				System.assertEquals(
					true,
					testResponse.results.get(key).hasAll,
					'JCPermissionUtilsTest.recordPermissionsForUserTest Assert Fail: hasAll'
				);
				System.assertEquals(
					true,
					testResponse.results.get(key).hasDelete,
					'JCPermissionUtilsTest.recordPermissionsForUserTest Assert Fail: hasDelete'
				);
				System.assertEquals(
					true,
					testResponse.results.get(key).hasEdit,
					'JCPermissionUtilsTest.recordPermissionsForUserTest Assert Fail: hasEdit'
				);
				System.assertEquals(
					true,
					testResponse.results.get(key).hasTransfer,
					'JCPermissionUtilsTest.recordPermissionsForUserTest Assert Fail: hasTransfer'
				);
				System.assertEquals(
					true,
					testResponse.results.get(key).hasRead,
					'JCPermissionUtilsTest.recordPermissionsForUserTest Assert Fail: hasRead'
				);
			}
			Test.stopTest();
		}

	}
	@isTest
	public static void recordPermissionsForUserTypeTest() {
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_FIRSTNAME AND LastName = :TEST_LASTNAME];
		System.runAs(testUser) {
			JCPermissionUtils.PermissionResponse testResponse = JCPermissionUtils.recordPermissionsForUser(
				5,
				UserInfo.getUserId()
			);
			System.assertEquals(
				false,
				testResponse.success,
				'JCFilesControllerTest.recordPermissionsForUserTypeTest Assert Fail: success'
			);
			System.assertEquals(
				1,
				testResponse.messages.size(),
				'JCPermissionUtilsTest.recordPermissionsForUserTypeTest Assert Fail: messages size'
			);
			System.assertEquals(
				'There was an error while processing your request. recordIds must be of type List<String>, String or Id.',
				testResponse.messages[0],
				'JCPermissionUtilsTest.recordPermissionsForUserTypeTest Assert Fail: messages value'
			);
		}

	}
	@IsTest
	static void checkUserCanShareTest() {
		User testUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_FIRSTNAME AND LastName = :TEST_LASTNAME AND Email = :TEST_EMAIL
			LIMIT 1
		];
		Feedback__c testRecord = [SELECT Id, Name FROM Feedback__c WHERE OwnerId = :testUser.Id LIMIT 1];
		Test.startTest();
		System.runAs(testUser) {
			JCPermissionUtils.PermissionResponse testResponse = JCPermissionUtils.checkUserCanShare(
				testRecord.Id,
				testUser.Id,
				'Edit',
				new List<String>{ 'Owner' }
			);
			System.assertEquals(
				true,
				testResponse.success,
				'JCPermissionUtilsTest.checkUserCanShareTest Assert Fail: success'
			);
			System.assertEquals(
				true,
				testResponse.results.get(testRecord.Id).hasShare,
				'JCPermissionUtilsTest.checkUserCanShareTest Assert Fail: hasShare'
			);
		}
		Test.stopTest();
	}
	@IsTest
	static void recordPermissionListTest() {
		User testUser = [
			SELECT Id, Name
			FROM User
			WHERE FirstName = :TEST_FIRSTNAME AND LastName = :TEST_LASTNAME AND Email = :TEST_EMAIL
			LIMIT 1
		];
		Feedback__c testRecord = [SELECT Id, Name FROM Feedback__c WHERE OwnerId = :testUser.Id LIMIT 1];
		Test.startTest();
		System.runAs(testUser) {
			JCPermissionUtils.ShareResponse testResponse = JCPermissionUtils.recordPermissionList(
				testRecord.Id,
				new List<String>{ 'Owner' }
			);
			System.assertEquals(
				true,
				testResponse.success,
				'JCPermissionUtilsTest.recordPermissionListTest Assert Fail: success'
			);
			System.assertEquals(
				testUser.Name,
				testResponse.results[0].whoShared.name,
				'JCPermissionUtilsTest.checkUserCanShareTest Assert Fail: whoShared'
			);
			System.assertEquals(
				'Owner',
				testResponse.results[0].reason.label,
				'JCPermissionUtilsTest.checkUserCanShareTest Assert Fail: reason'
			);
		}
		Test.stopTest();
	}
	@IsTest
	static void getShareQueryObjectTest() {
		User testUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_FIRSTNAME AND LastName = :TEST_LASTNAME AND Email = :TEST_EMAIL
			LIMIT 1
		];
		Feedback__c testRecord = [SELECT Id, Name FROM Feedback__c WHERE OwnerId = :testUser.Id LIMIT 1];
		Test.startTest();
		System.runAs(testUser) {
			JCQueryHelper.QueryObject testQueryObject = JCPermissionUtils.getShareQueryObject(
				testRecord.Id,
				new List<String>{ 'Owner' },
				'Edit'
			);
			System.assertEquals(
				'Feedback__Share',
				testQueryObject.objectName,
				'JCPermissionUtilsTest.getShareQueryObjectTest Assert Fail: testQueryObject.objectName'
			);
		}
		Test.stopTest();
	}
}
