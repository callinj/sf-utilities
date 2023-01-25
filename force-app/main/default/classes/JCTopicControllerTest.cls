@isTest
public with sharing class JCTopicControllerTest {
	static void testSetup() {
		String communityId = getCommunityId();
		List<Topic> testTopics = new List<Topic>();
		for (Integer i = 1; i <= 5; i++) {
			Topic topic = new Topic();
			topic.Name = 'JCTopicController Test ' + i;
			topic.Description = 'JCTopicController Test ' + i + ' Description';
			topic.NetworkId = communityId;
			testTopics.add(topic);
		}
		insert testTopics;

		insert new Knowledge__kav(Title = 'TestArticle', UrlName = 'test-article');
		for (Knowledge__kav article : [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE PublishStatus = 'Draft']) {
			KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
		}

		List<Topic> listTopics = getTestTopics();
		List<KnowledgeArticleVersion> listArticles = [
			SELECT Id, Title, Summary, ArticleTotalViewCount, LastPublishedDate
			FROM KnowledgeArticleVersion
		];
		insert new TopicAssignment(TopicId = listTopics.get(0).id, EntityId = listArticles[0].Id);
	}
	static String getCommunityId() {
		String communityId = [SELECT Id FROM Network LIMIT 1].Id;
		return communityId;
	}
	static List<Topic> getTestTopics() {
		List<Topic> testTopics = [
			SELECT Id, Description, Name, TalkingAbout
			FROM Topic
			WHERE NetworkId = :getCommunityId() AND Name LIKE '%JCTopicController Test%'
		];
		return testTopics;
	}
	static List<JCTopicController.TopicWrapper> testWrappers() {
		List<JCTopicController.TopicWrapper> topicWrappers = new List<JCTopicController.TopicWrapper>();
		for (Topic testTopic : getTestTopics()) {
			// Create TopicWrapper data
			JCTopicController.TopicWrapper topicWrapper = new JCTopicController.TopicWrapper();
			topicWrapper.id = testTopic.Id;
			topicWrapper.name = testTopic.Name;
			topicWrapper.description = testTopic.Description;
			topicWrapper.isNavigational = false;
			topicWrapper.isFeatured = false;
			topicWrapper.isFollowing = false;
			topicWrapper.discussions = 1;
			topicWrapper.articles = 1;
			topicWrapper.followers = 1;
			topicWrappers.add(topicWrapper);
		}
		return topicWrappers;
	}
	static JCQueryHelper.QueryObject getSearchOptions() {
		JCQueryHelper.QueryObject queryData = JCQueryHelper.createQueryObject('Topic', 'Id, Name', 500);
		queryData.addFilter('Name', '%JCTopicController Test%', 'OR', 'LIKE');

		JCQueryHelper.QueryFilterGroup filterGroup = queryData.createFilterGroup('OR');
		filterGroup.addFilter('Name', '%JCTopicController Test%', 'OR', 'LIKE');

		queryData.setOrder('Name', false, true);

		return queryData;
	}
	static ConnectApi.TopicPage getTopicPage(Topic testApiTopic, String communityId) {
		ConnectApi.TopicPage testTopicPage = new ConnectApi.TopicPage();
		ConnectApi.Topic apiTopic = new ConnectApi.Topic();
		ConnectApi.TopicImages apiTopicImages = new ConnectApi.TopicImages();
		apiTopicImages.coverImageUrl = '/banner/image';
		apiTopicImages.featuredImageUrl = '/featured/image';
		apiTopic.name = testApiTopic.Name;
		apiTopic.description = testApiTopic.Description;
		apiTopic.createdDate = testApiTopic.CreatedDate;
		apiTopic.id = testApiTopic.Id;
		apiTopic.images = apiTopicImages;
		apiTopic.isBeingDeleted = false;
		apiTopic.url = '/topic/test/url';
		testTopicPage.currentPageUrl = '/topic/test/current/url';
		testTopicPage.nextPageUrl = '/topic/test/next/url';
		testTopicPage.topics = new List<ConnectApi.Topic>{ apiTopic };
		return testTopicPage;
	}
	static ConnectApi.ManagedTopic createFeaturedTopic() {
		String communityId = getCommunityId();
		String testTopicName = 'ApexTest Featured Topic ' + communityId;
		ConnectApi.ManagedTopic featuredTopic = ConnectApi.ManagedTopics.createManagedTopicByName(
			communityId,
			testTopicName,
			ConnectApi.ManagedTopicType.Featured
		);
		return featuredTopic;
	}
	static ConnectApi.ManagedTopic createNavigationalTopic(String topicName, String parentId) {
		String communityId = getCommunityId();
		ConnectApi.ManagedTopic navigationalTopic;
		if (parentId != null) {
			navigationalTopic = ConnectApi.ManagedTopics.createManagedTopicByName(
				communityId,
				topicName,
				ConnectApi.ManagedTopicType.Navigational,
				parentId
			);
		} else {
			navigationalTopic = ConnectApi.ManagedTopics.createManagedTopicByName(
				communityId,
				topicName,
				ConnectApi.ManagedTopicType.Navigational
			);
		}
		return navigationalTopic;
	}
	@isTest
	static void topicResponseTest() {
		testSetup();
		JCTopicController.TopicResponse testResponse = new JCTopicController.TopicResponse();
		List<JCTopicController.TopicWrapper> testWrappers = testWrappers();
		testResponse.ancestors = testWrappers;
		testResponse.relatedTopics = testWrappers;
		testResponse.totalPaginationResults = 1;
		testResponse.topic = testWrappers.get(0);
		testResponse.ancestors.sort();
		Test.startTest();
		System.assertEquals(testResponse.success, true, 'topicResponseWrappersTest success Test: failed');
		System.assertEquals(testResponse.results.size(), 0, 'topicResponseWrappersTest results size Test: failed');
		System.assertEquals(
			testResponse.relatedTopics.size(),
			5,
			'topicResponseWrappersTest relatedTopics size Test: failed'
		);
		System.assertEquals(testResponse.ancestors.size(), 5, 'topicResponseWrappersTest ancestors size Test: failed');
		System.assertEquals(
			testResponse.ancestors.get(0).Name,
			'JCTopicController Test 1',
			'topicResponseWrappersTest ancestors sort Test: failed'
		);
		System.assertEquals(
			testResponse.totalPaginationResults,
			1,
			'topicResponseWrappersTest results size Test: failed'
		);
		System.assertEquals(
			testResponse.topic.id,
			testWrappers().get(0).id,
			'topicResponseWrappersTest topic Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void topicOptionsTest() {
		testSetup();
		JCTopicController.TopicOptions testOptions = new JCTopicController.TopicOptions();
		testOptions.searchOptions = getSearchOptions();
		testOptions.communityId = getCommunityId();
		testOptions.userIds = new List<String>{ (String) UserInfo.getUserId() };
		testOptions.relatedType = 'followed';
		testOptions.trendingAmount = 25;
		testOptions.suggestedCount = 5;
		Test.startTest();
		System.assertEquals(testOptions.searchOptions.objectName, 'Topic', 'topicOptionsTest objectName Test: failed');
		System.assertEquals(testOptions.communityId, getCommunityId(), 'topicOptionsTest objectName Test: failed');
		System.assertEquals(testOptions.userIds.size(), 1, 'topicOptionsTest userIds size Test: failed');
		System.assertEquals(
			testOptions.userIds.get(0),
			(String) UserInfo.getUserId(),
			'topicOptionsTest userIds value Test: failed'
		);
		System.assertEquals(testOptions.relatedType, 'followed', 'topicOptionsTest relatedType Test: failed');
		System.assertEquals(testOptions.trendingAmount, 25, 'topicOptionsTest trendingAmount Test: failed');
		System.assertEquals(testOptions.suggestedCount, 5, 'topicOptionsTest suggestedCount Test: failed');
		Test.stopTest();
	}
	@isTest
	static void getTopicsTest() {
		testSetup();
		JCTopicController.TopicOptions testOptions = new JCTopicController.TopicOptions();
		testOptions.searchOptions = getSearchOptions();
		testOptions.communityId = getCommunityId();
		testOptions.userIds = new List<String>{ (String) UserInfo.getUserId() };
		testOptions.relatedType = 'followed';
		testOptions.trendingAmount = 25;
		testOptions.suggestedCount = 5;
		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getTopics(testOptions);
		System.assertEquals(testResponse.success, true, 'getTopicsTest success Test: failed');
		System.assertEquals(testResponse.results.size(), 5, 'getTopicsTest size Test: failed');
		System.assertEquals(testResponse.results.get(0).id, testWrappers().get(0).id, 'getTopicsTest id Test: failed');
		Test.stopTest();
	}
	@isTest
	static void getSpecifiedRelatedTopicsFollowedTest() {
		testSetup();
		JCTopicController.TopicOptions testOptions = new JCTopicController.TopicOptions();
		String communityId = getCommunityId();
		testOptions.searchOptions = getSearchOptions();
		JCQueryHelper.QueryFilter newFilter = testOptions.searchOptions.filters.get(0);
		newFilter.value = '%JCTopicController Test 1%';
		testOptions.communityId = communityId;
		testOptions.userIds = new List<String>{ (String) UserInfo.getUserId() };
		testOptions.relatedType = 'followed';
		testOptions.trendingAmount = 25;
		testOptions.suggestedCount = 5;
		Topic relatedTopic;
		Topic testTopic;
		for (Topic currentTopic : [SELECT Id, Name, CreatedDate, Description FROM Topic]) {
			if (currentTopic.Name == 'JCTopicController Test 1') {
				testTopic = currentTopic;
			}
			if (currentTopic.Name == 'JCTopicController Test 4') {
				relatedTopic = currentTopic;
			}
		}
		EntitySubscription subscription = new EntitySubscription(
			ParentId = testTopic.Id,
			SubscriberId = UserInfo.getUserId(),
			NetworkId = communityId
		);
		insert subscription;
		ConnectApi.Topics.setTestGetRelatedTopics(
			communityId,
			(String) testTopic.Id,
			getTopicPage(relatedTopic, communityId)
		);

		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getSpecifiedRelatedTopics(testOptions);
		System.assertEquals(testResponse.success, true, 'getSpecifiedRelatedTopicsFollowedTest success Test: failed');
		System.assertEquals(
			testResponse.results.size(),
			1,
			'getSpecifiedRelatedTopicsFollowedTest results size Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.size(),
			1,
			'getSpecifiedRelatedTopicsFollowedTest relatedTopics size Test: failed'
		);
		System.assertEquals(
			testResponse.results.get(0).id,
			testTopic.Id,
			'getSpecifiedRelatedTopicsFollowedTest results value Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.get(0).id,
			relatedTopic.Id,
			'getSpecifiedRelatedTopicsFollowedTest relatedTopics value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void getSpecifiedRelatedTopicsTrendingTest() {
		testSetup();
		JCTopicController.TopicOptions testOptions = new JCTopicController.TopicOptions();
		String communityId = getCommunityId();
		testOptions.searchOptions = getSearchOptions();
		JCQueryHelper.QueryFilter newFilter = testOptions.searchOptions.filters.get(0);
		newFilter.value = '%JCTopicController Test 1%';
		testOptions.communityId = communityId;
		testOptions.userIds = new List<String>{ (String) UserInfo.getUserId() };
		testOptions.relatedType = 'trending';
		testOptions.trendingAmount = 25;
		testOptions.suggestedCount = 5;
		Topic relatedTopic;
		Topic trendingTopic;
		for (Topic testTopic : [SELECT Id, Name, CreatedDate, Description FROM Topic]) {
			if (testTopic.Name == 'JCTopicController Test 1') {
				trendingTopic = testTopic;
			}
			if (testTopic.Name == 'JCTopicController Test 4') {
				relatedTopic = testTopic;
			}
		}
		ConnectApi.Topics.setTestGetRelatedTopics(
			communityId,
			(String) trendingTopic.Id,
			getTopicPage(relatedTopic, communityId)
		);
		ConnectApi.Topics.setTestGetTrendingTopics(
			communityId,
			testOptions.trendingAmount,
			getTopicPage(trendingTopic, communityId)
		);

		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getSpecifiedRelatedTopics(testOptions);
		System.assertEquals(testResponse.success, true, 'getSpecifiedRelatedTopicsTrendingTest success Test: failed');
		System.assertEquals(
			testResponse.results.size(),
			1,
			'getSpecifiedRelatedTopicsTrendingTest results size Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.size(),
			1,
			'getSpecifiedRelatedTopicsTrendingTest relatedTopics size Test: failed'
		);
		System.assertEquals(
			testResponse.results.get(0).id,
			trendingTopic.Id,
			'getSpecifiedRelatedTopicsTrendingTest results value Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.get(0).id,
			relatedTopic.Id,
			'getSpecifiedRelatedTopicsTrendingTest relatedTopics value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void getSpecifiedRelatedTopicsUserTest() {
		testSetup();
		JCTopicController.TopicOptions testOptions = new JCTopicController.TopicOptions();
		String communityId = getCommunityId();
		testOptions.searchOptions = getSearchOptions();
		JCQueryHelper.QueryFilter newFilter = testOptions.searchOptions.filters.get(0);
		newFilter.value = '%JCTopicController Test 1%';
		testOptions.communityId = communityId;
		testOptions.userIds = new List<String>{ (String) UserInfo.getUserId() };
		testOptions.relatedType = 'user';
		testOptions.trendingAmount = 25;
		testOptions.suggestedCount = 5;
		Topic relatedTopic;
		Topic usedTopic;
		for (Topic testTopic : [SELECT Id, Name, CreatedDate, Description FROM Topic]) {
			if (testTopic.Name == 'JCTopicController Test 1') {
				usedTopic = testTopic;
			}
			if (testTopic.Name == 'JCTopicController Test 4') {
				relatedTopic = testTopic;
			}
		}
		ConnectApi.Topics.setTestGetRelatedTopics(
			communityId,
			(String) usedTopic.Id,
			getTopicPage(relatedTopic, communityId)
		);
		ConnectApi.Topics.setTestGetRecentlyTalkingAboutTopicsForUser(
			communityId,
			UserInfo.getUserId(),
			getTopicPage(usedTopic, communityId)
		);

		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getSpecifiedRelatedTopics(testOptions);
		System.assertEquals(testResponse.success, true, 'getSpecifiedRelatedTopicsUserTest success Test: failed');
		System.assertEquals(
			testResponse.results.size(),
			1,
			'getSpecifiedRelatedTopicsUserTest results size Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.size(),
			1,
			'getSpecifiedRelatedTopicsUserTest relatedTopics size Test: failed'
		);
		System.assertEquals(
			testResponse.results.get(0).id,
			usedTopic.Id,
			'getSpecifiedRelatedTopicsUserTest results value Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.get(0).id,
			relatedTopic.Id,
			'getSpecifiedRelatedTopicsUserTest relatedTopics value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void getFollowedTopicsTest() {
		testSetup();
		JCTopicController.TopicOptions testOptions = new JCTopicController.TopicOptions();
		String communityId = getCommunityId();
		testOptions.searchOptions = getSearchOptions();
		JCQueryHelper.QueryFilter newFilter = testOptions.searchOptions.filters.get(0);
		newFilter.value = '%JCTopicController Test 1%';
		testOptions.communityId = communityId;
		testOptions.userIds = new List<String>{ (String) UserInfo.getUserId() };
		testOptions.relatedType = 'followed';
		testOptions.trendingAmount = 25;
		testOptions.suggestedCount = 5;
		Topic relatedTopic;
		Topic testTopic;
		for (Topic currentTopic : [SELECT Id, Name, CreatedDate, Description FROM Topic]) {
			if (currentTopic.Name == 'JCTopicController Test 1') {
				testTopic = currentTopic;
			}
			if (currentTopic.Name == 'JCTopicController Test 4') {
				relatedTopic = currentTopic;
			}
		}
		EntitySubscription subscription = new EntitySubscription(
			ParentId = testTopic.Id,
			SubscriberId = UserInfo.getUserId(),
			NetworkId = communityId
		);
		insert subscription;
		ConnectApi.Topics.setTestGetRelatedTopics(
			communityId,
			(String) testTopic.Id,
			getTopicPage(relatedTopic, communityId)
		);

		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getFollowedTopics(testOptions);
		System.assertEquals(testResponse.success, true, 'getFollowedTopicsTest success Test: failed');
		System.assertEquals(testResponse.results.size(), 1, 'getFollowedTopicsTest results size Test: failed');
		System.assertEquals(
			testResponse.relatedTopics.size(),
			1,
			'getFollowedTopicsTest relatedTopics size Test: failed'
		);
		System.assertEquals(
			testResponse.results.get(0).id,
			testTopic.Id,
			'getFollowedTopicsTest results value Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.get(0).id,
			relatedTopic.Id,
			'getFollowedTopicsTest relatedTopics value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void getTrendingTopicsTest() {
		testSetup();
		String communityId = getCommunityId();
		Integer trendingAmount = 25;
		Integer suggestedCount = 5;
		Topic relatedTopic;
		Topic trendingTopic;
		for (Topic testTopic : [SELECT Id, Name, CreatedDate, Description FROM Topic]) {
			if (testTopic.Name == 'JCTopicController Test 1') {
				trendingTopic = testTopic;
			}
			if (testTopic.Name == 'JCTopicController Test 4') {
				relatedTopic = testTopic;
			}
		}
		ConnectApi.Topics.setTestGetRelatedTopics(
			communityId,
			(String) trendingTopic.Id,
			getTopicPage(relatedTopic, communityId)
		);
		ConnectApi.Topics.setTestGetTrendingTopics(
			communityId,
			trendingAmount,
			getTopicPage(trendingTopic, communityId)
		);

		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getTrendingTopics(
			communityId,
			trendingAmount,
			suggestedCount
		);
		System.assertEquals(testResponse.success, true, 'getTrendingTopicsTest success Test: failed');
		System.assertEquals(testResponse.results.size(), 1, 'getTrendingTopicsTest results size Test: failed');
		System.assertEquals(
			testResponse.relatedTopics.size(),
			1,
			'getTrendingTopicsTest relatedTopics size Test: failed'
		);
		System.assertEquals(
			testResponse.results.get(0).id,
			trendingTopic.Id,
			'getTrendingTopicsTest results value Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.get(0).id,
			relatedTopic.Id,
			'getTrendingTopicsTest relatedTopics value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void getUsedTopicsTest() {
		testSetup();
		String communityId = getCommunityId();
		Integer suggestedCount = 5;
		Topic relatedTopic;
		Topic usedTopic;
		for (Topic testTopic : [SELECT Id, Name, CreatedDate, Description FROM Topic]) {
			if (testTopic.Name == 'JCTopicController Test 1') {
				usedTopic = testTopic;
			}
			if (testTopic.Name == 'JCTopicController Test 4') {
				relatedTopic = testTopic;
			}
		}
		ConnectApi.Topics.setTestGetRelatedTopics(
			communityId,
			(String) usedTopic.Id,
			getTopicPage(relatedTopic, communityId)
		);
		ConnectApi.Topics.setTestGetRecentlyTalkingAboutTopicsForUser(
			communityId,
			UserInfo.getUserId(),
			getTopicPage(usedTopic, communityId)
		);

		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getUsedTopics(
			communityId,
			UserInfo.getUserId(),
			suggestedCount
		);
		System.assertEquals(testResponse.success, true, 'getUsedTopicsTest success Test: failed');
		System.assertEquals(testResponse.results.size(), 1, 'getUsedTopicsTest results size Test: failed');
		System.assertEquals(testResponse.relatedTopics.size(), 1, 'getUsedTopicsTest relatedTopics size Test: failed');
		System.assertEquals(
			testResponse.results.get(0).id,
			usedTopic.Id,
			'getUsedTopicsTest results value Test: failed'
		);
		System.assertEquals(
			testResponse.relatedTopics.get(0).id,
			relatedTopic.Id,
			'getUsedTopicsTest relatedTopics value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void getRelatedTopicsTest() {
		testSetup();
		String communityId = getCommunityId();
		Integer suggestedCount = 5;
		Topic relatedTopic;
		Topic testTopic;
		for (Topic currentTopic : [SELECT Id, Name, CreatedDate, Description FROM Topic]) {
			if (currentTopic.Name == 'JCTopicController Test 1') {
				testTopic = currentTopic;
			}
			if (currentTopic.Name == 'JCTopicController Test 4') {
				relatedTopic = currentTopic;
			}
		}
		ConnectApi.Topics.setTestGetRelatedTopics(
			communityId,
			(String) testTopic.Id,
			getTopicPage(relatedTopic, communityId)
		);

		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.getRelatedTopics(
			new List<String>{ testTopic.Id },
			communityId,
			suggestedCount
		);
		System.assertEquals(testResponse.success, true, 'getRelatedTopicsTest success Test: failed');
		System.assertEquals(testResponse.results.size(), 1, 'getRelatedTopicsTest results size Test: failed');
		System.assertEquals(
			testResponse.results.get(0).id,
			relatedTopic.Id,
			'getRelatedTopicsTest results value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void manageSubscriptionsAddTest() {
		testSetup();
		Map<Id, Topic> testTopicMap = new Map<Id, Topic>([SELECT Id, Name, CreatedDate, Description FROM Topic]);
		List<String> userIds = new List<String>{ UserInfo.getUserId() };
		List<String> recordIds = (List<String>) new List<Id>(testTopicMap.keySet());
		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.manageSubscriptions(
			recordIds,
			userIds,
			getCommunityId(),
			false
		);
		List<EntitySubscription> testSubscriptions = [
			SELECT ParentId
			FROM EntitySubscription
			WHERE ParentId IN :recordIds AND SubscriberId = :userIds
		];
		System.assertEquals(true, testResponse.success, 'manageSubscriptionsAddTest success Test: failed');
		System.assertEquals(
			testTopicMap.values().size(),
			testSubscriptions.size(),
			'manageSubscriptionsAddTest results size Test: failed'
		);
		System.assertEquals(
			testTopicMap.get(testSubscriptions.get(0).ParentId).Id,
			testSubscriptions.get(0).ParentId,
			'manageSubscriptionsAddTest results value Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	static void manageSubscriptionsRemoveTest() {
		testSetup();
		String communityId = getCommunityId();
		Map<Id, Topic> testTopicMap = new Map<Id, Topic>([SELECT Id, Name, CreatedDate, Description FROM Topic]);
		List<String> userIds = new List<String>{ UserInfo.getUserId() };
		List<String> recordIds = (List<String>) new List<Id>(testTopicMap.keySet());
		EntitySubscription subscription = new EntitySubscription(
			ParentId = testTopicMap.values().get(0).Id,
			SubscriberId = UserInfo.getUserId(),
			NetworkId = communityId
		);
		insert subscription;
		Test.startTest();
		JCTopicController.TopicResponse testResponse = JCTopicController.manageSubscriptions(
			recordIds,
			userIds,
			communityId,
			true
		);
		List<EntitySubscription> testSubscriptions = [
			SELECT ParentId
			FROM EntitySubscription
			WHERE ParentId IN :recordIds AND SubscriberId = :userIds
		];
		System.assertEquals(true, testResponse.success, 'manageSubscriptionsAddTest success Test: failed');
		System.assertEquals(0, testSubscriptions.size(), 'manageSubscriptionsAddTest results size Test: failed');
		Test.stopTest();
	}

	@isTest(SeeAllData=true)
	static void managedTopicsTest() {
		testSetup();
		String communityId = getCommunityId();
		String testFirstTopicName = 'ApexTest First Level Topic ' + communityId;
		String testSecondTopicName = 'ApexTest Second Level Topic ' + communityId;

		ConnectApi.ManagedTopic testFirstTopic = createNavigationalTopic(testFirstTopicName, null);
		ConnectApi.ManagedTopic testSecondTopic = createNavigationalTopic(testSecondTopicName, testFirstTopic.id);
		JCTopicController.TopicOptions testOptions = new JCTopicController.TopicOptions();
		testOptions.searchOptions = getSearchOptions();
		testOptions.searchOptions.filters.get(0).value = '%ApexTest%';
		testOptions.communityId = communityId;
		testOptions.userIds = new List<String>{ (String) UserInfo.getUserId() };
		testOptions.relatedType = 'followed';
		testOptions.trendingAmount = 25;
		testOptions.suggestedCount = 5;

		Map<Id, Topic> testTopicMap = new Map<Id, Topic>([SELECT Id, Name, CreatedDate, Description FROM Topic]);
		List<String> userIds = new List<String>{ UserInfo.getUserId() };
		List<String> recordIds = (List<String>) new List<Id>(testTopicMap.keySet());
		EntitySubscription subscription = new EntitySubscription(
			ParentId = testTopicMap.values().get(0).Id,
			SubscriberId = UserInfo.getUserId(),
			NetworkId = communityId
		);
		insert subscription;
		Test.startTest();

		// getTopicTree Tests
		JCTopicController.TopicResponse topicTreeResponse = JCTopicController.getTopicTree(
			testOptions,
			testSecondTopic.topic.id
		);
		System.assertEquals(true, topicTreeResponse.success, 'managedTopicsTest getTopicTree success test: failed');
		System.assertEquals(
			testSecondTopic.topic.id,
			topicTreeResponse.topic.id,
			'managedTopicsTest getTopicTree topic Test: failed'
		);
		System.assertEquals(
			1,
			topicTreeResponse.ancestors.size(),
			'managedTopicsTest getTopicTree ancestors size Test: failed'
		);
		System.assertEquals(
			testFirstTopic.topic.id,
			topicTreeResponse.ancestors.get(0).id,
			'managedTopicsTest getTopicTree ancestors value Test: failed'
		);

		// setAPITopicResponse Tests
		JCTopicController.TopicResponse apiResponse = JCTopicController.setAPITopicResponse(
			new List<ConnectApi.Topic>{ testFirstTopic.topic, testSecondTopic.topic },
			communityId,
			0,
			null,
			null
		);

		System.assertEquals(2, apiResponse.results.size(), 'managedTopicsTest apiResponse results Assert Fail');
		System.assertEquals(null, apiResponse.relatedTopics, 'managedTopicsTest apiResponse relatedTopics Assert Fail');

		System.debug('queryString ===' + testOptions.searchOptions.queryString());

		// getTopics Featured Topics Defined Topics Tests
		testOptions.featuredTopics = true;
		testOptions.definedTopics = new List<String>{ testFirstTopicName };
		JCTopicController.TopicResponse defindedResponse = JCTopicController.getTopics(testOptions);
		System.assertEquals(
			true,
			defindedResponse.success,
			'managedTopics Test getTopics defined success test: failed'
		);
		System.assertEquals(1, defindedResponse.results.size(), 'managedTopicsTest defined size Test: failed');
		System.assertEquals(
			testFirstTopicName,
			defindedResponse.results.get(0).name,
			'managedTopicsTest defined name Test: failed'
		);

		// getTopics Featured Topics Tests
		ConnectApi.ManagedTopic testFeaturedTopic = createFeaturedTopic();
		testOptions.searchOptions.filters.get(0).value = '%' + testFeaturedTopic.topic.name + '%';
		testOptions.definedTopics = null;
		JCTopicController.TopicResponse featuredResponse = JCTopicController.getTopics(testOptions);
		System.assertEquals(
			true,
			featuredResponse.success,
			'managedTopics Test getTopics featured success test: failed'
		);
		System.assertEquals(1, featuredResponse.results.size(), 'managedTopicsTest featured size Test: failed');
		System.assertEquals(
			testFeaturedTopic.topic.name,
			featuredResponse.results.get(0).name,
			'managedTopicsTest featured name Test: failed'
		);

		Test.stopTest();
	}
	@isTest
	static void getCommunityTopicsMapTest() {
		testSetup();
		JCQueryHelper.QueryObject searchOptions = getSearchOptions();
		List<Topic> testTopics = getTestTopics();
		System.debug('testTopics === ' + testTopics);
		Test.startTest();
		Map<String, JCTopicController.TopicWrapper> testResponse = JCTopicController.getCommunityTopicsMap(
			searchOptions
		);
		System.assertEquals(
			testTopics.size(),
			testResponse.values().size(),
			'getCommunityTopicsMapTest respone size Test: failed'
		);
		System.assertEquals(
			testTopics.get(0).id,
			testResponse.get(testTopics.get(0).id).id,
			'getCommunityTopicsMapTest response value Test: failed'
		);
		Test.stopTest();
	}

	@isTest
	static void getAssignedTopicsTest() {
		testSetup();
		List<Topic> testTopics = getTestTopics();

		JCQueryHelper.QueryObject queryData = new JCQueryHelper.QueryObject();
		queryData.addFilter('NetworkId', getCommunityId());

		JCQueryHelper.QueryFilterGroup filterGroup = queryData.createFilterGroup('AND');
		filterGroup.addFilter('TopicId', new List<String>{ testTopics[0].id }, 'OR', 'IN');

		Test.startTest();
		Map<String, List<JCTopicController.TopicWrapper>> assignedTopics = JCTopicController.getAssignedTopics(
			queryData
		);
		System.assertEquals(1, assignedTopics.size(), 'getAssignedTopicsTest size Test: failed');
		System.assertEquals(
			testTopics[0].id,
			assignedTopics.values()[0][0].id,
			'getAssignedTopicsTest id Test: failed'
		);
		Test.stopTest();
	}
}
