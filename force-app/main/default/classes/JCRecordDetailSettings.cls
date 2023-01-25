public with sharing class JCRecordDetailSettings extends VisualEditor.DynamicPickList {
	public override VisualEditor.DataRow getDefaultValue() {
		// set the default value of the picklist
		return new VisualEditor.DataRow('None', 'None');
	}

	public override VisualEditor.DynamicPickListRows getValues() {
		// create picklist
		VisualEditor.DynamicPickListRows settings = new VisualEditor.DynamicPickListRows();

		// add the default picklist value
		settings.addRow(new VisualEditor.DataRow('None', 'None'));

		try {
			// populate picklist
			for (JCRecordDetailSetting__mdt setting : [SELECT Id, MasterLabel FROM JCRecordDetailSetting__mdt]) {
				settings.addRow(new VisualEditor.DataRow(setting.MasterLabel, (String) setting.Id));
			}
		} catch (Exception e) {
			System.debug('Error returning Record Detail Settings');
		}

		return settings;
	}
	@AuraEnabled(cacheable=true)
	public static String getRecordSetting(String settingName) {
		String settingId;
		try {
			List<JCRecordDetailSetting__mdt> recordList = new List<JCRecordDetailSetting__mdt>();
			Set<JCRecordDetailSetting__mdt> recordSet = new Set<JCRecordDetailSetting__mdt>(
				[SELECT Id FROM JCRecordDetailSetting__mdt WHERE DeveloperName = :settingName LIMIT 1]
			);
			recordSet.addAll([SELECT Id FROM JCRecordDetailSetting__mdt WHERE MasterLabel = :settingName LIMIT 1]);
			recordList.addAll(recordSet);
			if (recordList.size() > 0) {
				settingId = recordList[0].Id;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return settingId;
	}
}
