public with sharing class JCTest extends VisualEditor.DynamicPickList {
	public override VisualEditor.DataRow getDefaultValue() {
		return new VisualEditor.DataRow('None', 'None');
	}

	public override VisualEditor.DynamicPickListRows getValues() {
		VisualEditor.DynamicPickListRows settings = new VisualEditor.DynamicPickListRows();
		settings.addRow(new VisualEditor.DataRow('None', 'None'));

		JCQueryHelper.QueryObject searchOptions = JCQueryHelper.createQueryObject(
			'JC_Related_Tabs_Setting__mdt',
			'Id, MasterLabel'
		);

		try {
			for (
				JC_Related_Tabs_Setting__mdt setting : (List<JC_Related_Tabs_Setting__mdt>) searchOptions.getResults()
			) {
				settings.addRow(new VisualEditor.DataRow(setting.MasterLabel, (String) setting.Id));
			}
		} catch (Exception e) {
			System.debug('Error returning JCTest.getValues(): ' + e);
		}

		return settings;
	}

	@AuraEnabled(cacheable=true)
	public static List<JCRecordDetailSetting__mdt> getTabSetting(String tabSetting) {
		List<JCRecordDetailSetting__mdt> recordDetailSettings = new List<JCRecordDetailSetting__mdt>();
		try {
			Set<JCRecordDetailSetting__mdt> recordSet = new Set<JCRecordDetailSetting__mdt>(
				[
					SELECT Id, Order__c, Fields__c, Section_Title__c
					FROM JCRecordDetailSetting__mdt
					WHERE JC_Related_Tabs_Setting__r.MasterLabel = :tabSetting
					ORDER BY Order__c NULLS LAST, Section_Title__c
				]
			);
			if (recordSet.isEmpty()) {
				recordSet.addAll(
					[
						SELECT Id, Order__c, Fields__c, Section_Title__c
						FROM JCRecordDetailSetting__mdt
						WHERE JC_Related_Tabs_Setting__r.DeveloperName = :tabSetting
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
	public static JCQueryHelper.QueryObject createQueryObject(String settingId, String recordId) {
		JCQueryHelper.QueryObject searchOptions = new JCQueryHelper.QueryObject();

		JC_Related_Tabs_Setting__mdt mdt = [
			SELECT Id, MasterLabel, Related_Object__c, Label_Field__c
			FROM JC_Related_Tabs_Setting__mdt
			WHERE Id = :settingId
			LIMIT 1
		];
		searchOptions.objectName = mdt.Related_Object__c;
		searchOptions.fields = new List<String>{ 'Id', 'RecordTypeId', mdt.Label_Field__c };

		Map<String, JCQueryHelper.QueryFilterGroup> filterGroups = new Map<String, JCQueryHelper.QueryFilterGroup>();

		Map<String, JC_Filter_Group_Setting__mdt> mdtFilterGroups = new Map<String, JC_Filter_Group_Setting__mdt>(
			[
				SELECT Condition__c, Related_Tabs_Setting__c
				FROM JC_Filter_Group_Setting__mdt
				WHERE Related_Tabs_Setting__c = :settingId
			]
		);
		List<String> groupIds = new List<String>(mdtFilterGroups.keySet());

		List<JC_Filter_Setting__mdt> mdtFilters = new List<JC_Filter_Setting__mdt>();

		mdtFilters.addAll(
			[
				SELECT
					Id,
					Field__c,
					Value__c,
					Condition__c,
					Operator__c,
					Filter_Group_Setting__c,
					Related_Tabs_Setting__c
				FROM JC_Filter_Setting__mdt
				WHERE Filter_Group_Setting__c IN :groupIds
			]
		);

		mdtFilters.addAll(
			[
				SELECT
					Id,
					Field__c,
					Value__c,
					Condition__c,
					Operator__c,
					Filter_Group_Setting__c,
					Related_Tabs_Setting__c
				FROM JC_Filter_Setting__mdt
				WHERE Related_Tabs_Setting__c = :settingId
			]
		);

		for (JC_Filter_Group_Setting__mdt mdtGroup : mdtFilterGroups.values()) {
			JCQueryHelper.QueryFilterGroup filterGroup = new JCQueryHelper.QueryFilterGroup();
			filterGroup.condition = mdtGroup.Condition__c;
			filterGroups.put(mdtGroup.Id, filterGroup);
		}

		for (JC_Filter_Setting__mdt filter : mdtFilters) {
			if (filter.Filter_Group_Setting__c != null && filterGroups.containsKey(filter.Filter_Group_Setting__c)) {
				JCQueryHelper.QueryFilterGroup filterGroup = filterGroups.get(filter.Filter_Group_Setting__c);
				if (filter.Value__c == 'recordId') {
					filter.Value__c = recordId;
				}
				filterGroup.addFilter(filter.Field__c, filter.Value__c, filter.Condition__c, filter.Operator__c);
			} else if (filter.Related_Tabs_Setting__c != null) {
				if (filter.Value__c == 'recordId') {
					filter.Value__c = recordId;
				}
				searchOptions.addFilter(filter.Field__c, filter.Value__c, filter.Condition__c, filter.Operator__c);
			}
		}
		searchOptions.filterGroups = filterGroups.values();
		// Retrieve filter groups
		System.debug('searchOptions === ' + searchOptions);
		return searchOptions;
	}

	// @AuraEnabled(cacheable=true)
	// public static List<SObject> getListItems(QueryDetails queryParams) {
	// 	String fieldQuery = 'Id';
	// 	if (queryParams.fieldsString != null) {
	// 		fieldQuery += ',' + queryParams.fieldsString;
	// 	}
	// 	String query = 'SELECT ' + fieldQuery + ' FROM ' + queryParams.relatedObject;
	// 	query += ' WHERE ' + queryParams.referenceField + '=' + '\'' + String.escapeSingleQuotes(queryParams.recordId) + '\'';
	// 	if (queryParams.selectedFilter != '') {
	// 		query += ' AND ' + queryParams.filterField + '=' + '\'' + String.escapeSingleQuotes(queryParams.selectedFilter) + '\'';
	// 	}
	// 	if (queryParams.orderField != null) {
	// 		query += ' Order By ' + queryParams.orderField;
	// 	}
	// 	Schema.SObjectType objectType = Id.valueOf(queryParams.recordId).getSobjectType();
	// 	System.debug('query = ' + query);
	// 	List<sObject> sobjList = Database.query(query);
	// 	return sobjList;
	// }
	// public class QueryDetails {
	// 	@AuraEnabled
	// 	public String recordId { get; set; }
	// 	@AuraEnabled
	// 	public String relatedObject { get; set; }
	// 	@AuraEnabled
	// 	public String referenceField { get; set; }
	// 	@AuraEnabled
	// 	public String fieldsString { get; set; }
	// 	@AuraEnabled
	// 	public String filterField { get; set; }
	// 	@AuraEnabled
	// 	public String selectedFilter { get; set; }
	// 	@AuraEnabled
	// 	public String orderField { get; set; }
	// }
}
