public with sharing class JCRelatedTabsController extends VisualEditor.DynamicPickList {
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
			for (
				JCRelatedTabsSetting__mdt setting : Database.query(
					'SELECT Id, MasterLabel FROM JCRelatedTabsSetting__mdt'
				)
			) {
				settings.addRow(new VisualEditor.DataRow(setting.MasterLabel, (String) setting.Id));
			}
		} catch (Exception e) {
			System.debug('Error returning Tab Detail Settings');
		}

		return settings;
	}

	@AuraEnabled(cacheable=true)
	public static String getTabSettingId(String settingName) {
		String tabSettingId;
		try {
			List<JCRelatedTabsSetting__mdt> recordList = new List<JCRelatedTabsSetting__mdt>();
			Set<JCRelatedTabsSetting__mdt> recordSet = new Set<JCRelatedTabsSetting__mdt>(
				[SELECT Id FROM JCRelatedTabsSetting__mdt WHERE DeveloperName = :settingName LIMIT 1]
			);
			recordSet.addAll([SELECT Id FROM JCRelatedTabsSetting__mdt WHERE MasterLabel = :settingName LIMIT 1]);
			recordList.addAll(recordSet);
			if (recordList.size() > 0) {
				tabSettingId = recordList[0].Id;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return tabSettingId;
	}
	@AuraEnabled(cacheable=true)
	public static List<JCRecordDetailSetting__mdt> getTabSetting(String tabSetting) {
		List<JCRecordDetailSetting__mdt> recordDetailSettings = new List<JCRecordDetailSetting__mdt>();
		try {
			Set<JCRecordDetailSetting__mdt> recordSet = new Set<JCRecordDetailSetting__mdt>(
				[
					SELECT Id, Order__c, Fields__c, Section_Title__c
					FROM JCRecordDetailSetting__mdt
					WHERE Related_Tabs_Setting__r.MasterLabel = :tabSetting
					ORDER BY Order__c NULLS LAST, Section_Title__c
				]
			);
			if (recordSet.isEmpty()) {
				recordSet.addAll(
					[
						SELECT Id, Order__c, Fields__c, Section_Title__c
						FROM JCRecordDetailSetting__mdt
						WHERE Related_Tabs_Setting__r.DeveloperName = :tabSetting
						ORDER BY Order__c NULLS LAST, Section_Title__c
					]
				);
			}
			recordDetailSettings.addAll(recordSet);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return recordDetailSettings;
	}
	@AuraEnabled(cacheable=true)
	public static List<SObject> getListItems(QueryDetails queryParams) {
		String fieldQuery = 'Id';
		if (queryParams.fieldsString != null) {
			fieldQuery += ',' + queryParams.fieldsString;
		}
		String query = 'SELECT ' + fieldQuery + ' FROM ' + queryParams.relatedObject;
		query +=
			' WHERE ' +
			queryParams.referenceField +
			'=' +
			'\'' +
			String.escapeSingleQuotes(queryParams.recordId) +
			'\'';
		if (queryParams.selectedFilter != null) {
			query +=
				' AND ' +
				queryParams.filterField +
				'=' +
				'\'' +
				String.escapeSingleQuotes(queryParams.selectedFilter) +
				'\'';
		}
		if (queryParams.recordType != null) {
			query += ' AND RecordType.DeveloperName = \'' + String.escapeSingleQuotes(queryParams.recordType) + '\'';
		}
		if (queryParams.orderField != null) {
			query += ' ORDER BY ' + queryParams.orderField;
		}
		//Schema.SObjectType objectType = Id.valueOf(queryParams.recordId).getSobjectType();
		System.debug('query = ' + query);
		List<sObject> sobjList = Database.query(query);
		return sobjList;
	}
	public class QueryDetails {
		@AuraEnabled
		public String recordId { get; set; }
		@AuraEnabled
		public String relatedObject { get; set; }
		@AuraEnabled
		public String referenceField { get; set; }
		@AuraEnabled
		public String fieldsString { get; set; }
		@AuraEnabled
		public String filterField { get; set; }
		@AuraEnabled
		public String selectedFilter { get; set; }
		@AuraEnabled
		public String orderField { get; set; }
		@AuraEnabled
		public String recordType { get; set; }
	}
}
