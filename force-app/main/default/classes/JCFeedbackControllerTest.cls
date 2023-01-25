@isTest
public with sharing class JCFeedbackControllerTest {
	// TODO Update test to use data factory
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

	@isTest
	public static void feedbackResponseTest() {
		JCFeedbackController.FeedbackResponse test = new JCFeedbackController.FeedbackResponse();
		System.assertEquals(
			test.results.size(),
			0,
			'JCFeedbackControllerTest.FeedbackResponseTest results Assert Fail: failed'
		);
		System.assertEquals(
			test.success,
			true,
			'JCFeedbackControllerTest.FeedbackResponseTest success Assert Fail: failed'
		);
		System.assertEquals(
			test.messages.size(),
			0,
			'JCFeedbackControllerTest.FeedbackResponseTest messages Assert Fail: failed'
		);
	}

	@isTest
	public static void feedbackResponseTestFalse() {
		JCFeedbackController.FeedbackResponse test = new JCFeedbackController.FeedbackResponse();

		test.success = false;
		test.messages.add('Testing');
		test.results = new List<JCFeedbackController.FeedbackWrapper>();
		System.assertEquals(
			test.success,
			false,
			'JCFeedbackControllerTest.FeedbackResponseTestFalse Assert Fail: Success assert'
		);
		System.assertEquals(
			test.messages.size(),
			1,
			'JCFeedbackControllerTest.FeedbackResponseTestFalse Assert Fail: messages assert'
		);
		System.assertEquals(
			test.messages[0],
			'Testing',
			'JCFeedbackControllerTest.FeedbackResponseTestFalse Assert Fail: messages value'
		);
		System.assertEquals(
			test.results.size(),
			0,
			'JCFeedbackControllerTest.FeedbackResponseTestFalse Assert Fail: results assert'
		);
	}
	@isTest
	public static void feedbackWrapperTest() {
		JCFeedbackController.FeedbackWrapper testWrapper = new JCFeedbackController.FeedbackWrapper();
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
		System.runAs(providerTestUser) {
			insert new Feedback__c(
				Provider__c = providerTestUser.Id,
				Receiver__c = receiverTestUser.Id,
				InteractionDate__c = date.today()
			);
		}
		Test.startTest();
		Feedback__c testFeedback = [
			SELECT Id, Title__c, Provider__r.Name, Receiver__r.Name, CreatedDate, InteractionDate__c
			FROM Feedback__c
			WHERE Provider__c = :providerTestUser.Id
			LIMIT 1
		];

		testWrapper.id = testFeedback.Id;
		testWrapper.name = testFeedback?.Title__c;
		testWrapper.provider = testFeedback?.Provider__r.Name;
		testWrapper.receiver = testFeedback?.Receiver__r.Name;
		testWrapper.createdDate = testFeedback?.CreatedDate;
		testWrapper.mainDate = testFeedback?.InteractionDate__c;
		testWrapper.recordUrl = '/detail/' + testFeedback.Id;
		System.assertEquals(
			testFeedback.Id,
			testWrapper.id,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper id'
		);
		System.assertEquals(
			testFeedback.Title__c,
			testWrapper.name,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper name'
		);
		System.assertEquals(
			testFeedback.Provider__r.Name,
			testWrapper.provider,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper provided'
		);
		System.assertEquals(
			testFeedback.Receiver__r.Name,
			testWrapper.receiver,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper receiver'
		);
		System.assertEquals(
			testFeedback.CreatedDate,
			testWrapper.createdDate,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper createdDate'
		);
		System.assertEquals(
			testFeedback.InteractionDate__c,
			testWrapper.mainDate,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper mainDate'
		);
		System.assertEquals(
			testFeedback.Id,
			testWrapper.id,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper id'
		);
		System.assertEquals(
			'/detail/' + testFeedback.Id,
			testWrapper.recordUrl,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackWrapper recordUrl'
		);
		Test.stopTest();
	}
	@isTest
	public static void feedbackStatsTest() {
		JCFeedbackController.FeedbackStats testWrapper = new JCFeedbackController.FeedbackStats();
		testWrapper.given = 5;
		testWrapper.received = 25;
		System.assertEquals(
			5,
			testWrapper.given,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackStats given'
		);
		System.assertEquals(
			25,
			testWrapper.received,
			'JCFeedbackControllerTest.feedbackWrapperTest Assert Fail: FeedbackStats received'
		);
	}
	@isTest
	public static void getFeedbackItemsTest() {
		List<RecordType> testRecordTypes = [
			SELECT Id
			FROM RecordType
			WHERE (DeveloperName = 'Conversation' OR DeveloperName = 'Feedback') AND SobjectType = 'Feedback__c'
		];
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
		List<Feedback__c> testItems = new List<Feedback__c>();
		System.runAs(providerTestUser) {
			for (RecordType testRecordType : testRecordTypes) {
				for (Integer i = 0; i < 3; i++) {
					testItems.add(
						new Feedback__c(
							Provider__c = UserInfo.getUserId(),
							Receiver__c = receiverTestUser.Id,
							InteractionDate__c = date.today(),
							RecordTypeId = testRecordType.Id
						)
					);
				}
			}
			insert testItems;
		}
		JCQueryHelper.QueryObject queryData = JCQueryHelper.createQueryObject('Feedback__c');
		queryData.queryLimit = 5;
		queryData.offset = 0;
		queryData.fields = new List<String>{
			'Id',
			'Title__c',
			'InteractionDate__c',
			'Provider__r.Name',
			'Receiver__r.Name',
			'CreatedDate'
		};
		queryData.addFilter('CreatedDate', 'THIS_FISCAL_YEAR');
		queryData.addFilter('RecordType.DeveloperName', 'Self', 'AND', '!=');
		System.runAs(providerTestUser) {
			queryData.addFilter('Provider__c', UserInfo.getUserId());
			Test.startTest();
			JCFeedbackController.FeedbackResponse testResponse = JCFeedbackController.getFeedbackItems(queryData);
			System.assertEquals(
				queryData.queryLimit,
				testResponse.results.size(),
				'JCFeedbackControllerTest.pendingRequestsTest Assert Fail: results size'
			);
			System.assertEquals(
				testItems.size(),
				testResponse.totalResults,
				'JCFeedbackControllerTest.pendingRequestsTest Assert Fail: totalResults'
			);
			Test.stopTest();
		}
	}
	@isTest
	public static void getMyFeedbackStatsTest() {
		RecordType testRecordType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Conversation' AND SobjectType = 'Feedback__c'
			LIMIT 1
		];
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
		List<Feedback__c> testGiven = new List<Feedback__c>();
		List<Feedback__c> testReceived = new List<Feedback__c>();
		System.runAs(providerTestUser) {
			for (Integer i = 0; i < 3; i++) {
				testGiven.add(
					new Feedback__c(
						Provider__c = UserInfo.getUserId(),
						Receiver__c = receiverTestUser.Id,
						InteractionDate__c = date.today(),
						RecordTypeId = testRecordType.Id
					)
				);
			}
			insert testGiven;
		}
		System.runAs(receiverTestUser) {
			for (Integer i = 0; i < 5; i++) {
				testReceived.add(
					new Feedback__c(
						Provider__c = UserInfo.getUserId(),
						Receiver__c = providerTestUser.Id,
						InteractionDate__c = date.today(),
						RecordTypeId = testRecordType.Id
					)
				);
			}
			insert testReceived;
		}
		System.runAs(providerTestUser) {
			Test.startTest();
			JCFeedbackController.FeedbackResponse testResponse = JCFeedbackController.getMyFeedbackStats(
				'conversation'
			);
			System.assertEquals(
				testGiven.size(),
				testResponse.stats.given,
				'JCFeedbackControllerTest.getMyFeedbackStatsTest Assert Fail: results size'
			);
			System.assertEquals(
				testReceived.size(),
				testResponse.stats.received,
				'JCFeedbackControllerTest.getMyFeedbackStatsTest Assert Fail: recieved'
			);
			Test.stopTest();
		}
	}
	@isTest
	public static void getMyFeedbackStatsFeedbackTest() {
		RecordType testRecordType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Feedback' AND SobjectType = 'Feedback__c'
			LIMIT 1
		];
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
		List<Feedback__c> testGiven = new List<Feedback__c>();
		List<Feedback__c> testReceived = new List<Feedback__c>();
		System.runAs(providerTestUser) {
			for (Integer i = 0; i < 3; i++) {
				testGiven.add(
					new Feedback__c(
						Provider__c = UserInfo.getUserId(),
						Receiver__c = receiverTestUser.Id,
						InteractionDate__c = date.today(),
						RecordTypeId = testRecordType.Id
					)
				);
			}
			insert testGiven;
		}
		System.runAs(receiverTestUser) {
			for (Integer i = 0; i < 5; i++) {
				testReceived.add(
					new Feedback__c(
						Provider__c = UserInfo.getUserId(),
						Receiver__c = providerTestUser.Id,
						InteractionDate__c = date.today(),
						RecordTypeId = testRecordType.Id
					)
				);
			}
			insert testReceived;
		}
		System.runAs(providerTestUser) {
			Test.startTest();
			JCFeedbackController.FeedbackResponse testResponse = JCFeedbackController.getMyFeedbackStats('feedback');
			System.assertEquals(
				testGiven.size(),
				testResponse.stats.given,
				'JCFeedbackControllerTest.getMyFeedbackStatsTest Assert Fail: results size'
			);
			System.assertEquals(
				testReceived.size(),
				testResponse.stats.received,
				'JCFeedbackControllerTest.getMyFeedbackStatsTest Assert Fail: recieved'
			);
			Test.stopTest();
		}
	}
	@isTest
	public static void pendingRequestsTest() {
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
		List<Feedback_Request__c> testRequests = new List<Feedback_Request__c>();
		for (Integer i = 0; i < 3; i++) {
			testRequests.add(
				new Feedback_Request__c(Requester__c = receiverTestUser.Id, Reviewer__c = providerTestUser.Id)
			);
		}
		testRequests[1].Responded__c = true;
		System.runAs(receiverTestUser) {
			insert testRequests;
		}
		JCQueryHelper.QueryObject queryData = JCQueryHelper.createQueryObject('Feedback_Request__c');
		queryData.queryLimit = 1;
		queryData.offset = 0;
		queryData.fields = new List<String>{
			'Id',
			'Name',
			'Requester__r.Name',
			'Reviewer__r.Name',
			'RequestText__c',
			'CreatedDate'
		};
		queryData.addFilter('CreatedDate', 'THIS_FISCAL_YEAR');
		queryData.addFilter('Responded__c', false);
		System.runAs(providerTestUser) {
			queryData.addFilter('Reviewer__c', UserInfo.getUserId());
			Test.startTest();
			JCFeedbackController.FeedbackResponse testResponse = JCFeedbackController.pendingRequests(queryData);
			System.assertEquals(
				queryData.queryLimit,
				testResponse.results.size(),
				'JCFeedbackControllerTest.pendingRequestsTest Assert Fail: results size'
			);
			System.assertEquals(
				testRequests.size() - 1,
				testResponse.totalResults,
				'JCFeedbackControllerTest.pendingRequestsTest Assert Fail: totalResults'
			);
			Test.stopTest();
		}
	}

	@isTest
	public static void sendNotificationsTest() {
		User sharedUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		Feedback__c testFeedback = new Feedback__c(
			Provider__c = sharedUser.Id,
			Receiver__c = UserInfo.getUserId(),
			InteractionDate__c = date.today()
		);

		System.runAs(sharedUser) {
			insert testFeedback;
		}

		Test.startTest();
		JCUtils.shareRecord(testFeedback.Id, receiverTestUser.Id);
		Feedback__Share shareRecord = [
			SELECT Id, UserOrGroupId, ParentId, LastModifiedById
			FROM Feedback__Share
			WHERE UserOrGroupId = :receiverTestUser.Id AND ParentId = :testFeedback.Id
		];
		System.assertEquals(
			receiverTestUser.Id,
			shareRecord.UserOrGroupId,
			'JCFeedbackControllerTest.sendNotificationsTest Assert Fail: Incorrect UserOrGroupId'
		);
		System.assertEquals(
			testFeedback.Id,
			shareRecord.ParentId,
			'JCFeedbackControllerTest.sendNotificationTest Assert Fail: Incorrect ParentId'
		);
		Test.stopTest();
	}

	@isTest
	public static void getSharedFeedbackTest() {
		JCFeedbackController.FeedbackResponse response = new JCFeedbackController.FeedbackResponse();

		User sharedUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		Feedback__c testFeedback = new Feedback__c(
			Provider__c = sharedUser.Id,
			Receiver__c = UserInfo.getUserId(),
			InteractionDate__c = date.today()
		);

		System.runAs(sharedUser) {
			insert testFeedback;
		}

		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject(
			'Feedback__Share',
			new List<String>{ 'Id', 'ParentId', 'Parent.Title__c', 'LastModifiedDate' },
			5,
			0
		);
		searchOptions.addFilter('UserOrGroupId', receiverTestUser.Id);
		searchOptions.addFilter('RowCause', 'Manual');

		Test.startTest();
		JCUtils.shareRecord(testFeedback.Id, receiverTestUser.Id);
		response = JCFeedbackController.getSharedFeedback(searchOptions);
		System.assertEquals(
			true,
			response.success,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect success'
		);
		System.assertEquals(
			1,
			response.totalResults,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect totalResults'
		);
		System.assertEquals(
			'Feedback from Provider Test',
			response.results[0].name,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect name'
		);
		Test.stopTest();
	}

	@isTest
	public static void getSharedWithMeTest() {
		JCFeedbackController.FeedbackResponse response = new JCFeedbackController.FeedbackResponse();

		User sharedUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_PROVIDER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];
		User receiverTestUser = [
			SELECT Id
			FROM User
			WHERE FirstName = :TEST_RECEIVER_FIRSTNAME AND LastName = :TEST_USER_LASTNAME
		];

		Feedback__c testFeedback = new Feedback__c(
			Provider__c = sharedUser.Id,
			Receiver__c = UserInfo.getUserId(),
			InteractionDate__c = date.today()
		);
		Goal__c testGoal = new Goal__c(Name = 'Test Priority', Status__c = 'Not Started');
		Feedback__c testFeedback2 = new Feedback__c(
			Provider__c = sharedUser.Id,
			Receiver__c = UserInfo.getUserId(),
			InteractionDate__c = date.today()
		);

		List<SObject> testRecords = new List<SObject>{ testFeedback, testGoal, testFeedback2 };
		List<SObject> shareRecords = new List<SObject>();

		System.runAs(sharedUser) {
			insert testRecords;

			for (SObject record : testRecords) {
				Id recordId = (Id) record.get('Id');
				String objectName = String.valueOf(recordId.getSobjectType());
				String shareObjectName = objectName.replaceAll('__c', '__') + 'Share';
				SObject shareObject = Schema.getGlobalDescribe().get(shareObjectName).newSObject(null, true);
				shareObject.put('UserOrGroupId', receiverTestUser.Id);
				shareObject.put('ParentId', recordId);
				shareObject.put('AccessLevel', 'Read');
				shareRecords.add(shareObject);
			}

			insert shareRecords;
		}

		JCQueryHelper.QueryObject feedbackOptions = JCQueryHelper.createQueryObject(
			'Feedback__Share',
			new List<String>{ 'Id', 'ParentId', 'Parent.Title__c', 'LastModifiedDate' },
			5,
			0
		);
		feedbackOptions.addFilter('UserOrGroupId', receiverTestUser.Id);
		feedbackOptions.addFilter('RowCause', 'Manual');
		feedbackOptions.setOrder('LastModifiedDate', true, true);

		JCQueryHelper.QueryObject goalOptions = JCQueryHelper.createQueryObject(
			'Goal__Share',
			new List<String>{ 'Id', 'ParentId', 'Parent.Title__c', 'Parent.Name', 'LastModifiedDate' },
			5,
			0
		);
		goalOptions.addFilter('UserOrGroupId', receiverTestUser.Id);
		goalOptions.addFilter('RowCause', 'Manual');
		goalOptions.setOrder('LastModifiedDate', true, true);

		List<JCFeedbackController.FeedbackWrapper> wrappers = new List<JCFeedbackController.FeedbackWrapper>();

		for (Feedback__Share item : (List<Feedback__Share>) feedbackOptions.getResults()) {
			JCFeedbackController.FeedbackWrapper wrapper = new JCFeedbackController.FeedbackWrapper();
			wrapper.id = item.Id;
			wrapper.name = item?.Parent.Title__c;
			wrapper.createdDate = item?.LastModifiedDate;
			wrapper.recordUrl = '/detail/' + item.ParentId;
			wrapper.objectName = feedbackOptions.objectName;
			wrappers.add(wrapper);
		}

		for (Goal__Share item : (List<Goal__Share>) goalOptions.getResults()) {
			JCFeedbackController.FeedbackWrapper wrapper = new JCFeedbackController.FeedbackWrapper();
			wrapper.id = item.Id;
			wrapper.name = item?.Parent.Title__c + ': ' + item?.Parent.Name;
			wrapper.createdDate = item?.LastModifiedDate;
			wrapper.recordUrl = '/detail/' + item?.ParentId;
			wrapper.objectName = goalOptions.objectName;
			wrappers.add(wrapper);
		}
		wrappers.sort();

		Test.startTest();
		response = JCFeedbackController.getSharedWithMe(feedbackOptions, goalOptions);
		System.assertEquals(
			true,
			response.success,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect success'
		);
		System.assertEquals(
			3,
			response.totalResults,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect totalResults'
		);
		System.assertEquals(
			wrappers[0].name,
			response.results[0].name,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect name'
		);
		System.assertEquals(
			wrappers[1].name,
			response.results[1].name,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect name'
		);
		System.assertEquals(
			wrappers[2].name,
			response.results[2].name,
			'JCFeedbackControllerTest.getSharedFeedbackTest Assert Fail: Incorrect name'
		);
		Test.stopTest();
	}
}
