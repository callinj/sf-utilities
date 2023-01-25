public with sharing class JCRosterTriggerHandler extends JCTriggerHandler {
	public override void afterUpdate() {
		String recordTypeId = [
			SELECT Id
			FROM RecordType
			WHERE SObjectType = 'Roster__c' AND DeveloperName = 'Talent_Decision'
		]
		.Id;
		String actionType;
		List<Roster__c> qualifiedRosters = new List<Roster__c>();

		if (Trigger.new != null) {
			for (Roster__c roster : (List<Roster__c>) Trigger.new) {
				if (
					roster.RecordTypeId == recordTypeId &&
					roster.IsReleased__c != Trigger.oldMap.get(roster.Id).get('isReleased__c')
				) {
					actionType = roster.isReleased__c == true ? 'Release' : 'Rollback';
					qualifiedRosters.add(roster);
				}
			}

			if (qualifiedRosters.size() > 0) {
				List<String> rosterIds = new List<String>();
				for (Roster__c roster : qualifiedRosters) {
					rosterIds.add((String) roster.id);
				}

				JCTalentDecisionUpdateBatch talentDecisionBatch = new JCTalentDecisionUpdateBatch(
					rosterIds,
					actionType
				);
				Database.executeBatch(talentDecisionBatch, 2000);
			}
		}
	}
}
