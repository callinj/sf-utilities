@isTest
public with sharing class JCUtilsTest {
	@isTest
	public static void getTypeTest() {
		String myString = 'StringToBlob';
		Blob myBlob = Blob.valueof(myString);
		Decimal testDemical = 5.1;
		Long testLong = 235235222;
		Datetime timeTest = Datetime.newInstance(1991, 12, 16);

		List<String> testList = new List<String>();
		JCUtils utils = new JCUtils();
		User testUser = new User();

		testList.add(mystring);

		System.assertEquals(JCUtils.getType(utils), 'Object', 'getTypeTest Object Test: failed');
		System.assertEquals(JCUtils.getType(myString), 'String', 'getTypeTest String Test: failed');
		System.assertEquals(JCUtils.getType(myBlob), 'Blob', 'getTypeTest Blob Test: failed');
		System.assertEquals(JCUtils.getType(15), 'Integer', 'getTypeTest Integer Test: failed');
		System.assertEquals(JCUtils.getType(UserInfo.getUserId()), 'Id', 'getTypeTest Id Test: failed');
		System.assertEquals(JCUtils.getType(true), 'Boolean', 'getTypeTest Boolean Test: failed');
		System.assertEquals(JCUtils.getType(testUser), 'User', 'getTypeTest User Test: failed');
		System.assertEquals(JCUtils.getType(testDemical), 'Decimal', 'getTypeTest Decimal Test: failed');
		System.assertEquals(JCUtils.getType(testLong), 'Long', 'getTypeTest Long Test: failed');
		System.assertEquals(JCUtils.getType(testList), 'List', 'getTypeTest List Test: failed');
		System.assertEquals(JCUtils.getType(timeTest.date()), 'Date', 'getTypeTest Date Test: failed');
		System.assertEquals(JCUtils.getType(timeTest), 'Datetime', 'getTypeTest Datetime Test: failed');
		System.assertEquals(JCUtils.getType(timeTest.time()), 'Time', 'getTypeTest Time Test: failed');
	}

	@isTest
	public static void stripQuotesTest() {
		System.assertEquals(JCUtils.stripQuotes('\'Hello\''), 'Hello', 'stripQuotesTest StripSingleQuote Test: failed');
		System.assertEquals(
			JCUtils.stripQuotes('\"Hello\"'),
			'Hello',
			'stripQuotesTest StringDoubleQuote Test: failed'
		);
	}
	@isTest
	public static void addQuotesTest() {
		System.assertEquals('\'Hello\'', JCUtils.addQuotes('Hello'), 'JCUtilsTest.addQuotesTest Test: failed');
	}
	@isTest
	public static void shareRecordTest() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

		// Create 1 Test User
		User user = new User();
		user.ProfileId = profileId;
		user.FirstName = 'Test';
		user.LastName = 'User';
		user.Email = 'test.user@accenturefederal.com';
		user.Username = 'test.user@accenturefederal.com.apextestclass';
		user.Alias = 'tuser';
		user.TimeZoneSidKey = 'America/Los_Angeles';
		user.LocaleSidKey = 'en_US';
		user.EmailEncodingKey = 'UTF-8';
		user.LanguageLocaleKey = 'en_US';
		insert user;

		User user2 = new User();
		user2.ProfileId = profileId;
		user2.FirstName = 'Test';
		user2.LastName = 'User2';
		user2.Email = 'test.user2@accenturefederal.com';
		user2.Username = 'test.user2@accenturefederal.com.apextestclass';
		user2.Alias = 'tuser2';
		user2.TimeZoneSidKey = 'America/Los_Angeles';
		user2.LocaleSidKey = 'en_US';
		user2.EmailEncodingKey = 'UTF-8';
		user2.LanguageLocaleKey = 'en_US';
		insert user2;

		Feedback__c feedbackItem1 = new Feedback__c();
		feedbackItem1.RecordTypeId = getRecordTypeId('Feedback');
		feedbackItem1.Provider__c = UserInfo.getUserId();
		feedbackItem1.Receiver__c = user.Id;
		insert feedbackItem1;

		Test.startTest();
		JCUtils.shareRecord(feedbackItem1.Id, user2.Id);
		List<Feedback__Share> sharedList = [
			SELECT Id, ParentId, UserOrGroupId, RowCause
			FROM Feedback__Share
			WHERE ParentId = :feedbackItem1.Id AND UserOrGroupId = :user2.Id
		];
		System.assertEquals('Manual', sharedList[0].RowCause, 'shareRecordTest RowCause Test: failed');
		Test.stopTest();
	}
	public static String getRecordTypeId(String recordType) {
		return [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Feedback__c' AND DeveloperName = :recordType
		]
		.Id;
	}
	@isTest
	public static void convertToStringListTest() {
		String testString = 'testString';
		List<String> listTest = new List<String>{ testString };
		List<String> stringResponse = JCUtils.convertToStringList(testString);
		List<String> listResponse = JCUtils.convertToStringList(listTest);
		System.assertEquals(listTest, stringResponse, 'JCUtilsTest.convertToStringListTest Assert Fail: String');
		System.assertEquals(listTest, listResponse, 'JCUtilsTest.convertToStringListTest Assert Fail: List');
		try {
			List<String> exceptionResponse = JCUtils.convertToStringList(3);
		} catch (JCUtils.TypeException ex) {
			System.assertEquals(
				'There was an error while processing your request. recordIds must be of type List<String>, String or Id.',
				ex.getMessage(),
				'JCUtilsTest.convertToStringListTest Assert Fail: Exception'
			);
		}
	}
}
