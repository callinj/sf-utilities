@isTest
public class JCFilesControllerTest {
	// TODO Update test to use test factory
	static final String TEST_PERMISSION_SET = 'Career Management User';
	static final String TEST_FIRSTNAME = 'Apex';
	static final String TEST_LASTNAME = 'Test';
	static final String TEST_EMAIL = 'apextest@email.com';
	@testSetup
	static void setup() {
		//Add test setup data here
		//Add test setup data here
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
		PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Label = :TEST_PERMISSION_SET];
		List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
		assignments.add(new PermissionSetAssignment(PermissionSetId = testPermissionSet.Id, AssigneeId = testUser.Id));
		insert assignments;
		System.runAs(testUser) {
			insert new Account(Name = 'Apex Test Account');
			Blob fileBlob = Blob.valueOf('Apex test file');
			List<ContentVersion> testFiles = new List<ContentVersion>();
			for (Integer i = 0; i < 2; i++) {
				String fileName = 'ApexTest' + i;
				testFiles.add(
					new ContentVersion(Title = fileName, PathOnClient = fileName + '.jpg', VersionData = fileBlob)
				);
			}
			insert testFiles;
		}

	}
	@isTest
	public static void assignFilesToRecordTest() {
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_FIRSTNAME AND LastName = :TEST_LASTNAME];
		System.runAs(testUser) {
			Account testAccount = [SELECT Id FROM Account LIMIT 1];
			Map<String, ContentDocument> testFiles = new Map<String, ContentDocument>([SELECT Id FROM ContentDocument]);
			Test.startTest();
			JCResponse testResponse = JCFilesController.assignFilesToRecord(
				new List<String>(testFiles.keySet()),
				testAccount.Id
			);
			List<ContentDocumentLink> testLinks = [
				SELECT Id
				FROM ContentDocumentLink
				WHERE ContentDocumentId IN :testFiles.keySet() AND LinkedEntityId = :testAccount.Id
			];
			System.assertEquals(
				true,
				testResponse.success,
				'JCFilesControllerTest.assignFilesToRecordTest Assert Fail: success'
			);
			System.assertEquals(
				testFiles.size(),
				testLinks.size(),
				'JCFilesControllerTest.assignFilesToRecordTest Assert Fail: content document link size'
			);
			Test.stopTest();
		}

	}
	@isTest
	public static void assignFilesToRecordExceptionTest() {
		User testUser = [SELECT Id FROM User WHERE FirstName = :TEST_FIRSTNAME AND LastName = :TEST_LASTNAME];
		System.runAs(testUser) {
			Account testAccount = [SELECT Id FROM Account LIMIT 1];
			Map<String, ContentDocument> testFiles = new Map<String, ContentDocument>([SELECT Id FROM ContentDocument]);
			Test.startTest();
			JCResponse testResponse = JCFilesController.assignFilesToRecord(
				new List<String>(testFiles.keySet()),
				'1234'
			);
			System.assertEquals(
				false,
				testResponse.success,
				'JCFilesControllerTest.assignFilesToRecordTest Assert Fail: success'
			);
			System.assertEquals(
				1,
				testResponse.messages.size(),
				'JCFilesControllerTest.assignFilesToRecordTest Assert Fail: message size'
			);
			Test.stopTest();
		}

	}
}
