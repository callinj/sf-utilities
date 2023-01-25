public with sharing class JCUserTriggerHandler extends JCTriggerHandler {
	public class UserPeopleLeadWrapper {
		@AuraEnabled
		public String userId { get; set; }
		@AuraEnabled
		public String oldPeopleLeadId { get; set; }
		@AuraEnabled
		public String newPeopleLeadId { get; set; }
	}
	public override void beforeInsert() {
		UserHandler.onBeforeInsert(Trigger.new);
	}
	public override void beforeUpdate() {
		UserHandler.onBeforeUpdate((List<User>) Trigger.new, (Map<Id, User>) Trigger.oldMap);
	}
	public override void afterUpdate() {
		UserHandler.onAfterUpdate((List<User>) Trigger.new, (Map<Id, User>) Trigger.oldMap);
		Set<Id> newPeopleLeadSet = new Set<Id>();
		Set<String> oldPeopleLeadSet = new Set<String>();
		for (SObject currentNewUser : Trigger.new) {
			User currentOldUser = (User) Trigger.oldMap.get(currentNewUser.Id);
			if (JCUtils.fieldChanged(currentOldUser, currentNewUser, 'People_Lead__c')) {
				if (currentOldUser.People_Lead__c != null) {
					oldPeopleLeadSet.add(currentOldUser.People_Lead__c);
				}
				if (currentNewUser.get('People_Lead__c') != null) {
					newPeopleLeadSet.add((Id) currentNewUser.get('People_Lead__c'));
				}
			}
		}
		// Set<String> peopleLeads = new Set<String>(newPeopleLeadSet.clone());
		// peopleLeads.addAll(oldPeopleLeadSet.clone());
		// if (oldPeopleLeadSet.size() > 0) {
		// 	JCPeopleLeadPermissionsRemove removePermissionsBatch = new JCPeopleLeadPermissionsRemove(
		// 		new List<String>(oldPeopleLeadSet)
		// 	);
		// 	Database.executeBatch(removePermissionsBatch, 200);
		// }
		if (newPeopleLeadSet.size() > 0) {
			JCPeopleLeadPermissionsAdd addPermissionsBatch = new JCPeopleLeadPermissionsAdd(newPeopleLeadSet);
			Database.executeBatch(addPermissionsBatch, 200);
		}
		transferShareRecords();
	}
	public static void transferShareRecords() {
		// Checks to see if user has an updated people lead
		Map<String, UserPeopleLeadWrapper> uniqueUsersMap = new Map<String, UserPeopleLeadWrapper>();
		String field = 'People_Lead__c';
		for (User currentNewUser : (List<User>) Trigger.new) {
			User currentOldUser = (User) Trigger.oldMap.get(currentNewUser.Id);
			if (JCUtils.fieldChanged(currentOldUser, currentNewUser, field) == true) {
				UserPeopleLeadWrapper wrapper = new UserPeopleLeadWrapper();
				wrapper.userId = currentNewUser.Id;
				wrapper.oldPeopleLeadId = (String) currentOldUser.get(field);
				wrapper.newPeopleLeadId = (String) currentNewUser.get(field);
				uniqueUsersMap.put(wrapper.userId, wrapper);
			}
		}
		// If users have an updated people lead, transfer share records
		if (uniqueUsersMap.size() > 0) {
			JCUpdateShareRecordsBatch updateShareRecordsBatch = new JCUpdateShareRecordsBatch(uniqueUsersMap);
			Database.executeBatch(updateShareRecordsBatch, 200);
		}
	}
}
