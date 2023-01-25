public with sharing class JCWrapper {
	// Record Wrapper - Everything extends this
	public virtual class Record {
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String name { get; set; }
		public Record(String recordId, String recordName) {
			id = recordId;
			name = recordName;
		}
		public Record(SObject recordObject) {
			id = (String) recordObject?.get('Id');
			name = (String) recordObject?.get('Name');
		}
		public Record(Map<String, Object> recordMap) {
			id = (String) recordMap?.get('Id');
			name = (String) recordMap?.get('Name');
		}
		public Record(String recordId) {
			id = recordId;
			name = null;
		}
		public Record() {
			id = null;
			name = null;
		}
	}

	public virtual class Person extends Record { // Id, Name, Email
		@AuraEnabled
		public String email { get; set; }
		public Person(String personId, String personName, String personEmail) {
			super();
			id = personId;
			name = personName;
			email = personEmail;
		}
		public Person(String personId, String personName) {
			super();
			id = personId;
			name = personName;
			email = null;
		}
		public Person(SObject personObject) {
			super();
			id = (String) personObject?.get('Id');
			name = (String) personObject?.get('Name');
			email = (String) personObject?.get('Email');
		}
		public Person(Map<String, Object> personMap) {
			super();
			id = (String) personMap?.get('Id');
			name = (String) personMap?.get('Name');
			email = (String) personMap?.get('Email');
		}
		public Person(String personId) {
			super();
			id = personId;
			email = null;
		}
		public Person() {
			super();
			email = null;
		}
	}
	// New Wrapper "Employee" extends Person - Adds enterpriseId, personelId, etc
	public virtual class Employee extends Person { // Id, Name, Email
		@AuraEnabled
		public String EID { get; set; }
		public String HRPartner { get; set; }
		public String personnelNbr { get; set; }
		public String firstName { get; set; }
		public String careerLevel { get; set; }
		public String isActive { get; set; }
		// public String Career_Level__c { get; set; }
		public String lastName { get; set; }
		public Employee(Map<String, Object> employeeMap) {
			super();
			EID = (String) employeeMap?.get('EID');
			HRPartner = (String) employeeMap?.get('HRPartner');
			personnelNbr = (String) employeeMap?.get('personnelNbr');
			firstName = (String) employeeMap?.get('firstName');
			careerLevel = (String) employeeMap?.get('careerLevel');
			isActive = (String) employeeMap?.get('isActive');
			// Career_Level__c = (String) employeeMap?.get('Career_Level__c');
			lastName = (String) employeeMap?.get('lastName');
		}
		public Employee() {
			super();
			email = null;
		}
	}
}
