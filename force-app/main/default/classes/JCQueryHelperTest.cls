@isTest
public class JCQueryHelperTest {
	@TestVisible
	static JCQueryHelper.QueryObject createData() {
		JCQueryHelper.QueryObject queryData = JCQueryHelper.createQueryObject('Topic', 'Name', 500, 25);
		JCQueryHelper.QueryFilterGroup filterGroup = queryData.createFilterGroup('OR');

		queryData.addFilter('Name', '%Topic%', 'OR', 'LIKE');
		queryData.setOrder('Name', false, true);
		filterGroup.addFilter('Name', '%Topic%', 'OR', 'LIKE');

		return queryData;
	}

	@isTest
	static void createQueryObjectTest() {
		JCQueryHelper.QueryObject queryData = JCQueryHelper.createQueryObject('Topic');

		System.assertEquals('Topic', queryData.objectName, 'createQueryObjectTest objectName Test: failed');
		System.assertEquals(null, queryData.fields, 'createQueryObjectTest fields Test: failed');
		System.assertEquals(null, queryData.queryLimit, 'createQueryObjectTest queryLimit Test: failed');
		System.assertEquals(null, queryData.offset, 'createQueryObjectTest offset Test: failed');

		queryData = JCQueryHelper.createQueryObject('Topic', 'Id, Name');
		System.assertEquals('Topic', queryData.objectName, 'createQueryObjectTest objectName Test: failed');
		System.assertEquals(
			new List<String>{ 'Id', 'Name' },
			queryData.fields,
			'createQueryObjectTest fields Test: failed'
		);
		System.assertEquals(null, queryData.queryLimit, 'createQueryObjectTest queryLimit Test: failed');
		System.assertEquals(null, queryData.offset, 'createQueryObjectTest offset Test: failed');

		queryData = JCQueryHelper.createQueryObject('Topic', 'Id, Name', 500);
		System.assertEquals('Topic', queryData.objectName, 'createQueryObjectTest objectName Test: failed');
		System.assertEquals(
			new List<String>{ 'Id', 'Name' },
			queryData.fields,
			'createQueryObjectTest fields Test: failed'
		);
		System.assertEquals(500, queryData.queryLimit, 'createQueryObjectTest queryLimit Test: failed');
		System.assertEquals(null, queryData.offset, 'createQueryObjectTest offset Test: failed');

		queryData = JCQueryHelper.createQueryObject('Topic', new List<String>{ 'Id', 'Name' }, 500, 25);
		System.assertEquals('Topic', queryData.objectName, 'createQueryObjectTest objectName Test: failed');
		System.assertEquals(
			new List<String>{ 'Id', 'Name' },
			queryData.fields,
			'createQueryObjectTest fields Test: failed'
		);
		System.assertEquals(500, queryData.queryLimit, 'createQueryObjectTest queryLimit Test: failed');
		System.assertEquals(25, queryData.offset, 'createQueryObjectTest offset Test: failed');
	}

	@isTest
	static void queryStringTest() {
		JCQueryHelper.QueryObject queryData = createData();
		System.assertEquals(
			'SELECT Name FROM Topic WHERE Name LIKE \'%Topic%\' OR ( Name LIKE \'%Topic%\') ORDER BY Name NULLS LAST LIMIT 500 OFFSET 25',
			queryData.queryString(),
			'queryStringTest queryString() Test: failed'
		);
		System.assertEquals(
			'SELECT COUNT() FROM Topic WHERE Name LIKE \'%Topic%\' OR ( Name LIKE \'%Topic%\')',
			queryData.queryString('count', null),
			'queryStringTest queryString() Test: failed'
		);
	}

	@isTest
	static void buildQueryStringTest() {
		JCQueryHelper.QueryObject queryData = createData();

		System.assertEquals(
			'SELECT COUNT(Id) FROM Topic WHERE Name LIKE \'%Topic%\' OR ( Name LIKE \'%Topic%\')',
			queryData.buildQueryString('count', 'Id'),
			'queryStringTest queryString() Test: failed'
		);
		System.assertEquals(
			'SELECT COUNT() FROM Topic WHERE Name LIKE \'%Topic%\' OR ( Name LIKE \'%Topic%\')',
			queryData.buildQueryString('count', null),
			'queryStringTest queryString() Test: failed'
		);
	}

	@isTest
	static void fieldsStringTest() {
		JCQueryHelper.QueryObject queryData = new JCQueryHelper.QueryObject();
		System.assertEquals(queryData.fieldsString(), 'Id', 'fieldsStringTest fieldsString() Id Test: failed');
		queryData.fields = new List<String>{ 'Id', 'Name' };
		System.assertEquals(
			queryData.fieldsString(),
			'Id, Name',
			'fieldsStringTest fieldsString() Multiple Fields Test: failed'
		);
	}

	@isTest
	static void filterStringTest() {
		JCQueryHelper.QueryObject queryData = createData();
		System.assertEquals(
			' WHERE Name LIKE \'%Topic%\' OR ( Name LIKE \'%Topic%\')',
			queryData.filterString(),
			'filterStringTest filterString() Test: failed'
		);
	}

	@isTest
	static void orderStringTest() {
		JCQueryHelper.QueryObject queryData = createData();
		System.assertEquals(
			queryData.orderString(),
			' ORDER BY Name NULLS LAST',
			'orderStringTest orderString() Test: failed'
		);
	}

	@isTest
	static void limitStringTest() {
		JCQueryHelper.QueryObject queryData = createData();
		System.assertEquals(
			queryData.limitString(),
			' LIMIT 500',
			'limitStringTest limitString() queryLimit != null Test: failed'
		);
		JCQueryHelper.QueryObject queryDataOriginal = new JCQueryHelper.QueryObject();
		System.assertEquals(
			queryDataOriginal.limitString(),
			'',
			'limitStringTest limitString() queryLimit == null Test: failed'
		);
	}

	@isTest
	static void offsetStringTest() {
		JCQueryHelper.QueryObject queryData = createData();
		System.assertEquals(
			queryData.offsetString(),
			' OFFSET 25',
			'offsetStringTest offsetString() offset != null Test: failed'
		);
		JCQueryHelper.QueryObject queryDataOriginal = new JCQueryHelper.QueryObject();
		System.assertEquals(
			queryDataOriginal.offsetString(),
			'',
			'offsetStringTest offsetString() offset == null Test: failed'
		);
	}

	@isTest
	static void filterAttributeTest() {
		JCQueryHelper.QueryFilter twoAttributes = new JCQueryHelper.QueryFilter('Name', '%Topic%');
		System.assertEquals(twoAttributes.field, 'Name', 'filterAttributeTest twoAttributes.field Test: failed');
		System.assertEquals(twoAttributes.value, '%Topic%', 'filterAttributeTest twoAttributes.value Test: failed');
		System.assertEquals(twoAttributes.condition, 'AND', 'filterAttributeTest twoAttributes.condition Test: failed');
		System.assertEquals(twoAttributes.operator, '=', 'filterAttributeTest twoAttributes.operator Test: failed');

		JCQueryHelper.QueryFilter fourAttributes = new JCQueryHelper.QueryFilter('Name', '%Topic%', 'OR', 'LIKE');
		System.assertEquals(fourAttributes.field, 'Name', 'filterAttributeTest fourAttributes.field Test: failed');
		System.assertEquals(fourAttributes.value, '%Topic%', 'filterAttributeTest fourAttributes.value Test: failed');
		System.assertEquals(
			fourAttributes.condition,
			'OR',
			'filterAttributeTest fourAttributes.condition Test: failed'
		);
		System.assertEquals(
			fourAttributes.operator,
			'LIKE',
			'filterAttributeTest fourAttributes.operator Test: failed'
		);
	}

	@isTest
	static void buildFilterStringTest() {
		JCQueryHelper.QueryObject queryData = createData();
		String testFilterStringTrue = JCQueryHelper.buildFilterString(queryData.filters, true);
		String testFilterStringFalse = JCQueryHelper.buildFilterString(queryData.filters, false);
		System.assertEquals(
			' OR Name LIKE \'%Topic%\'',
			testFilterStringTrue,
			'buildFilterStringTest buildFilterString() addCondition = true Test: failed'
		);
		System.assertEquals(
			' Name LIKE \'%Topic%\'',
			testFilterStringFalse,
			'buildFilterStringTest buildFilterString() addCondition = false Test: failed'
		);
	}
	@isTest
	static void buildFilterStringListTest() {
		// JCQueryHelper.QueryObject queryData = createData();
		List<JCQueryHelper.QueryFilter> filters = new List<JCQueryHelper.QueryFilter>{
			new JCQueryHelper.QueryFilter('Name', new List<String>{ 'Test', 'Test 1' }, 'OR', 'IN')
		};
		String testFilterString = JCQueryHelper.buildFilterString(filters, false);
		System.assertEquals(
			' Name IN (\'Test\', \'Test 1\')',
			testFilterString,
			'buildFilterStringListTest buildFilterString() list Test: failed'
		);
	}

	@isTest
	static void addFilterQueryObjectTest() {
		JCQueryHelper.QueryObject queryData = createData();

		queryData.addFilter('Name', 'Topic One');
		System.assertEquals(queryData.filters[1].field, 'Name', 'addFilterTest field Test: failed');
		System.assertEquals(queryData.filters[1].value, 'Topic One', 'addFilterTest value Test: failed');
		System.assertEquals(queryData.filters[1].condition, 'AND', 'addFilterTest condition Test: failed');
		System.assertEquals(queryData.filters[1].operator, '=', 'addFilterTest operator Test: failed');

		queryData.addFilter('Name', new List<String>{ '1234' }, 'OR', 'IN');
		System.assertEquals(queryData.filters[2].field, 'Name', 'addFilterTest field Test: failed');
		System.assertEquals(queryData.filters[2].value, new List<String>{ '1234' }, 'addFilterTest value Test: failed');
		System.assertEquals(queryData.filters[2].condition, 'OR', 'addFilterTest condition Test: failed');
		System.assertEquals(queryData.filters[2].operator, 'IN', 'addFilterTest operator Test: failed');
	}

	@isTest
	static void setFilterQueryObjectTest() {
		JCQueryHelper.QueryObject queryData = new JCQueryHelper.QueryObject();

		queryData.setFilter(new JCQueryHelper.QueryFilter('Name', 'Topic'));
		System.assertEquals(1, queryData.filters.size(), 'setFilterQueryObjectTest size Test: failed');

		queryData.setFilter(new JCQueryHelper.QueryFilter('Name', 'Topic'));
		System.assertEquals(2, queryData.filters.size(), 'setFilterQueryObjectTest size Test: failed');
	}

	@isTest
	static void setOrderTest() {
		JCQueryHelper.QueryObject queryData = createData();

		queryData.setOrder('Name');
		System.assertEquals('Name', queryData.querySorts[1].field, 'setOrderTest field Test: failed');
		System.assertEquals(false, queryData.querySorts[1].descending, 'setOrderTest descending Test: failed');
		System.assertEquals(true, queryData.querySorts[1].nullsLast, 'setOrderTest nullsLast Test: failed');

		queryData.setOrder('Name', true, false);
		System.assertEquals('Name', queryData.querySorts[2].field, 'setOrderTest field Test: failed');
		System.assertEquals(true, queryData.querySorts[2].descending, 'setOrderTest descending Test: failed');
		System.assertEquals(false, queryData.querySorts[2].nullsLast, 'setOrderTest nullsLast Test: failed');

		queryData.setOrder(new JCQueryHelper.QueryOrder('Name'));
		System.assertEquals('Name', queryData.querySorts[3].field, 'setOrderTest field Test: failed');
		System.assertEquals(false, queryData.querySorts[3].descending, 'setOrderTest descending Test: failed');
		System.assertEquals(true, queryData.querySorts[3].nullsLast, 'setOrderTest nullsLast Test: failed');
	}

	@isTest
	static void setQuerySortTest() {
		JCQueryHelper.QueryObject queryData = new JCQueryHelper.QueryObject();

		queryData.setQuerySort(new JCQueryHelper.QueryOrder('Name'));
		System.assertEquals('Name', queryData.querySorts[0].field, 'setQuerySortTest name Test: failed');

		queryData.setQuerySort(new JCQueryHelper.QueryOrder('Id'));
		System.assertEquals('Id', queryData.querySorts[1].field, 'setQuerySortTest name Test: failed');
	}

	@isTest
	static void addFilterQueryFilterTest() {
		JCQueryHelper.QueryObject queryData = createData();
		JCQueryHelper.QueryFilterGroup filterGroup = queryData.createFilterGroup('AND');

		filterGroup.addFilter('Name', 'Topic One');
		System.assertEquals(filterGroup.filters[0].field, 'Name', 'addFilterTest field Test: failed');
		System.assertEquals(filterGroup.filters[0].value, 'Topic One', 'addFilterTest value Test: failed');
		System.assertEquals(filterGroup.filters[0].condition, 'AND', 'addFilterTest condition Test: failed');
		System.assertEquals(filterGroup.filters[0].operator, '=', 'addFilterTest operator Test: failed');

		filterGroup.addFilter('Name', new List<String>{ '1234' }, 'OR', 'IN');
		System.assertEquals(filterGroup.filters[1].field, 'Name', 'addFilterTest field Test: failed');
		System.assertEquals(
			filterGroup.filters[1].value,
			new List<String>{ '1234' },
			'addFilterTest value Test: failed'
		);
		System.assertEquals(filterGroup.filters[1].condition, 'OR', 'addFilterTest condition Test: failed');
		System.assertEquals(filterGroup.filters[1].operator, 'IN', 'addFilterTest operator Test: failed');

		filterGroup = new JCQueryHelper.QueryFilterGroup('AND', filterGroup.filters);
		System.assertEquals(filterGroup.filters[0].field, 'Name', 'addFilterTest field Test: failed');
		System.assertEquals(filterGroup.filters[0].value, 'Topic One', 'addFilterTest value Test: failed');
		System.assertEquals(filterGroup.filters[0].condition, 'AND', 'addFilterTest condition Test: failed');
		System.assertEquals(filterGroup.filters[0].operator, '=', 'addFilterTest operator Test: failed');

		System.assertEquals(filterGroup.filters[1].field, 'Name', 'addFilterTest field Test: failed');
		System.assertEquals(
			filterGroup.filters[1].value,
			new List<String>{ '1234' },
			'addFilterTest value Test: failed'
		);
		System.assertEquals(filterGroup.filters[1].condition, 'OR', 'addFilterTest condition Test: failed');
		System.assertEquals(filterGroup.filters[1].operator, 'IN', 'addFilterTest operator Test: failed');
	}

	@isTest
	static void setFilterQueryFilterTest() {
		JCQueryHelper.QueryObject queryData = new JCQueryHelper.QueryObject();
		JCQueryHelper.QueryFilterGroup filterGroup = queryData.createFilterGroup('AND');

		filterGroup.setFilter(new JCQueryHelper.QueryFilter('Name', 'Topic'));
		System.assertEquals(1, filterGroup.filters.size(), 'setFilterQueryObjectTest size Test: failed');

		filterGroup.setFilter(new JCQueryHelper.QueryFilter('Name', 'Topic'));
		System.assertEquals(2, filterGroup.filters.size(), 'setFilterQueryObjectTest size Test: failed');
	}
	// @IsTest
	// static void getQueryObjectResults(){

	// 	Test.startTest();
	// 	System.runAs(contextuser){

	// 	}
	// 	Test.stopTest();

	// }
}
