@isTest
public with sharing class JCRecordUtilsTest {
	@testSetup
	static void setup() {
		//Add test setup data here
		Account testAccount = new Account(Name = 'ApexTestName');
		insert testAccount;
	}
	@isTest
	public static void recordInfoTest() {
		JCRecordUtils.RecordInfo testInfo = new JCRecordUtils.RecordInfo();
		Map<String, JCRecordUtils.FieldDetails> fieldsMap = new Map<String, JCRecordUtils.FieldDetails>();
		JCRecordUtils.FieldDetails fieldDetail = new JCRecordUtils.FieldDetails('Apex Test');
		fieldsMap.put('Name', fieldDetail);
		testInfo.fields = fieldsMap;
		Test.startTest();
		System.assertEquals(testInfo.success, true, 'RecordInfoTest success Test: failed');
		System.assertEquals(testInfo.fields.get('Name').value, 'Apex Test', 'RecordInfoTest name Test: failed');
		Test.stopTest();
	}
	@isTest
	public static void fieldDetailsTest() {
		String testValue = 'Apex Test Value';
		String testLabel = 'Apex Test Label';
		String testRelationship = 'Owner.Name';
		JCRecordUtils.FieldDetails defaultDetail = new JCRecordUtils.FieldDetails();
		JCRecordUtils.FieldDetails valueDetail = new JCRecordUtils.FieldDetails(testValue);
		JCRecordUtils.FieldDetails labelDetail = new JCRecordUtils.FieldDetails(testValue, testLabel);
		JCRecordUtils.FieldDetails relationshipDetail = new JCRecordUtils.FieldDetails(
			testValue,
			testLabel,
			testRelationship
		);
		Test.startTest();

		// Default details asserts
		System.assertEquals(
			null,
			defaultDetail.value,
			'JCRecordUtilsTest.fieldDetailsTest Assert Fail: defaultDetail value'
		);

		// Value details asserts
		System.assertEquals(
			testValue,
			valueDetail.value,
			'JCRecordUtilsTest.fieldDetailsTest Assert Fail: valueDetail value'
		);

		// Label details asserts
		System.assertEquals(
			testValue,
			labelDetail.value,
			'JCRecordUtilsTest.fieldDetailsTest Assert Fail: labelDetail value'
		);
		System.assertEquals(
			testLabel,
			labelDetail.label,
			'JCRecordUtilsTest.fieldDetailsTest Assert Fail: valueDetail label'
		);

		// Relationship details asserts
		System.assertEquals(
			testValue,
			relationshipDetail.value,
			'JCRecordUtilsTest.fieldDetailsTest Assert Fail: labelDetail value'
		);
		System.assertEquals(
			testLabel,
			relationshipDetail.label,
			'JCRecordUtilsTest.fieldDetailsTest Assert Fail: valueDetail label'
		);
		System.assertEquals(
			testRelationship,
			relationshipDetail.fieldRelationship,
			'JCRecordUtilsTest.fieldDetailsTest Assert Fail: valueDetail label'
		);

		Test.stopTest();
	}
	@isTest
	public static void getRecordInfoTest() {
		Account testAccount = [SELECT Id, Name, Owner.Name FROM Account WHERE Name = 'ApexTestName' LIMIT 1];

		JCQueryHelper.QueryObject objectData = JCQueryHelper.createQueryObject(
			null,
			new List<String>{ 'Name', 'Owner.Name', 'ApexTestField' }
		);
		objectData.addFilter('Id', testAccount.Id);

		JCRecordUtils.RecordInfo testResults = JCRecordUtils.getRecordInfo(objectData, testAccount.Id);
		Test.startTest();

		System.assertEquals(
			testResults.fields.get('Name').value,
			testAccount.Name,
			'getRecordInfoTest name Test: failed'
		);
		System.assertEquals(
			testResults.fields.get('Owner.Name').value,
			testAccount.Owner.Name,
			'getRecordInfoTest owner name Test: failed'
		);
		System.assertEquals(
			testResults.fields.get('ApexTestField').isValid,
			false,
			'getRecordInfoTest invalid Test: failed'
		);
		Test.stopTest();
	}
	@isTest
	public static void getFieldValueTest() {
		Account testAccount = [SELECT Id, Name, Industry, Owner.Name FROM Account WHERE Name = 'ApexTestName' LIMIT 1];
		Test.startTest();
		Object resultName = JCRecordUtils.getFieldValue(testAccount, 'Name');
		Object resultOwnerName = JCRecordUtils.getFieldValue(testAccount, 'Owner.Name');
		Object resultNull = JCRecordUtils.getFieldValue(testAccount, 'Industry');

		System.assertEquals(resultName, testAccount.Name, 'getFieldValueTest name Test: failed');
		System.assertEquals(resultOwnerName, testAccount.Owner.Name, 'getFieldValueTest owner name Test: failed');
		System.assertEquals(resultNull, null, 'getFieldValueTest null Test: failed');
		Test.stopTest();
	}
}
