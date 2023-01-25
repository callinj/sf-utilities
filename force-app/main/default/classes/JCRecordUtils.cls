public with sharing class JCRecordUtils {
	static Schema.SObjectField validField = null;
	static List<String> validFields = new List<String>();
	static List<String> invalidFields = new List<String>();
	static Map<String, Schema.DescribeSObjectResult> objectInfo = new Map<String, Schema.DescribeSObjectResult>();
	static Map<String, List<Schema.sObjectType>> fieldInfo = new Map<String, List<Schema.sObjectType>>();
	static Map<String, String> fieldLabelMap = new Map<String, String>();
	public class RecordInfo extends JCResponse {
		@AuraEnabled
		public Map<String, FieldDetails> fields { get; set; }
		public RecordInfo() {
			super();
			fields = new Map<String, FieldDetails>();
		}
	}
	public class FieldInfo {
		public List<String> fields { get; set; }
		public List<String> parts { get; set; }
		public String relationship { get; set; }
		public String relationshipLabel { get; set; }
		public Schema.sObjectType objectType { get; set; }
		public Boolean checked { get; set; }
		public FieldInfo() {
			fields = new List<String>();
			parts = new List<String>();
			relationship = null;
			checked = false;
		}
	}
	public class FieldDetails {
		@AuraEnabled
		public String fieldRelationship { get; set; }
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public Object value { get; set; }
		@AuraEnabled
		public Boolean isValid { get; set; }
		public FieldDetails() {
			fieldRelationship = null;
			label = null;
			value = null;
			isValid = false;
		}
		public FieldDetails(Object setValue) {
			fieldRelationship = null;
			label = null;
			value = setValue;
			isValid = false;
		}
		public FieldDetails(Object setValue, String setLabel) {
			fieldRelationship = null;
			label = setLabel;
			value = setValue;
			isValid = false;
		}
		public FieldDetails(Object setValue, String setLabel, String setRelationship) {
			value = setValue;
			label = setLabel;
			fieldRelationship = setRelationship;
		}
	}

	@AuraEnabled(cacheable=true)
	public static RecordInfo getRecordInfo(JCQueryHelper.QueryObject objectInfo, String recordId) {
		RecordInfo response = new RecordInfo();
		List<String> masterFieldList = objectInfo.fields.clone();
		Map<String, FieldInfo> testMap = new Map<String, FieldInfo>();
		Map<String, List<String>> fieldMap = new Map<String, List<String>>();

		SObjectType objectType = Id.valueOf(recordId).getSObjectType();
		Map<String, Schema.SObjectField> objectFields = objectType.getDescribe().fields.getMap();

		for (String currentField : objectInfo.fields) {
			List<String> fieldParts = currentField.split('\\.');
			List<String> modifiedParts = fieldParts.clone();
			String field = modifiedParts.remove((fieldParts.size() - 1));
			String key = String.join(modifiedParts, '.');
			fieldMap.put(currentField, fieldParts);
			if (testMap.containsKey(key)) {
				testMap.get(key).fields.add(field);
			} else {
				FieldInfo fieldInfo = new FieldInfo();
				fieldInfo.fields.add(field);
				fieldInfo.parts = modifiedParts;
				fieldInfo.relationship = String.join(modifiedParts, '.');
				testMap.put(key, fieldInfo);
			}
		}
		for (String relationship : testMap.keySet()) {
			validField = null;
			FieldInfo fieldInfo = testMap.get(relationship);
			if (!fieldInfo.checked) {
				checkValidFields(fieldInfo, new List<Schema.SObjectType>{ objectType });
			}
		}
		objectInfo.objectName = objectType.getDescribe().getName();
		objectInfo.fields = validFields;
		try {
			String queryString = objectInfo.queryString();
			SObject record;
			if (objectInfo.fields.size() > 0) {
				SObjectAccessDecision securityDecision = Security.stripInaccessible(
					AccessType.READABLE,
					Database.query(queryString)
				);
				record = securityDecision.getRecords()[0];
				response.results.add(record);
			}
			for (String requestedField : masterFieldList) {
				Object fieldValue;
				Boolean isValid = validFields.contains(requestedField);
				if (isValid) {
					fieldValue = getFieldValue(record, requestedField);
					fieldValue = fieldValue != null ? fieldValue : '';
				}
				FieldDetails details = new FieldDetails(fieldValue, fieldLabelMap.get(requestedField), requestedField);
				details.isValid = isValid;
				System.debug('details === ' + details);
				response.fields.put(requestedField, details);
			}
		} catch (Exception e) {
			response.success = false;
			if (e.getMessage() == 'unexpected token: \'FROM\'') {
				response.messages.add('Query statement has no valid fields');
			} else {
				response.messages.add(e.getMessage());
			}
		}
		return response;
	}
	public static Object getFieldValue(SObject record, String field) {
		Sobject currentObject = record;
		String[] fieldParts = field.split('\\.');
		for (Integer i = 0; i < fieldParts.size() - 1; i++) {
			currentObject = (Sobject) currentObject.getSobject(fieldParts[i]);
			if (currentObject == null) {
				return null;
			}
		}
		return currentObject.get(fieldParts[fieldParts.size() - 1]);
	}
	private static void checkValidFields(FieldInfo fieldInfo, List<Schema.sObjectType> objectTypes) {
		List<String> requestedFields = fieldInfo.fields;
		List<String> fieldParts = fieldInfo.parts;
		while (objectTypes?.size() > 0 && validField == null) {
			Schema.sObjectType objectType = objectTypes.remove(0);
			Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
			Map<String, Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
			List<String> relationshipParts = fieldParts.clone();
			if (relationshipParts.size() > 0) {
				Boolean validRelationship = true;
				while (relationshipParts.size() > 0 && validRelationship && validField == null) {
					String relationshipPart = relationshipParts.remove(0).toLowerCase();
					validRelationship = false;
					for (Schema.SObjectField objectField : objectFields.values()) {
						Schema.DescribeFieldResult fieldDescribe = objectField.getDescribe();
						String fieldRelationship = fieldDescribe.getRelationshipName();
						if (
							String.isNotBlank(fieldRelationship) && fieldRelationship.toLowerCase() == relationshipPart
						) {
							List<Schema.sObjectType> fieldReference = fieldDescribe.getReferenceTo();
							String cleanLabel = fieldDescribe.getLabel().replace(' ID', '');
							fieldInfo.relationshipLabel = fieldInfo.relationshipLabel != null
								? fieldInfo.relationshipLabel + ' ' + cleanLabel
								: cleanLabel;
							validRelationship = true;
							checkValidFields(fieldInfo, fieldReference);
						}
					}
				}
			}
			if (!fieldInfo.checked) {
				fieldInfo.checked = true;
				for (String requestedField : requestedFields) {
					validField = objectFields.get(requestedField);
					String fullField = fieldInfo.relationship != ''
						? fieldInfo.relationship + '.' + requestedField
						: requestedField;
					if (validField != null) {
						DescribeFieldResult fieldDescribe = validField.getDescribe();
						String fieldLabel = validField.getDescribe().getLabel().replace(' ID', '');
						String fullLabel = fieldInfo.relationshipLabel != null
							? fieldInfo.relationshipLabel + ' ' + fieldLabel
							: fieldLabel;
						fieldLabelMap.put(fullField, fullLabel);
						validFields.add(fullField);
					} else {
						invalidFields.add(fullField);
					}
				}
			}
		}
	}
}
