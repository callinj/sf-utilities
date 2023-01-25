public class JCTalentDecisionTriggerHandler extends JCTriggerHandler {
	public override void beforeInsert() {
		JCQueryHelper.QueryObject queryObject = JCQueryHelper.createQueryObject('Group', 'Id', 1);
		queryObject.addFilter('DeveloperName', 'HR_Admins');
		List<SObject> queryResults = queryObject.getResults();
		Group adminQueue = (Group) queryResults[0];
		for (Talent_Decision__c currentDecision : (List<Talent_Decision__c>) Trigger.new) {
			if (currentDecision.OwnerId != adminQueue.Id) {
				currentDecision.OwnerId = adminQueue.Id;
			}
		}
	}
}
