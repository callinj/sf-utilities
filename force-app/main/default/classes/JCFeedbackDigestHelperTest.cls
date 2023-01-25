@isTest
public with sharing class JCFeedbackDigestHelperTest {
	static final String TEST_PERMISSION_SET = 'Career_Management_User';
	static final String TEST_PROVIDER_FIRSTNAME = 'Provider';
	static final String TEST_RECEIVER_FIRSTNAME = 'Receiver';
	static final String TEST_USER_LASTNAME = 'Test';
	static final String TEST_USER_EMAIL = '@email.com';
	@testSetup
	static void setup() {
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

	private static String getRecordTypeId(String recordType) {
		return [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Feedback__c' AND DeveloperName = :recordType
		]
		.Id;
	}

	private static void createShareRecords(List<SObject> records, String userId) {
		List<SObject> shareRecords = new List<SObject>();
		for (SObject record : records) {
			Id recordId = (Id) record.get('Id');
			String objectName = String.valueOf(recordId.getSobjectType());
			String shareObjectName = objectName.replaceAll('__c', '__') + 'Share';
			SObject shareObject = Schema.getGlobalDescribe().get(shareObjectName).newSObject(null, true);
			shareObject.put('UserOrGroupId', userId);
			shareObject.put('ParentId', recordId);
			shareObject.put('AccessLevel', 'Read');
			shareRecords.add(shareObject);
		}
		insert shareRecords;
	}

	@isTest
	static void getConversationsTest() {
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		JCFeedbackDigestHelper helper = new JCFeedbackDigestHelper();
		helper.userId = receiverTestUser.Id;

		List<Feedback__c> testFeedbacks = new List<Feedback__c>();

		for (Integer i = 0; i < 3; i++) {
			Feedback__c feedback = new Feedback__c();
			feedback.RecordTypeId = getRecordTypeId('Conversation');
			feedback.Provider__c = UserInfo.getUserId();
			feedback.Receiver__c = receiverTestUser.Id;
			feedback.InteractionDate__c = Date.today().addDays(-1);
			testFeedbacks.add(feedback);
		}
		insert testFeedbacks;

		List<Feedback__c> feedbacks = new List<Feedback__c>();

		Test.startTest();
		feedbacks = helper.getConversations();
		System.assertEquals(3, feedbacks.size(), 'JCFeedbackDigestHelperTest.getConversationsTest() Assert Fail: size');
		System.assertEquals(
			receiverTestUser.Id,
			feedbacks[0].Receiver__c,
			'JCFeedbackDigestHelperTest.getConversationsTest() Assert Fail: Receiver__c'
		);
		Test.stopTest();
	}

	@isTest
	static void getFeedbacksTest() {
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		JCFeedbackDigestHelper helper = new JCFeedbackDigestHelper();
		helper.userId = receiverTestUser.Id;

		List<Feedback__c> testFeedbacks = new List<Feedback__c>();

		for (Integer i = 0; i < 3; i++) {
			Feedback__c feedback = new Feedback__c();
			feedback.RecordTypeId = getRecordTypeId('Feedback');
			feedback.Provider__c = UserInfo.getUserId();
			feedback.Receiver__c = receiverTestUser.Id;
			feedback.InteractionDate__c = Date.today().addDays(-1);
			testFeedbacks.add(feedback);
		}
		insert testFeedbacks;

		List<Feedback__c> feedbacks = new List<Feedback__c>();

		Test.startTest();
		feedbacks = helper.getFeedbacks();
		System.assertEquals(3, feedbacks.size(), 'JCFeedbackDigestHelperTest.getFeedbacksTest() Assert Fail: size');
		System.assertEquals(
			receiverTestUser.Id,
			feedbacks[0].Receiver__c,
			'JCFeedbackDigestHelperTest.getFeedbacksTest() Assert Fail: Receiver__c'
		);
		Test.stopTest();
	}

	@isTest
	static void getRequestsTest() {
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		JCFeedbackDigestHelper helper = new JCFeedbackDigestHelper();
		helper.userId = receiverTestUser.Id;

		List<Feedback_Request__c> testFeedbackRequests = new List<Feedback_Request__c>();

		for (Integer i = 0; i < 3; i++) {
			Feedback_Request__c feedbackRequest = new Feedback_Request__c();
			feedbackRequest.Requester__c = UserInfo.getUserId();
			feedbackRequest.Reviewer__c = receiverTestUser.Id;
			feedbackRequest.Comments__c = 'Apex Test Class';
			testFeedbackRequests.add(feedbackRequest);
		}
		insert testFeedbackRequests;

		List<Feedback_Request__c> feedbackRequests = new List<Feedback_Request__c>();

		Test.startTest();
		feedbackRequests = helper.getRequests();
		System.assertEquals(
			3,
			feedbackRequests.size(),
			'JCFeedbackDigestHelperTest.getFeedbacksTest() Assert Fail: size'
		);
		System.assertEquals(
			receiverTestUser.Id,
			feedbackRequests[0].Reviewer__c,
			'JCFeedbackDigestHelperTest.getFeedbacksTest() Assert Fail: Receiver__c'
		);
		Test.stopTest();
	}

	@isTest
	public static void getSharedConversationsTest() {
		User shareUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		JCFeedbackDigestHelper helper = new JCFeedbackDigestHelper();
		helper.userId = shareUser.Id;

		List<Feedback__c> testFeedbacks = new List<Feedback__c>();

		for (Integer i = 0; i < 3; i++) {
			Feedback__c feedback = new Feedback__c();
			feedback.RecordTypeId = getRecordTypeId('Conversation');
			feedback.Provider__c = UserInfo.getUserId();
			feedback.Receiver__c = receiverTestUser.Id;
			feedback.InteractionDate__c = Date.today().addDays(-1);
			testFeedbacks.add(feedback);
		}
		insert testFeedbacks;

		createShareRecords(testFeedbacks, shareUser.Id);

		Test.startTest();
		List<Feedback__Share> feedbacks = helper.getSharedConversations();
		System.assertEquals(
			3,
			feedbacks.size(),
			'JCFeedbackDigestHelperTest.getSharedConversationsTest() Assert Fail: size'
		);
		System.assertEquals(
			'Conversation with Receiver Test',
			feedbacks[0].Parent.Title__c,
			'JCFeedbackDigestHelperTest.getSharedConversationsTest() Assert Fail: Title__c'
		);
		Test.stopTest();
	}

	@isTest
	public static void getSharedFeedbacksTest() {
		User shareUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		JCFeedbackDigestHelper helper = new JCFeedbackDigestHelper();
		helper.userId = shareUser.Id;

		List<Feedback__c> testFeedbacks = new List<Feedback__c>();

		for (Integer i = 0; i < 3; i++) {
			Feedback__c feedback = new Feedback__c();
			feedback.RecordTypeId = getRecordTypeId('Feedback');
			feedback.Provider__c = UserInfo.getUserId();
			feedback.Receiver__c = receiverTestUser.Id;
			feedback.StartDate__c = Date.today().addDays(-1);
			feedback.EndDate__c = Date.today();
			testFeedbacks.add(feedback);
		}
		insert testFeedbacks;

		createShareRecords(testFeedbacks, shareUser.Id);

		Test.startTest();
		List<Feedback__Share> feedbacks = helper.getSharedFeedbacks();
		System.assertEquals(
			3,
			feedbacks.size(),
			'JCFeedbackDigestHelperTest.getSharedConversationsTest() Assert Fail: size'
		);
		System.assertEquals(
			'Feedback for Receiver Test',
			feedbacks[0].Parent.Title__c,
			'JCFeedbackDigestHelperTest.getSharedConversationsTest() Assert Fail: Title__c'
		);
		Test.stopTest();
	}

	@isTest
	public static void getSharedSelfReflectionsTest() {
		User providerTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		JCFeedbackDigestHelper helper = new JCFeedbackDigestHelper();
		helper.userId = receiverTestUser.Id;

		List<Feedback__c> testFeedbacks = new List<Feedback__c>();

		System.runAs(providerTestUser) {
			for (Integer i = 0; i < 3; i++) {
				Feedback__c feedback = new Feedback__c();
				feedback.RecordTypeId = getRecordTypeId('Self');
				feedback.StartDate__c = Date.today().addDays(-1);
				feedback.EndDate__c = Date.today();
				testFeedbacks.add(feedback);
			}
			insert testFeedbacks;
		}

		createShareRecords(testFeedbacks, receiverTestUser.Id);

		Test.startTest();
		List<Feedback__Share> feedbacks = helper.getSharedSelfReflections();
		System.assertEquals(
			3,
			feedbacks.size(),
			'JCFeedbackDigestHelperTest.getSharedConversationsTest() Assert Fail: size'
		);
		System.assertEquals(
			testFeedbacks[0].Id,
			feedbacks[0].ParentId,
			'JCFeedbackDigestHelperTest.getSharedConversationsTest() Assert Fail: Title__c'
		);
		Test.stopTest();
	}

	@isTest
	public static void getSharedPrioritiesTest() {
		User providerTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		String recordTypeId = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Goal__c' AND DeveloperName = 'Priority'
		]
		.Id;

		JCFeedbackDigestHelper helper = new JCFeedbackDigestHelper();
		helper.userId = receiverTestUser.Id;

		List<Goal__c> testPriorities = new List<Goal__c>();

		System.runAs(providerTestUser) {
			for (Integer i = 0; i < 3; i++) {
				Goal__c goal = new Goal__c();
				goal.Name = 'Test Priority ' + i;
				goal.RecordTypeId = recordTypeId;
				goal.Status__c = 'Not Started';
				testPriorities.add(goal);
			}
			insert testPriorities;
		}

		createShareRecords(testPriorities, receiverTestUser.Id);

		Test.startTest();
		List<Goal__Share> priorities = helper.getSharedPriorities();
		System.assertEquals(
			3,
			priorities.size(),
			'JCFeedbackDigestHelperTest.getSharedConversationsTest() Assert Fail: size'
		);
		System.assertEquals(
			'Provider\'s Priority',
			priorities[0].Parent.Title__c,
			'JCFeedbackDigestHelperTest.getSharedPrioritiesTest() Assert Fail: Title__c'
		);
		System.assertEquals(
			'Test Priority 0',
			priorities[0].Parent.Name,
			'JCFeedbackDigestHelperTest.getSharedPrioritiesTest() Assert Fail: Name'
		);
		Test.stopTest();
	}
}
