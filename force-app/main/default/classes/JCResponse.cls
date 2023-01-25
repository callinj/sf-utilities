public virtual with sharing class JCResponse {
	// TODO Migrate over to JCWrapper
	@AuraEnabled
	public Boolean success { get; set; }
	@AuraEnabled
	public List<SObject> results { get; set; }
	@AuraEnabled
	public List<String> messages { get; set; }
	public JCResponse() {
		success = true;
		messages = new List<String>();
		results = new List<SObject>();
	}
}
