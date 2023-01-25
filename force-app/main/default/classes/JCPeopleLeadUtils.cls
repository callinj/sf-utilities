public with sharing class JCPeopleLeadUtils {
	static final String PERMISSIONSETNAME = 'People_Lead';
	public static JCQueryHelper.QueryObject getPLAssignmentsObject(List<String> peopleListIdList) {
		JCQueryHelper.QueryObject assignmentQueryObject = JCQueryHelper.createQueryObject(
			'PermissionSetAssignment',
			'Id'
		);
		JCQueryHelper.QueryFilterGroup filterGroup = assignmentQueryObject.createFilterGroup('AND');
		filterGroup.addFilter('PermissionSetId', getPLPermissionSetObject().queryString(), 'AND', 'IN');
		assignmentQueryObject.addFilter('AssigneeId', peopleListIdList, 'AND', 'IN');
		return assignmentQueryObject;
	}
	public static JCQueryHelper.QueryObject getPLPermissionSetObject() {
		JCQueryHelper.QueryObject permissionSetQueryObject = JCQueryHelper.createQueryObject('PermissionSet', 'Id');
		permissionSetQueryObject.addFilter('Name', PERMISSIONSETNAME, 'AND', '=');
		return permissionSetQueryObject;
	}
}
