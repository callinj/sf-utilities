public with sharing class JCRosterController {
	public class RosterResponse extends JCResponse {
		@AuraEnabled
		public List<RosterWrapper> results { get; set; }
		@AuraEnabled
		public Integer totalResults { get; set; }
		public RosterResponse() {
			super();
			results = new List<RosterWrapper>();
			totalResults = 0;
		}
	}
	public class RosterWrapper {
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String performancePeriod { get; set; }
		@AuraEnabled
		public Boolean isReleased { get; set; }
		@AuraEnabled
		public Boolean isPublic { get; set; }
	}
	@AuraEnabled(cacheable=true)
	public static RosterResponse getRosters(JCQueryHelper.QueryObject searchOptions) {
		RosterResponse response = new RosterResponse();
		try {
			for (Roster__c item : (List<Roster__c>) searchOptions.getResults()) {
				RosterWrapper wrapper = new RosterWrapper();
				wrapper.id = item.Id;
				wrapper.name = item?.Name;
				wrapper.performancePeriod = item?.Performance_Period__c;
				wrapper.isReleased = item?.isReleased__c;
				wrapper.isPublic = item?.isPublic__c;
				response.results.add(wrapper);
			}
			response.totalResults = searchOptions.getTotalResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
		}
		return response;
	}

	@AuraEnabled(cacheable=true)
	public static List<String> getUniquePerformancePeriods() {
		List<String> uniquePerformancePeriods = new List<String>();
		// TODO | Refactor QueryHelper to account for 'GROUP BY'
		List<AggregateResult> talentDecisions = [
			SELECT Performance_Period__c
			FROM Roster__c
			WHERE RecordType.DeveloperName = 'Talent_Decision'
			GROUP BY Performance_Period__c
		];

		for (AggregateResult value : talentDecisions) {
			uniquePerformancePeriods.add((String) value.get('Performance_Period__c'));
		}
		return uniquePerformancePeriods;
	}
}
