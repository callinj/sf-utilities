public with sharing class JCUpdateShareRecordsBatch implements Database.Batchable<SObject> {
	static final String TD_SHARE_REASON = 'Share_record_with_employee_lead__c';
	static final String FEEDBACK_GOAL_SHARE_REASON = 'Share_record_with_receiver_lead__c';
	public Map<String, JCUserTriggerHandler.UserPeopleLeadWrapper> userPeopleLeads;
	private PermissionSetAssignment assignedPermission;

	public JCUpdateShareRecordsBatch(Map<String, JCUserTriggerHandler.UserPeopleLeadWrapper> userPeopleLeadsWrapper) {
		userPeopleLeads = userPeopleLeadsWrapper;

		String permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Talent_Decision_Management' LIMIT 1]?.Id;
		assignedPermission = new PermissionSetAssignment(
			PermissionSetId = permissionSetId,
			AssigneeId = UserInfo.getUserId()
		);
		insert assignedPermission;
	}

	public Database.QueryLocator start(Database.BatchableContext context) {
		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject('User', 'Id');
		searchOptions.addFilter('Id', new List<String>(userPeopleLeads.keySet()), 'AND', 'IN');
		if (Test.isRunningTest()) {
			searchOptions.queryLimit = 200;
		}
		return Database.getQueryLocator(searchOptions.queryString());
	}

	public void execute(Database.BatchableContext context, List<User> records) {
		// Retrieve all share records for Feedback, Goal, Talent Decision
		List<String> currentUserIds = new List<String>();
		for (User user : records) {
			currentUserIds.add(user.Id);
		}

		// TODO - Set filter to Receiver__c IN records - POC
		// Retrieve all Feedback__c records
		JCQueryHelper.QueryObject feedbackOptions = JCQueryHelper.createQueryObject(
			'Feedback__c',
			'Id, CreatedById, Receiver__c'
		);
		feedbackOptions.addFilter('RecordType.DeveloperName', 'Self', 'AND', '!=');
		feedbackOptions.addFilter('Receiver__c', currentUserIds, 'AND', 'IN');

		// TODO - make List<QueryHelper>
		updateShareRecords(feedbackOptions, userPeopleLeads);

		// TODO Confirm with business - May not need goals at all
		// Retrieve all Goal__c records
		JCQueryHelper.QueryObject goalOptions = JCQueryHelper.createQueryObject(
			'Goal__c',
			'Id, CreatedById, Receiver__c'
		);
		goalOptions.addFilter('CreatedById', currentUserIds, 'AND', 'IN');
		goalOptions.addFilter('Receiver__c', null, 'AND', '!=');

		updateShareRecords(goalOptions, userPeopleLeads);

		// Retrieve all Talent_Decision__c records
		JCQueryHelper.QueryObject talentDecisionOptions = JCQueryHelper.createQueryObject(
			'Talent_Decision__c',
			'Id, Employee__c'
		);
		talentDecisionOptions.addFilter('Employee__c', currentUserIds, 'AND', 'IN');

		updateShareRecords(talentDecisionOptions, userPeopleLeads);
	}

	public static void updateShareRecords(
		JCQueryHelper.QueryObject searchOptions,
		Map<String, JCUserTriggerHandler.UserPeopleLeadWrapper> userPeopleLeads
	) {
		// INFO - Source of Truth - Deleting and Creating share records
		Map<String, SObject> records = new Map<String, SObject>(searchOptions.getResults());
		List<String> recordIds = new List<String>(records.keySet());
		String shareObjectName = searchOptions.objectName.replaceAll('__c', '__') + 'Share'; // TODO - Make into a utility

		List<String> oldPeopleLeads = new List<String>();
		for (JCUserTriggerHandler.UserPeopleLeadWrapper user : userPeopleLeads.values()) {
			oldPeopleLeads.add(user.oldPeopleLeadId);
		}

		// TODO - Update to list of QueryHelper
		deleteShareRecords(shareObjectName, recordIds, oldPeopleLeads);

		Boolean isTalentDecisionObject = searchOptions.objectName == 'Talent_Decision__c';
		String lookupField = isTalentDecisionObject ? 'Employee__c' : 'Receiver__c';
		String shareReason = isTalentDecisionObject ? TD_SHARE_REASON : FEEDBACK_GOAL_SHARE_REASON;

		// Holds the records for new share records
		List<SObject> shareRecords = new List<SObject>();

		for (SObject record : records.values()) {
			if (userPeopleLeads.get((String) record.get(lookupField))?.newPeopleLeadId != null) {
				SObject shareObject = Schema.getGlobalDescribe().get(shareObjectName).newSObject(null, true);
				shareObject.put('UserOrGroupId', userPeopleLeads.get((String) record.get(lookupField)).newPeopleLeadId);
				shareObject.put('ParentId', record.Id);
				shareObject.put('AccessLevel', 'Read');
				shareObject.put('RowCause', shareReason);
				shareRecords.add(shareObject);
			}
		}

		insert Security.stripInaccessible(AccessType.CREATABLE, shareRecords).getRecords();
	}

	public static void deleteShareRecords(String objectName, List<String> recordIds, List<String> oldPeopleLeads) {
		System.debug('objectName === ' + objectName);
		System.debug('oldPeopleLeads === ' + oldPeopleLeads);
		System.debug('recordIds === ' + recordIds);
		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject(objectName, 'Id');
		searchOptions.addFilter('ParentId', recordIds, 'AND', 'IN');
		searchOptions.addFilter('UserOrGroupId', oldPeopleLeads, 'AND', 'IN');
		JCQueryHelper.QueryFilterGroup filterGroup = searchOptions.createFilterGroup('AND');
		filterGroup.addFilter('RowCause', TD_SHARE_REASON, 'OR', '=');
		filterGroup.addFilter('RowCause', FEEDBACK_GOAL_SHARE_REASON, 'OR', '=');
		System.debug('queryString === ' + searchOptions.queryString());
		delete searchOptions.getResults();
	}

	public void finish(Database.BatchableContext context) {
		delete assignedPermission;
	}
}
