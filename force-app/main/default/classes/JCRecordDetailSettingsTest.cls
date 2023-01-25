@isTest
public with sharing class JCRecordDetailSettingsTest {
	@isTest
	public static void getDefaultValueTest() {
		JCRecordDetailSettings settingsClass = new JCRecordDetailSettings();
		VisualEditor.DataRow expectedResult = new VisualEditor.DataRow('None', 'None');
		Test.startTest();
		VisualEditor.DataRow row = settingsClass.getDefaultValue();
		Test.stopTest();
		System.assertEquals(expectedResult.getLabel(), row.getLabel(), 'getDefaultValueTest get label assert fail');
		System.assertEquals(expectedResult.getValue(), row.getValue(), 'getDefaultValueTest get value assert fail');
	}
	@isTest
	public static void getValuesTest() {
		JCRecordDetailSettings settingsClass = new JCRecordDetailSettings();
		VisualEditor.DynamicPickListRows expectedSettings = new VisualEditor.DynamicPickListRows();
		expectedSettings.addRow(new VisualEditor.DataRow('None', 'None'));
		for (JCRecordDetailSetting__mdt setting : [SELECT Id, MasterLabel FROM JCRecordDetailSetting__mdt]) {
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
	public static void getRecordSettingMasterLabelTest() {
		List<JCRecordDetailSetting__mdt> testSettings = [SELECT Id, MasterLabel FROM JCRecordDetailSetting__mdt];
		String label = testSettings.size() != 0 ? testSettings[0].MasterLabel : null;
		List<JCRecordDetailSetting__mdt> expectedSettings = new List<JCRecordDetailSetting__mdt>();
		if (label != null) {
			expectedSettings = [
				SELECT Id, Section_Title__c
				FROM JCRecordDetailSetting__mdt
				WHERE MasterLabel = :label
				ORDER BY Section_Title__c
			];
		}
		Test.startTest();
		String recievedSetting = JCRecordDetailSettings.getRecordSetting(label);
		Test.stopTest();
		if (expectedSettings.size() == 0) {
			System.assertEquals(null, recievedSetting, 'getRecordSettingMasterLabelTest recieved value should be null');
		} else {
			System.assertEquals(
				expectedSettings[expectedSettings.size() - 1].Id,
				recievedSetting,
				'getRecordSettingMasterLabelTest checking last item assert fail'
			);
		}
	}
	@isTest
	public static void getRecordSettingDeveloperNameTest() {
		List<JCRecordDetailSetting__mdt> testSettings = [SELECT Id, DeveloperName FROM JCRecordDetailSetting__mdt];
		String name = testSettings.size() != 0 ? testSettings[0].DeveloperName : null;
		List<JCRecordDetailSetting__mdt> expectedSettings = new List<JCRecordDetailSetting__mdt>();
		if (name != null) {
			expectedSettings = [
				SELECT Id, Section_Title__c
				FROM JCRecordDetailSetting__mdt
				WHERE DeveloperName = :name
				ORDER BY Section_Title__c
			];
		}
		Test.startTest();
		String recievedSetting = JCRecordDetailSettings.getRecordSetting(name);
		if (expectedSettings.size() == 0) {
			System.assertEquals(
				null,
				recievedSetting,
				'getRecordSettingDeveloperNameTest recieved value should be null'
			);
		} else {
			System.assertEquals(
				expectedSettings[expectedSettings.size() - 1].Id,
				recievedSetting,
				'getRecordSettingDeveloperNameTest checking last item assert fail'
			);
		}
	}
}
