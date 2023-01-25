@isTest
public with sharing class JCRelatedTabsControllerTest {
	@isTest
	public static void getDefaultValueTest() {
		JCRelatedTabsController settingsClass = new JCRelatedTabsController();
		VisualEditor.DataRow expectedResult = new VisualEditor.DataRow('None', 'None');
		Test.startTest();
		VisualEditor.DataRow row = settingsClass.getDefaultValue();
		Test.stopTest();
		System.assertEquals(expectedResult.getLabel(), row.getLabel(), 'getDefaultValueTest get label assert fail');
		System.assertEquals(expectedResult.getValue(), row.getValue(), 'getDefaultValueTest get value assert fail');
	}
	@isTest
	public static void getValuesTest() {
		JCRelatedTabsController settingsClass = new JCRelatedTabsController();
		VisualEditor.DynamicPickListRows expectedSettings = new VisualEditor.DynamicPickListRows();
		expectedSettings.addRow(new VisualEditor.DataRow('None', 'None'));
		for (
			JCRelatedTabsSetting__mdt setting : Database.query('SELECT Id, MasterLabel FROM JCRelatedTabsSetting__mdt')
		) {
			expectedSettings.addRow(new VisualEditor.DataRow(setting.MasterLabel, (String) setting.Id));
		}
		Test.startTest();
		VisualEditor.DynamicPickListRows recievedSettings = settingsClass.getValues();
		Test.stopTest();
		System.assertEquals(expectedSettings.size(), recievedSettings.size(), 'getValuesTest size assert fail');
		System.assertEquals(
			expectedSettings.get(expectedSettings.size() - 1).getValue(),
			recievedSettings.get(recievedSettings.size() - 1).getValue(),
			'getValuesTest checking last item assert fail'
		);
	}
	@isTest
	public static void getTabSettingMasterLabelTest() {
		List<JCRecordDetailSetting__mdt> testSettings = [
			SELECT Id, Related_Tabs_Setting__r.MasterLabel
			FROM JCRecordDetailSetting__mdt
		];
		String label = testSettings.size() != 0 ? testSettings[0].Related_Tabs_Setting__r.MasterLabel : null;
		List<JCRecordDetailSetting__mdt> expectedSettings = new List<JCRecordDetailSetting__mdt>();
		if (label != null) {
			expectedSettings = [
				SELECT Id, Order__c, Section_Title__c
				FROM JCRecordDetailSetting__mdt
				WHERE Related_Tabs_Setting__r.MasterLabel = :label
				ORDER BY Order__c NULLS LAST, Section_Title__c
			];
		}
		Test.startTest();
		List<JCRecordDetailSetting__mdt> receivedSettings = JCRelatedTabsController.getTabSetting(label);
		Test.stopTest();
		system.debug('**** the expectedSetting size is ' + expectedSettings.size());
		system.debug('**** the receivedSetting size is ' + receivedSettings.size());
		System.assertEquals(
			expectedSettings.size(),
			receivedSettings.size(),
			'getTabSettingMasterLabelTest size assert fail'
		);
		if (expectedSettings.size() > 0) {
			System.assertEquals(
				expectedSettings[expectedSettings.size() - 1].Id,
				receivedSettings[receivedSettings.size() - 1].Id,
				'getTabSettingMasterLabelTest checking last item assert fail'
			);
		}
	}
	@isTest
	public static void getTabSettingDeveloperNameTest() {
		List<JCRecordDetailSetting__mdt> testSettings = [
			SELECT Id, Related_Tabs_Setting__r.DeveloperName
			FROM JCRecordDetailSetting__mdt
		];
		String name = testSettings.size() != 0 ? testSettings[0].Related_Tabs_Setting__r.DeveloperName : null;
		List<JCRecordDetailSetting__mdt> expectedSettings = new List<JCRecordDetailSetting__mdt>();
		if (name != null) {
			expectedSettings = [
				SELECT Id, Order__c, Section_Title__c
				FROM JCRecordDetailSetting__mdt
				WHERE Related_Tabs_Setting__r.DeveloperName = :name
				ORDER BY Order__c NULLS LAST, Section_Title__c
			];
		}
		Test.startTest();
		List<JCRecordDetailSetting__mdt> receivedSettings = JCRelatedTabsController.getTabSetting(name);
		Test.stopTest();
		System.assertEquals(
			expectedSettings.size(),
			receivedSettings.size(),
			'getTabSettingDeveloperNameTest size assert fail'
		);
		if (expectedSettings.size() > 0) {
			System.assertEquals(
				expectedSettings[expectedSettings.size() - 1].Id,
				receivedSettings[receivedSettings.size() - 1].Id,
				'getTabSettingDeveloperNameTest checking last item assert fail'
			);
		}
	}
	@isTest
	public static void getTabSettingIdTest() {
		List<JCRelatedTabsSetting__mdt> testSettings = [SELECT Id, MasterLabel FROM JCRelatedTabsSetting__mdt];
		String label = testSettings.size() != 0 ? testSettings[0].MasterLabel : null;
		String expectedId;
		if (label != null) {
			expectedId = [SELECT Id, MasterLabel FROM JCRelatedTabsSetting__mdt WHERE MasterLabel = :label LIMIT 1].Id;
		}
		Test.startTest();
		String receivedId = JCRelatedTabsController.getTabSettingId(label);
		Test.stopTest();
		System.assertEquals(expectedId, receivedId, 'getTabSettingIdTest size assert fail');
	}
	@isTest
	public static void getListItemsTest() {
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;
		List<Contact> testContacts = new List<Contact>();
		do {
			testContacts.add(
				new Contact(FirstName = 'Test', LastName = 'Name' + testContacts.size(), AccountId = testAccount.Id)
			);
		} while (testContacts.size() < 2);
		JCRelatedTabsController.QueryDetails details = new JCRelatedTabsController.QueryDetails();
		insert testContacts;
		details.recordId = testAccount.Id;
		details.relatedObject = 'Contact';
		details.referenceField = 'AccountId';
		details.fieldsString = 'Name';
		details.filterField = 'FirstName';
		details.selectedFilter = 'Test';
		details.orderField = 'LastName';

		Test.startTest();
		List<SObject> items = JCRelatedTabsController.getListItems(details);
		Test.stopTest();
		Contact firstItem = (Contact) items[0];
		System.assertEquals(2, items.size(), 'getListItemsTest size assert fail');
		System.assertEquals(
			(testContacts[0].FirstName + ' ' + testContacts[0].LastName),
			firstItem.Name,
			'getListItemsTest checking first item assert fail'
		);
	}
}
