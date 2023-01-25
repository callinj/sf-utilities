/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class JCWrapperTest {
	@isTest
	static void personContructorTest() {
		Test.startTest();
		JCWrapper.Person testPerson = new JCWrapper.Person();
		System.assertEquals(null, testPerson.id, 'JCWrapperTest.personContructorTest Assert Fail: testPerson.id');
		System.assertEquals(null, testPerson.name, 'JCWrapperTest.personContructorTest Assert Fail: testPerson.name');
		Test.stopTest();
	}
	@isTest
	static void personIdTest() {
		Test.startTest();
		JCWrapper.Person testPerson = new JCWrapper.Person(UserInfo.getUserId());
		System.assertEquals(
			UserInfo.getUserId(),
			testPerson.id,
			'JCWrapperTest.personIdTest Assert Fail: testPerson.id'
		);
		System.assertEquals(null, testPerson.name, 'JCWrapperTest.personIdTest Assert Fail: testPerson.name');
		Test.stopTest();
	}
	@isTest
	static void personIdNameTest() {
		Test.startTest();
		JCWrapper.Person testPerson = new JCWrapper.Person(UserInfo.getUserId(), UserInfo.getName());
		System.assertEquals(
			UserInfo.getUserId(),
			testPerson.id,
			'JCWrapperTest.personIdNameTest Assert Fail: testPerson.id'
		);
		System.assertEquals(
			UserInfo.getName(),
			testPerson.name,
			'JCWrapperTest.personIdNameTest Assert Fail: testPerson.name'
		);
		Test.stopTest();
	}
	@isTest
	static void personMapTest() {
		Map<String, Object> testMap = new Map<String, Object>();
		testMap.put('Id', UserInfo.getUserId());
		testMap.put('Name', UserInfo.getName());

		Test.startTest();
		JCWrapper.Person testPerson = new JCWrapper.Person(testMap);
		System.assertEquals(
			(String) testMap.get('Id'),
			testPerson.id,
			'JCWrapperTest.personMapTest Assert Fail: testPerson.id'
		);
		System.assertEquals(
			(String) testMap.get('Name'),
			testPerson.name,
			'JCWrapperTest.personMapTest Assert Fail: testPerson.name'
		);
		Test.stopTest();
	}
	@isTest
	static void personSObjectTest() {
		User testUser = [SELECT Id, Name, Email FROM user WHERE Id = :UserInfo.getUserId() LIMIT 1];
		Test.startTest();
		JCWrapper.Person testPerson = new JCWrapper.Person(testUser);
		System.assertEquals(
			(String) testUser.Id,
			testPerson.id,
			'JCWrapperTest.personSObjectTest Assert Fail: testPerson.id'
		);
		System.assertEquals(
			testUser.Name,
			testPerson.name,
			'JCWrapperTest.personSObjectTest Assert Fail: testPerson.name'
		);
		Test.stopTest();
	}
}
