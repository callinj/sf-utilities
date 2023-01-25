public with sharing class JCPeopleLeadPermissionsAdd implements Database.Batchable<SObject> {
	Set<Id> peopleLeadIdList;
	public JCPeopleLeadPermissionsAdd(Set<Id> peopleLeadsToProcess) {
		if (peopleLeadsToProcess == null) {
			peopleLeadsToProcess = new Set<Id>();
		}
		this.peopleLeadIdList = peopleLeadsToProcess;
	}
	public List<PermissionSetAssignment> start(Database.BatchableContext context) {
		List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
		Set<String> assigneeIds = new Set<String>();
		PermissionSet peopleLeadPemissionSet = (PermissionSet) JCPeopleLeadUtils.getPLPermissionSetObject()
			.getResults()[0];
		List<Id> holderList = new List<Id>(this.peopleLeadIdList);
		System.debug('assignmentQueryObject ==  ' + assignmentQueryObject.queryString());
		JCQueryHelper.QueryObject assignmentQueryObject = JCPeopleLeadUtils.getPLAssignmentsObject(holderList);
		for (
			PermissionSetAssignment currentAssignment : (List<PermissionSetAssignment>) assignmentQueryObject.getResults()
		) {
			assigneeIds.add(currentAssignment.AssigneeId);
		}
		System.debug('assigneeIds ==  ' + assigneeIds);
		System.debug('this.peopleLeadIdList ==  ' + this.peopleLeadIdList);
		for (String peopleLeadId : this.peopleLeadIdList) {
			System.debug('peopleLeadId ==  ' + peopleLeadId);
			if (!assigneeIds.contains(peopleLeadId)) {
				assignmentsToInsert.add(
					new PermissionSetAssignment(
						PermissionSetId = peopleLeadPemissionSet.Id,
						AssigneeId = (Id) peopleLeadId
					)
				);
			}
		}
		System.debug('assignmentsToInsert === ' + assignmentsToInsert);
		return assignmentsToInsert;
	}
	public void execute(Database.BatchableContext context, List<PermissionSetAssignment> records) {
		System.debug('add records === ' + records);
		// insert records;
	}
	public void finish(Database.BatchableContext context) {
	}
}
