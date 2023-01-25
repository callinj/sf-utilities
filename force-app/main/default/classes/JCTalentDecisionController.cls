public with sharing class JCTalentDecisionController {
	public class TalentDecisionResponse extends JCResponse {
		@AuraEnabled
		public List<TalentDecisionWrapper> results { get; set; }
		@AuraEnabled
		public Integer totalResults { get; set; }
		public TalentDecisionResponse() {
			super();
			results = new List<TalentDecisionWrapper>();
			totalResults = 0;
		}
	}
	public class TalentDecisionWrapper {
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String period { get; set; }
		@AuraEnabled
		public String decision { get; set; }
		@AuraEnabled
		public String recordUrl { get; set; }
		@AuraEnabled
		public Date effectiveDate { get; set; }
	}
	@AuraEnabled(cacheable=true)
	public static TalentDecisionResponse getTalentDecisions(JCQueryHelper.QueryObject searchOptions) {
		TalentDecisionResponse response = new TalentDecisionResponse();
		try {
			for (Talent_Decision__c item : (List<Talent_Decision__c>) searchOptions.getResults()) {
				TalentDecisionWrapper wrapper = new TalentDecisionWrapper();
				wrapper.id = item.Id;
				wrapper.period = item?.Performance_Period__c;
				wrapper.decision = item?.Decision__c;
				wrapper.recordUrl = '/detail/' + item.Id;
				wrapper.effectiveDate = item?.Effective_Date__c;
				response.results.add(wrapper);
			}
			response.totalResults = searchOptions.getTotalResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
		}
		return response;
	}
}
