public with sharing class JCFeedbackDigestHelper {
	public List<Feedback__c> conversations;
	public List<Feedback__c> feedbacks;
	public List<Feedback_Request__c> requests;
	public List<Feedback__Share> sharedConversations;
	public List<Feedback__Share> sharedFeedbacks;
	public List<Feedback__Share> sharedSelfReflections;
	public List<Goal__Share> sharedPriorities;
	public List<JCFeedbackController.FeedbackWrapper> shareRecords;
	public String userId { get; set; }
	public String communityUrl { get; set; }
	public String baseUrl { get; set; }
	public String dateRange { get; set; }
	public String dashboardUrl { get; set; }

	static final Map<Integer, String> MONTHS = new Map<Integer, String>{
		1 => 'January',
		2 => 'February',
		3 => 'March',
		4 => 'April',
		5 => 'May',
		6 => 'June',
		7 => 'July',
		8 => 'August',
		9 => 'September',
		10 => 'October',
		11 => 'November',
		12 => 'December'
	};

	public JCFeedbackDigestHelper() {
		communityUrl = 'https://' + [SELECT Id, Domain FROM Domain][0].Domain + '/performance';
		baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/page/home';
		dashboardUrl =
			URL.getSalesforceBaseUrl().toExternalForm() +
			'/' +
			[
				SELECT Id, IsDeleted, FolderName, Title
				FROM Dashboard
				WHERE Title = 'JC Performance Tool: License Usage Dashboard'
			]
			?.Id;

		Integer currentDay = Date.today().day();
		Integer sevenDaysAgo = Date.today().addDays(-7).day();
		String currentMonth = MONTHS.get(Date.today().month());
		String lastMonth = MONTHS.get(Date.today().addDays(-7).month());
		Integer currentYear = Date.today().year();
		Integer lastYear = Date.today().addDays(-7).year();

		dateRange = lastMonth + ' ' + sevenDaysAgo;

		if (lastYear == currentYear) {
			dateRange += '-';
		} else {
			dateRange += ', ' + lastYear + '-';
		}

		if (lastMonth != currentMonth) {
			dateRange += currentMonth + ' ';
		}

		dateRange += currentDay + ', ' + currentYear;
	}

	// Retrieves Feedback Items with a RecordType of 'Conversation'
	public List<Feedback__c> getConversations() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Feedback__c',
			'Id, Title__c, Receiver__c'
		);
		queryObject.addFilter('Receiver__c', userId, 'AND', '=');
		queryObject.addFilter('RecordType.Name', 'Conversation', 'AND', '=');
		queryObject.addFilter('CreatedDate', 'LAST_N_DAYS:7', 'AND', '=');
		conversations = queryObject.getResults();

		return conversations;
	}

	// Retrieves Feedback Items with a RecordType of 'Feedback'
	public List<Feedback__c> getFeedbacks() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Feedback__c',
			'Id, Title__c, Receiver__c'
		);
		queryObject.addFilter('Receiver__c', userId, 'AND', '=');
		queryObject.addFilter('RecordType.Name', 'Feedback', 'AND', '=');
		queryObject.addFilter('CreatedDate', 'LAST_N_DAYS:7', 'AND', '=');
		feedbacks = queryObject.getResults();

		return feedbacks;
	}

	// Retrieves Feedback Requests that userId has not responded to
	public List<Feedback_Request__c> getRequests() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Feedback_Request__c',
			'Id, RequestText__c, Reviewer__c'
		);
		queryObject.addFilter('Reviewer__c', userId, 'AND', '=');
		queryObject.addFilter('Responded__c', false, 'AND', '=');
		queryObject.addFilter('CreatedDate', 'LAST_N_DAYS:7', 'AND', '=');
		requests = queryObject.getResults();

		return requests;
	}

	public List<Feedback__Share> getSharedConversations() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Feedback__Share',
			'Id, ParentId, Parent.Title__c, LastModifiedDate'
		);
		queryObject.addFilter('UserOrGroupId', userId, 'AND', '=');
		queryObject.addFilter('Parent.RecordType.Name', 'Conversation', 'AND', '=');
		queryObject.addFilter('LastModifiedDate', 'LAST_N_DAYS:7', 'AND', '=');
		JCQueryHelper.QueryFilterGroup filterGroup = queryObject.createFilterGroup('AND');
		filterGroup.addFilter('RowCause', 'Manual', 'OR', '=');
		filterGroup.addFilter('RowCause', 'Share_record_with_receiver__c', 'OR', '=');
		sharedConversations = queryObject.getResults();

		return sharedConversations;
	}

	public List<Feedback__Share> getSharedFeedbacks() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Feedback__Share',
			'Id, ParentId, Parent.Title__c, LastModifiedDate'
		);
		queryObject.addFilter('UserOrGroupId', userId, 'AND', '=');
		queryObject.addFilter('Parent.RecordType.Name', 'Feedback', 'AND', '=');
		queryObject.addFilter('LastModifiedDate', 'LAST_N_DAYS:7', 'AND', '=');
		JCQueryHelper.QueryFilterGroup filterGroup = queryObject.createFilterGroup('AND');
		filterGroup.addFilter('RowCause', 'Manual', 'OR', '=');
		filterGroup.addFilter('RowCause', 'Share_record_with_receiver__c', 'OR', '=');
		sharedFeedbacks = queryObject.getResults();

		return sharedFeedbacks;
	}

	public List<Feedback__Share> getSharedSelfReflections() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Feedback__Share',
			'Id, ParentId, Parent.Title__c, LastModifiedDate'
		);
		queryObject.addFilter('UserOrGroupId', userId, 'AND', '=');
		queryObject.addFilter('Parent.RecordType.Name', 'Self', 'AND', '=');
		queryObject.addFilter('LastModifiedDate', 'LAST_N_DAYS:7', 'AND', '=');
		JCQueryHelper.QueryFilterGroup filterGroup = queryObject.createFilterGroup('AND');
		filterGroup.addFilter('RowCause', 'Manual', 'OR', '=');
		filterGroup.addFilter('RowCause', 'Share_record_with_receiver__c', 'OR', '=');
		sharedSelfReflections = queryObject.getResults();

		return sharedSelfReflections;
	}

	public List<Goal__Share> getSharedPriorities() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject(
			'Goal__Share',
			'Id, ParentId, Parent.Name, Parent.Title__c, LastModifiedDate'
		);
		queryObject.addFilter('UserOrGroupId', userId, 'AND', '=');
		queryObject.addFilter('Parent.RecordType.Name', 'Priority', 'AND', '=');
		queryObject.addFilter('LastModifiedDate', 'LAST_N_DAYS:7', 'AND', '=');
		JCQueryHelper.QueryFilterGroup filterGroup = queryObject.createFilterGroup('AND');
		filterGroup.addFilter('RowCause', 'Manual', 'OR', '=');
		filterGroup.addFilter('RowCause', 'Share_With_Provider__c', 'OR', '=');
		sharedPriorities = queryObject.getResults();

		return sharedPriorities;
	}
}
