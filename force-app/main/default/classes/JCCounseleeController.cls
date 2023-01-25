public with sharing class JCCounseleeController {
	public class CounseleeResponse extends JCResponse {
		@AuraEnabled
		public List<CounseleeWrapper> results { get; set; }
		@AuraEnabled
		public Integer totalResults { get; set; }
		public CounseleeResponse() {
			super();
			results = new List<CounseleeWrapper>();
			totalResults = 0;
		}
	}
	public class CounseleeWrapper {
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String recordUrl { get; set; }
	}
	@AuraEnabled(cacheable=true)
	public static CounseleeResponse getCounselees(JCQueryHelper.QueryObject searchOptions) {
		CounseleeResponse response = new CounseleeResponse();
		try {
			for (User item : (List<User>) searchOptions.getResults()) {
				CounseleeWrapper wrapper = new CounseleeWrapper();
				wrapper.id = item.Id;
				wrapper.name = item.Name;
				wrapper.recordUrl = '/detail/' + item.Id;
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
