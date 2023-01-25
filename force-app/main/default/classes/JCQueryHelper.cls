public with sharing class JCQueryHelper {
	static final Set<String> DATE_LITERALS = new Set<String>{
		'YESTERDAY',
		'TODAY',
		'TOMORROW',
		'LAST_WEEK',
		'THIS_WEEK',
		'NEXT_WEEK',
		'LAST_MONTH',
		'THIS_MONTH',
		'NEXT_MONTH',
		'LAST_90_DAYS',
		'NEXT_90_DAYS',
		'LAST_N_DAYS',
		'NEXT_N_DAYS',
		'NEXT_N_WEEKS',
		'LAST_N_WEEKS',
		'NEXT_N_MONTHS',
		'LAST_N_MONTHS',
		'THIS_QUARTER',
		'LAST_QUARTER',
		'NEXT_QUARTER',
		'NEXT_N_QUARTERS',
		'LAST_N_QUARTERS',
		'THIS_YEAR',
		'LAST_YEAR',
		'NEXT_YEAR',
		'NEXT_N_YEARS',
		'LAST_N_YEARS',
		'THIS_FISCAL_QUARTER',
		'LAST_FISCAL_QUARTER',
		'NEXT_FISCAL_QUARTER',
		'NEXT_N_FISCAL_QUARTERS',
		'LAST_N_FISCAL_QUARTERS',
		'THIS_FISCAL_YEAR',
		'LAST_FISCAL_YEAR',
		'NEXT_FISCAL_YEAR',
		'NEXT_N_FISCAL_YEARS',
		'LAST_N_FISCAL_YEARS'
	};
	// TODO | Allow query to be used with a GROUP BY clause
	static final Set<String> AGGREGATE_FUNCTIONS = new Set<String>{
		'AVG',
		'COUNT',
		'COUNT_DISTINCT',
		'MIN',
		'MAX',
		'SUM'
	};
	public class CustomException extends Exception {
	}

	public static QueryObject createQueryObject(String objectName) {
		QueryObject queryObject = new QueryObject();
		queryObject.objectName = objectName;
		return queryObject;
	}
	public static QueryObject createQueryObject(String objectName, Object fields) {
		QueryObject queryObject = new QueryObject();
		queryObject.objectName = objectName;
		queryObject.fields = setFields(fields);
		return queryObject;
	}
	public static QueryObject createQueryObject(String objectName, Object fields, Integer queryLimit) {
		QueryObject queryObject = new QueryObject();
		queryObject.objectName = objectName;
		queryObject.fields = setFields(fields);
		queryObject.queryLimit = queryLimit;
		return queryObject;
	}
	public static QueryObject createQueryObject(String objectName, Object fields, Integer queryLimit, Integer offset) {
		QueryObject queryObject = new QueryObject();
		queryObject.objectName = objectName;
		queryObject.fields = setFields(fields);
		queryObject.queryLimit = queryLimit;
		queryObject.offset = offset;
		return queryObject;
	}

	private static List<String> setFields(Object fields) {
		List<String> fieldsList = new List<String>();
		String type = JCUtils.getType(fields);

		switch on type {
			when 'String' {
				fieldsList = String.valueOf(fields).replace(' ', '').split(',');
			}
			when 'List' {
				fieldsList = (List<String>) fields;
			}
			when else {
				throw new CustomException('QueryObject.fields must be of type List<String> or String.');
			}
		}
		return fieldsList;
	}
	public class CountResponse extends JCResponse {
		@AuraEnabled
		public Integer totalResults { get; set; }
		public CountResponse() {
			super();
			totalResults = 0;
		}
	}
	public class QueryObject {
		@AuraEnabled
		public String objectName { get; set; }
		@AuraEnabled
		public List<String> fields { get; set; }
		@AuraEnabled
		public Integer offset { get; set; }
		@AuraEnabled
		public Integer queryLimit { get; set; }
		@AuraEnabled
		public List<QueryFilterGroup> filterGroups { get; set; }
		@AuraEnabled
		public List<QueryFilter> filters { get; set; }
		@AuraEnabled
		public List<QueryOrder> querySorts { get; set; }

		// TODO | Check if object is valid -> Schema.getGlobalDescribe().get(objectName)
		// TODO | Above solution doesn't work for KnowledgeArticleVersion -> Figure out a way
		// TODO | Check if valid field

		public String queryString() {
			return buildQueryString(null, null);
		}
		public String queryString(String type, String field) {
			return buildQueryString(type, field);
		}
		public List<SObject> getResults() {
			return Security.stripInaccessible(AccessType.READABLE, Database.query(buildQueryString(null, null)))
				?.getRecords();
		}
		public Database.QueryLocator getQueryLocator() {
			return Database.getQueryLocator(buildQueryString(null, null));
		}
		public Integer getTotalResults() {
			return Database.countQuery(buildQueryString('COUNT', null));
		}
		public Integer getTotalResults(String field) {
			return Database.countQuery(buildQueryString('COUNT', field));
		}
		@TestVisible
		private String buildQueryString(String type, String field) {
			String queryString = 'SELECT ';

			if (type == null) {
				queryString +=
					fieldsString() +
					' FROM ' +
					objectName.replaceAll('"|\'', '') +
					filterString() +
					orderString() +
					limitString() +
					offsetString();
			} else {
				type = type?.toUpperCase();
				if (!AGGREGATE_FUNCTIONS.contains(type)) {
					throw new CustomException('Not a valid Aggregate Function');
				}

				queryString += type;

				queryString += field != null ? '(' + field + ')' : '()';

				queryString += ' FROM ' + objectName.replaceAll('"|\'', '') + filterString();
			}
			return queryString;
		}

		public String fieldsString() {
			if (fields == null) {
				fields = new List<String>{ 'Id' };
			}
			return String.join(fields, ', ');
		}
		public String filterString() {
			String returnString = '';
			List<QueryFilterGroup> tempQueryFilterGroups = filterGroups?.clone();
			List<QueryFilter> tempFilters = filters?.clone();
			if (tempFilters?.size() > 0) {
				returnString += buildFilterString(tempFilters, String.isNotEmpty(returnString));
			}
			if (tempQueryFilterGroups?.size() > 0) {
				for (
					Integer iQueryFilterGroup = 0; iQueryFilterGroup < tempQueryFilterGroups.size(); iQueryFilterGroup++
				) {
					QueryFilterGroup tempQueryFilterGroup = tempQueryFilterGroups[iQueryFilterGroup];
					if (tempQueryFilterGroup.filters?.size() > 0) {
						if (returnString != '') {
							returnString += ' ' + tempQueryFilterGroup.condition;
						}
						returnString += ' (' + buildFilterString(tempQueryFilterGroup.filters, false) + ')';
					}
				}
			}

			returnString = String.isNotEmpty(returnString) ? ' WHERE' + returnString : returnString;
			return returnString;
		}
		public String orderString() {
			String returnString = '';
			if (querySorts != null) {
				for (Integer i = 0; i < querySorts.size(); i++) {
					QueryOrder querySort = querySorts[i];
					if (String.isNotBlank(querySort.field)) {
						if (i != 0) {
							returnString += ',';
						}
						returnString += ' ' + querySort.field;
						if (querySort.descending != null && querySort.descending) {
							returnString += ' DESC';
						}
						if (querySort?.nullsLast) {
							returnString += ' NULLS LAST';
						}
					}
				}
			}
			returnString = String.isNotEmpty(returnString) ? ' ORDER BY' + returnString : returnString;
			return returnString;
		}
		public String limitString() {
			return queryLimit != null ? ' LIMIT ' + String.valueOf(queryLimit) : '';
		}
		public String offsetString() {
			return offset != null ? ' OFFSET ' + offset : '';
		}

		public void addFilter(String filterField, Object filterValue) {
			setFilter(new QueryFilter(filterField, filterValue));
		}
		public void addFilter(String filterField, Object filterValue, String filterCondition, String filterOperator) {
			setFilter(new QueryFilter(filterField, filterValue, filterCondition, filterOperator));
		}
		public void addFilter(QueryFilter filter) {
			if (filter != null) {
				setFilter(filter);
			}
		}
		public void addFilters(List<QueryFilter> filters) {
			for (QueryFilter filter : filters) {
				setFilter(filter);
			}
		}
		@TestVisible
		private void setFilter(QueryFilter queryFilter) {
			if (filters == null) {
				filters = new List<QueryFilter>{ queryFilter };
			} else {
				filters.add(queryFilter);
			}
		}

		public QueryFilterGroup createFilterGroup(String condition) {
			if (filterGroups == null) {
				filterGroups = new List<QueryFilterGroup>();
			}

			QueryFilterGroup filterGroup = new QueryFilterGroup(condition);
			filterGroups.add(filterGroup);
			return filterGroup;
		}

		public void setOrder(String orderField) {
			setQuerySort(new QueryOrder(orderField));
		}
		public void setOrder(QueryOrder orderAttribute) {
			setQuerySort(orderAttribute);
		}
		public void setOrder(String orderField, Boolean orderDescending, Boolean orderNullsLast) {
			setQuerySort(new QueryOrder(orderField, orderDescending, orderNullsLast));
		}
		@TestVisible
		private void setQuerySort(QueryOrder orderAttribute) {
			if (querySorts == null) {
				querySorts = new List<QueryOrder>{ orderAttribute };
			} else {
				querySorts.add(orderAttribute);
			}
		}
	}
	public class QueryFilterGroup {
		@AuraEnabled
		public String condition { get; set; }
		@AuraEnabled
		public List<QueryFilter> filters { get; set; }
		public QueryFilterGroup() {
			condition = 'AND';
		}
		public QueryFilterGroup(String groupCondition) {
			condition = groupCondition;
		}
		public QueryFilterGroup(String groupCondition, List<QueryFilter> groupFilters) {
			condition = groupCondition;
			filters = groupFilters;
		}

		public void addFilter(String filterField, Object filterValue) {
			setFilter(new QueryFilter(filterField, filterValue));
		}
		public void addFilter(String filterField, Object filterValue, String filterCondition, String filterOperator) {
			setFilter(new QueryFilter(filterField, filterValue, filterCondition, filterOperator));
		}
		@TestVisible
		private void setFilter(QueryFilter queryFilter) {
			if (filters == null) {
				filters = new List<QueryFilter>{ queryFilter };
			} else {
				filters.add(queryFilter);
			}
		}
	}
	public class QueryFilter {
		@AuraEnabled
		public String field { get; set; }
		@AuraEnabled
		public Object value { get; set; }
		@AuraEnabled
		public String condition { get; set; }
		@AuraEnabled
		public String operator { get; set; }
		public QueryFilter() {
			condition = 'AND';
			operator = '=';
		}
		public QueryFilter(String filterField, Object filterValue) {
			field = filterField;
			value = filterValue;
			condition = 'AND';
			operator = '=';
		}
		public QueryFilter(String filterField, Object filterValue, String filterCondition, String filterOperator) {
			field = filterField;
			value = filterValue;
			condition = filterCondition != null ? filterCondition : 'AND';
			operator = filterOperator != null ? filterOperator : '=';
		}
	}
	public class QueryOrder {
		@AuraEnabled
		public String field { get; set; }
		@AuraEnabled
		public Boolean descending { get; set; }
		@AuraEnabled
		public Boolean nullsLast { get; set; }
		public QueryOrder() {
			descending = false;
			nullsLast = true;
		}
		public QueryOrder(String orderField) {
			field = orderField;
			descending = false;
			nullsLast = true;
		}
		public QueryOrder(String orderField, Boolean orderDescending, Boolean orderNullsLast) {
			field = orderField;
			descending = orderDescending;
			nullsLast = orderNullsLast;
		}
	}
	@TestVisible
	private static String buildFilterString(List<QueryFilter> filters, Boolean addCondition) {
		String returnString = '';
		for (Integer iFilter = 0; iFilter < filters.size(); iFilter++) {
			QueryFilter tempFilter = filters[iFilter];
			if (String.isNotBlank(tempFilter.field) && String.isNotBlank(tempFilter.operator)) {
				Object tempValue = tempFilter.value;
				String valueType = JCUtils.getType(tempValue);
				if ((valueType == 'String' || valueType == 'Id')) {
					String holderValue = (String) tempValue;
					holderValue = holderValue.split(':')[0]; // TODO | Refactor - Check if integer is after :
					if (!DATE_LITERALS.contains(holderValue)) {
						tempValue = JCUtils.addQuotes((String) tempValue);
					}
				} else if ((valueType == 'List' || valueType == 'Set')) {
					// TODO - Figure out how to convert set to list
					// if (valueType == 'Set') {
					// 	tempValue = new List<Object>();
					// }
					List<Object> valueList = (List<Object>) tempValue;
					// String itemValueType = JCUtils.getType(valueList.get(0));
					String itemValueType = JCUtils.getType(valueList.get(0));
					if (itemValueType == 'String' || itemValueType == 'Id') {
						for (Integer i = 0; i < valueList.size(); i++) {
							Object item = JCUtils.addQuotes((String) valueList.get(i));
							valueList.set(i, item);
						}
						tempValue = valueList;
					}
					tempValue = '(' + String.join((List<Object>) tempValue, ', ') + ')';
				} else if (valueType == 'SOQL') {
					tempValue = '(' + tempValue + ')';
				}
				if (iFilter != 0 || addCondition) {
					returnString += ' ' + tempFilter.condition;
				}
				returnString +=
					' ' +
					tempFilter.field.replaceAll('"|\'', '') +
					' ' +
					tempFilter.operator.replaceAll('"|\'', '') +
					' ' +
					tempValue;
			}
		}
		return returnString;
	}
	@AuraEnabled(cacheable=true)
	public static JCResponse getQueryObjectResults(QueryObject queryOptions) {
		JCResponse response = new JCResponse();
		try {
			response.results = queryOptions.getResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
		}
		return response;
	}
	@AuraEnabled(cacheable=true)
	public static CountResponse getQueryObjectCountResults(QueryObject queryOptions) {
		CountResponse response = new CountResponse();
		try {
			response.totalResults = queryOptions.getTotalResults();
		} catch (Exception e) {
			response.success = false;
			response.messages.add(e.getMessage());
		}
		return response;
	}
}
