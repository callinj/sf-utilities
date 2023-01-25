public with sharing class JCPeopleLeadPermissionsRemove implements Database.Batchable<SObject> {
	List<String> peopleLeadIdList;
	public JCPeopleLeadPermissionsRemove(List<String> peopleLeadsToProcess) {
		if (peopleLeadsToProcess == null) {
			peopleLeadsToProcess = new List<String>();
		}
		this.peopleLeadIdList = peopleLeadsToProcess;
	}
	public Database.QueryLocator start(Database.BatchableContext context) {
		Set<String> tempPLSet = new Set<String>(peopleLeadIdList);
		for (AggregateResult peopleLeadGroupResult : [
			SELECT count(Id), People_Lead__c
			FROM User
			WHERE People_Lead__c IN :this.peopleLeadIdList
			GROUP BY People_Lead__c
		]) {
			Boolean oldRemoved = tempPLSet.remove((String) peopleLeadGroupResult.get('People_Lead__c'));
		}
		this.peopleLeadIdList = new List<String>(tempPLSet);
		JCQueryHelper.QueryObject assignmentQueryObject = JCPeopleLeadUtils.getPLAssignmentsObject(
			this.peopleLeadIdList
		);
		if (Test.isRunningTest()) {
			assignmentQueryObject.queryLimit = 200;
		}
		return assignmentQueryObject.getQueryLocator();
	}
	public void execute(Database.BatchableContext context, List<PermissionSetAssignment> records) {
		delete records;
	}
	public void finish(Database.BatchableContext context) {
	}
}
