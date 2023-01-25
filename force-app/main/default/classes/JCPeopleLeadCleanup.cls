public with sharing class JCPeopleLeadCleanup implements Database.Batchable<sObject> {
	public String permissionSetId;

	public JCPeopleLeadCleanup() {
		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject('PermissionSet', 'Id');
		searchOptions.addFilter('Name', 'People_Lead', 'AND', '=');
		permissionSetId = searchOptions.getResults()[0].Id;
	}

	public Database.QueryLocator start(Database.BatchableContext context) {
		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject('User', 'Id, People_Lead__c');
		searchOptions.addFilter('IsActive', true, 'AND', '=');

		// JCQueryHelper.QueryObject psOptions = JCQueryHelper.createQueryObject('PermissionSet', 'Id');
		// psOptions.addFilter('Name', 'People_Lead', 'AND', '=');
		// permissionSetId = psOptions.getResults()[0].Id;

		if (Test.isRunningTest()) {
			searchOptions.queryLimit = 200;
			// searchOptions.addFilter('Email', '%@email.com', 'AND', 'LIKE');
			// searchOptions.addFilter('People_Lead__c', null, 'AND', '!=');
			searchOptions.setOrder('CreatedDate', true, true);
		}

		return Database.getQueryLocator(searchOptions.queryString());
	}

	public void execute(Database.BatchableContext context, List<SObject> users) {
		Set<String> peopleLeads = new Set<String>();
		List<String> userIds = new List<String>();

		for (User user : (List<User>) users) {
			userIds.add(user.Id);
		}

		try {
			JCQueryHelper.QueryObject psaOptions = JCQueryHelper.createQueryObject('PermissionSetAssignment', 'Id');
			psaOptions.addFilter('PermissionSetId', permissionSetId, 'AND', '=');
			psaOptions.addFilter('AssigneeId', userIds, 'AND', 'IN');
			List<PermissionSetAssignment> assignments = (List<PermissionSetAssignment>) psaOptions.getResults();
			delete assignments;

			JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject('User', 'Id, People_Lead__c');
			searchOptions.addFilter('People_Lead__c', userIds, 'AND', 'IN');
			searchOptions.addFilter('IsActive', true, 'AND', '=');

			List<User> people = (List<User>) searchOptions.getResults();

			for (User user : people) {
				peopleLeads.add((String) user.People_Lead__c);
			}

			Map<String, List<PermissionSetAssignment>> assignmentsMap = new Map<String, List<PermissionSetAssignment>>();

			JCQueryHelper.QueryObject assignmentOptions = JCQueryHelper.createQueryObject(
				'PermissionSetAssignment',
				'Id, AssigneeId'
			);
			assignmentOptions.addFilter('PermissionSetId', permissionSetId, 'AND', '=');
			assignmentOptions.addFilter('AssigneeId', new List<String>(peopleLeads), 'AND', 'IN');

			System.debug('peopleLeads === ' + assignmentOptions.queryString());
			for (PermissionSetAssignment assignment : (List<PermissionSetAssignment>) assignmentOptions.getResults()) {
				if (assignmentsMap.containsKey(assignment.AssigneeId)) {
					assignmentsMap.get(assignment.AssigneeId).add(assignment);
				} else {
					assignmentsMap.put(assignment.AssigneeId, new List<PermissionSetAssignment>{ assignment });
				}
			}

			Set<PermissionSetAssignment> newAssignments = new Set<PermissionSetAssignment>();
			for (User person : people) {
				if (assignmentsMap.get(person.People_Lead__c) == null) {
					newAssignments.add(
						new PermissionSetAssignment(
							PermissionSetId = permissionSetId,
							AssigneeId = person.People_Lead__c
						)
					);
				}
			}

			insert new List<PermissionSetAssignment>(newAssignments);
		} catch (Exception e) {
			System.debug('JCPeopleLeadCleanup Exception: ' + e.getMessage());
		}
	}

	public void finish(Database.BatchableContext context) {
		CustomNotificationType notificationType = [
			SELECT Id, DeveloperName
			FROM CustomNotificationType
			WHERE DeveloperName = 'Feedback_Notification'
		];
		String adminConsole = '{ type: \'standard__app\', attributes: { appTarget: \'c__PA_Admin_Console\',}}';

		Messaging.CustomNotification notification = new Messaging.CustomNotification();
		notification.setTitle('People Lead Clean Up Successful');
		notification.setBody('The people lead clean up has completed.');
		notification.setNotificationTypeId(notificationType.Id);
		notification.setTargetPageRef(adminConsole);
		notification.send(new Set<String>{ UserInfo.getUserId() });
	}
}
