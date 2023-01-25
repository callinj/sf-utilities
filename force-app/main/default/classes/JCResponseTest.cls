@isTest
public with sharing class JCResponseTest {
	@isTest
	public static void JCResponseWrapperTest() {
		JCResponse test = new JCResponse();
		System.assertEquals(test.results.size(), 0);
		System.assertEquals(test.success, true);
		System.assertEquals(test.messages.size(), 0);
	}

	@isTest
	public static void JCResponseWrapperTestFalse() {
		JCResponse test = new JCResponse();

		test.success = false;
		test.messages.add('Testing');
		test.results = new List<SObject>();

		System.assertEquals(test.success, false);
		System.assertEquals(test.messages.size(), 1);
		System.assertEquals(test.messages[0], 'Testing');
		System.assertNotEquals(test.results, null);
	}
}
