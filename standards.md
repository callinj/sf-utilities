Press ctrl/cmd+shift+v to view me in pretty preview mode in VSCode

## Table of Contents

-   [General](#general)
-   [Variables](#variables)
-   [SOQL](#soql)
-   [Triggers](#triggers)
-   [Apex Tests](#apex-tests)
-   [Comments & Documentation](#comments--documentation)
-   [HTML/CSS](#htmlcss)

## **General**

### **Tab Indentation**

4 spaces

### **Max Line/Print Width**

120 characters. Keep between 80-100 as much as possible.

### **Case**

Variables: `camelCase`
Constants: `SCREAMING_SNAKE_CASE`
Apex Class: `PascalCase`
Aura/LWC Bundle: `camelCase`

### **Multi-line statements**

Indent multiple lines for a single statement

```java
String  message  =  'I am a very long string, yes I am, I am a super duper long string. '
+  'I am so long that I need multiple lines for a single statement.';

// Multi-line if/for indented twice with blocked code indented once
if (phase ==  'Delivery/DI'  && (Type ==  'DelSSLUp'  || Type ==  'DelSSLDown')
&& (tr.Role__c  ==  'Account Information Security Lead'
||  tr.Role__c  ==  'Client Account Lead (CAL)'
||  tr.Role__c  ==  'Accountable Managing Director')) {
	// Code here...
}
```

### **Annotations**

Declare above class/method so VSCode renders color-coding correctly.

```java
@AuraEnabled
public  static  String  getBillingTransactions(String projectId) {}
```

# **Variables**

## Declaration

Always declare variables at the top of their scope (class, method, loop, etc.), even if they are not initialized until mid-scope.

Declare all initialized variables first, then all uninitialized.

Group related variables together.

List in the order they're first referenced in code as best you can, balancing with grouping related together.

```java
/* Apex */
public class Example {
	static  final  String  CONST_STRING  =  'I am a class constant.'; // Class scope
	public  static  void  assignExampleVariables() {
		// Method scope
		List<User> activeUsers = new List<User>();
		List<User> inactiveUsers = new List<User>();
		Set<Email> activeUserEmails = new Set<Email>();
		List<Person__c> persons;
		for(User currentUser : [SELECT Id, Email, IsActive FROM User]) {
			Boolean  isActive  =  u.IsActive; // Don't need a boolean for if statement, just example of local scope
			if(isActive) {
				activeUsers.add(currentUser);
				activeUserEmails.add(currentUser.Email);
			}else {
				inactiveUsers.add(u);
			}
		}
		// Initializing method variable mid-scope
		if(!activeUserEmails.isEmpty()) {
			persons = [SELECT  Id  FROM  Person__c  WHERE  Email__c  IN: activeUserEmails];
		}
	}
}
```

## Naming Conventions

Name should be as brief as possible while clearly indicating what the variable is and will be used for.

```java
/* Apex */
List<Deal_Support_Request__Share> shareUpserts = new List<Deal_Support_Request__Share>();
List<Deal_Support_Request__Share> shareDeletes = new List<Deal_Support_Request__Share>();
Set<Id> deleteShareDsrIds = new Set<Id>();
Set<Id> deleteShareUserIds = new Set<Id>();
```

```javascript
/* Javascript */
let _columnWidthsMode;
let _minColumnWidth;
let defaultSortColumn;
let showLockedIcon;
let hideReset;
let customLockMessage;
```

Single variable - abbreviated object noun, singular (with verb/preposition if warranted)
List - abbreviated object noun, plural (with verb/preposition if warranted)
Set - abbreviated object noun(s), plural (with verb/preposition if warranted)
Map - abbreviated noun to noun + Map, or object noun + Map when mapping record ids to records

```java
/* Apex */
Opportunity  newOpportunity;
List<Opportunity> newOpportunities;
String  email;
List<String> emails;
Set<Id> opportunityIds;
Map<Id, List<Opportunity_Team_Roles__c>> opportunityIdToRolesMap // I'm listing both nouns because I'm mapping different objects
Map<Id, Opportunity> opportunityMap // I'm listing one noun since I'm mapping record Id to record on same object
```

## Ternaries

Use ternaries instead of if/else for variable assignments with simple logic whenever possible.

```java
// Single ternary
String  message  = count > 100  ?  'More than 100'  :  'Less than or equal to 100';

// Nested ternary
String  message = count >= 100 ? count > 100 ? 'More than 100' : 'Equal to 100' : 'Less than 100';
```

# **SOQL**

**UPPERCASE all commands**

```java
List<User> activeUsers = [SELECT  Id, Name  FROM  User  WHERE  IsActive  = true AND Auto_Deactivated__c = false ORDER BY LastName];
```

**Multi-line:** Use a line for each command statement, and indent multi-line commands

```java
List<User> users  = [SELECT Id, Name, Alias, Email, Auto_Deactivated__c, IsActive, LastLoginDate, CreatedDate,LastModifiedDate, ProfileId, UserRoleId, FederationIdentifier
	FROM  User
	WHERE  LastLoginDate  < LAST_N_DAYS:30
	AND  IsActive  =  TRUE
	AND (Profile.Name  =  'JC Standard License'  OR  Profile.Name  =  'JC Platform License')
	AND  Id  NOT  IN  :whitelistIds
	AND  PO_Approver_Type__c  NOT  IN  :WHITELIST_PO_APPROVERS
	ORDER  BY LastName, FirstName  ASC
	LIMIT 5000];
```

**For Loops:** If SOQL statement is too long for one line, follow multi-line standard indented double

```java
// Single-line
for(User  currentUser : [SELECT Id, Name  FROM User]) {
	// For loop code here...
}

// Multi-line
for(User currentUser : [SELECT Id, Name, Alias, Email, Auto_Deactivated__c, IsActive, LastLoginDate, CreatedDate
	FROM  User
	WHERE  IsActive  =  TRUE
	ORDER  BY LastName, FirstName  ASC
]) {
	// For loop code here...
}
```

# **Triggers**

**Only declare triggers actually used.**

```java
trigger LogApiErrorTrigger on Log_API_Error__e (after insert) {
	if(Trigger.isInsert  &&  Trigger.isAfter) {
		LogAPIErrorHandler.onAfterInsert(Trigger.new);
	}
}
```

**Use newList, oldList, newMap, and oldMap as variable names in handlers/bl for trigger variables.**

```java
public  static  void  onBeforeInsert(List<Opportunity> newList) {}
public  static  void  onAfterUpdate(Map<Id, Opportunity newMap, Map<Id, Opportunity> oldMap) {}
```

**When available, use newMap/oldMap instead of newList/oldList to reduce declarations, and use values() to pass in lists to bl methods when needed.**

```java
public  static  void  onBeforeInsert(List<Opportunity> newList) {
	OpportunityBL.populateComplexityCategory(newList);
}
public  static  void  onAfterUpdate(Map<Id, Opportunity newMap, Map<Id, Opportunity> oldMap) {
	OpportunityBL.populateComplexityCategory(newMap.values()); // needs List
	OpportunityBL.doFieldUpdates(newMap, oldMap); // needs Maps
}
```

# **Apex Tests**

## Declaration

Declare test classes as private and name same as Apex class appended with "Test".

```java
@isTest
private  class CashOBDControllerTest{}
```

Declare testSetup before test methods.

```java
@isTest
private  class CashOBDControllerTest {
	@testSetup
	static  void  setup() {}
	@isTest
	static  void  getBillingTransactionsTest() {}
}
```

## Naming Conventions

<!-- TODO update description to put Test after method -->

Prefix test method names with "Test" and name after the method being tested or the general action when testing singular methods isn't possible or reasonable.

```java
// Testing single method
@isTest
static  void  getBillingTransactionsTest() {}

// Testing general actions
@isTest
static  void  createRolesTest() {}

@isTest
static  void  deleteRolesTest() {}
```

Use underscores in method name to separate cases from method/action.

```java
@isTest
static  void  getBillingTransactionsTest() {}

@isTest
static  void  getBillingTransactionsTest_internalServerError() {}

@isTest
static  void  getBillingTransactionsTest_exception() {}
```

## Assertions

Use assertEquals() when expecting a specific value and only use assert() on booleans or necessary evaluations because assertEquals() gives more information on failure than assert().

```java
// assertEquals() expecting specific values
System.assertEquals(500, errorResponse.statusCode);
System.assertEquals(UTIL_Cash.ERR_SOURCE_MULECP, errorResponse.errorSource);

// assert() expecting true evaluation of string containing a substring
System.assert(errorResponse.errorMessage.contains(UTIL_TestData.MULESOFT_ERROR_MSG));

//assert() expecting a Boolean field to be true
System.assert(testUser.IsActive);
```

## Comments

Comment test methods with brief explanation of what is being tested and specific case (if applicable).

```java
// Test Role Copies on new Opp Team Roles with active and inactive users
@isTest
static  void  createRolesTest() {}

// Test Role Copies on updated Opp Team Roles access/role with active and inactive users
@isTest
static  void  updateRolesTest_accessAndRole() {}

// Test Role Copies on updated Opp Team Roles person with active/inactive users
@isTest
static  void  updateRolesTest_person()
```

Comment related assertion blocks with brief explanation of what is being tested.

```java
// Assert that roles were updated only for active users and deleted for inactive users
System.assertEquals(1, qaRoles.size());
System.assertEquals(1, mfcRoles.size());
System.assertEquals(1, dsrRoles.size());
for(Team_Role__c  role  : qaRoles) {
	System.assert(role.Name__c  !=  userInactive.Id  &&  role.Name__c  !=  user2.Id
		&&  role.Name__c  ==  user1.Id);
	System.assert(role.QA_CDP_Plan_Access__c  == ROLE_ACCESS_NEW);
	System.assert(role.Role__c  == ROLE_NEW);
}
```

# **Comments & Documentation**

## Code Comments

Comment related blocks of code as briefly as possible to explain what the code is doing.

```java
// Validate sales credit for role isn't more than 100%
if(roleCreditMap.get(currentRole.Role__c) !=  null  &&  currentRole.Sales_Credit__c !=  null) {
	if((roleCreditMap.get(currentRole.Role__c) +  currentRole.Sales_Credit__c) >  100) {
		for(Opportunity_Team_Roles__c  newRole: newRoles){
			if(newRole.Opportunity_Name__c  ==  opp.Id){
				newRole.addError(cem.get(UTIL_Constants.ERROR_MSG_TEA_016).Error_Message__c);
			}
		}
	} else{
		roleCreditMap.put(currentRole.Role__c, (roleCreditMap.get(currentRole.Role__c) +  currentRole.Sales_Credit__c));
	}
}else {
	roleCreditMap.put(currentRole.Role__c, currentRole.Sales_Credit__c);
}
```

Comment related variable group declarations for organization and clarity.

```java
// Errors
public  static  final  String  ERR_SOURCE_MULECP  =  'Mulesoft/Costpoint';
public  static  final  String  ERR_SOURCE_SF  =  'Salesforce';
public  static  final  String  TIMEOUT_MSG  =  'Request timeout communicating with Costpoint.';
public  static  final  String  ERR_MSG_INVALID_CLIENT  =  'Invalid Client';
public  static  final  String  ERR_MSG_NOT_FOUND  =  'Not Found';
```

Comment single variable declarations for clarity when dealing with complex classes, lots of variables, or if variable name isn't obvious.

```java
/* Apex */
private  Boolean  requiresFull; // Requires full license?
private  Boolean  permissionsEmpty  =  true; // User deprovisioned?
private  Boolean  hasChatter  =  false; // Has chatter license?
```

```javascript
/* Javascript */
let inputTimeout; // timeout delay for input keyup event
let focusTimeout; // timeout delay for input lose focus event
```

## Apex Documentation

Follow [Javadoc](https://en.wikipedia.org/wiki/Javadoc) standards for class and method documentation.

### Class documentation

```java
/**
* Calculate Financial Summaries and update opps after line items inserted/updated/deleted
* @author Jane Doe
* @date 3/20/2015
* Updated 3/9/2021 by Jack Frost cleanup and document, remove OppLineItem BL to own class
*/
public class CalculateFinancialSummaryBL {
	// Code block
}
```

### Method Documentation

```java
/** Send For Review email
* @param  pl1 Project Level 1 record
* @param  recipients Email recipients addresses list
* @param  comments User entered email comments
* @return Success message or AuraHandledException
*/
@AuraEnabled
public  static  String  sendForReviewEmail(Project_Level_1__c pl1, List<String> recipients, String comments) {
	//Code block
}
```

## Javascript Documentation

Follow [JSDoc](https://jsdoc.app/) standards for class and method documentation.

### Class Documentation

Define all required/optional attributes, events fired/received, @api methods, and channel messages published/received.

```javascript
/**
* Datatable with sorting, filtering, row locking, cell change validation
* Uses extendedDatatable lwc for custom datatype support
* @author Kevin Long
* @date 4/20/2021
*
* <lightning-datatable> documentation: @url https://developer.salesforce.com/docs/component-library/bundle/lightning-datatable/specification
*
* REQUIRED ATTRIBUTES
* // rawData
* @param {Object[]} rawData Datatable compatible data array
* @param {boolean} rawData[].editable Set to false to make a row read only. Rows editable if not set
* @param {*} rawData[][keyField] Each row must have keyField set
*
* @param {string} keyField Column fieldName to use as key-field. Values must be unique.
* @param {string} tableHeaderTitle Card title
*
* OPTIONAL ATTRIBUTES
* @param {number} minColumnWidth Datatable min-column-width for 'auto' mode. Defaults to 100.
* @param {number|string} loadSize Number of rows to load initially and on scrolling load more. Defaults to 50
*
* EVENTS
* Notify parent of cell changes. Use to run validations, update formula fields, or other custom logic
* @event notifycellchange
* @type {Object}
* @property {Object[]} changes event.detail.draftValues
* @property {Object[]} updatedData this.updatedData
*
* API METHODS
* @see updateErrors - Update table errors by evaluating valid changes and errors.
* @see showValidationErrors - Display toast for validation errors.
*
* CHANNEL PUBLISHES
* @see Datatable_Custom_Change - Notifies custom datatype cmps of mass edit
```

### Method documentation

```javascript
/**
* Get formula field updates when variable fields updated
* @param {Object[]} changes Datatable event.detail.draftValues @see dynamicDatatable
* @param {Object[]} updatedData Datatable updatedData @see dynamicDatatable
* @returns {Object[]} changes for formula fields
*/
getFormulaFieldUpdates(changes, updatedData) {
	//Code block
}
```

# **HTML/CSS**

## HTML

If tag is too lengthy for one line, break into multiple lines and indent.

```html
<lightning-input
	name="filteredDataSearch"
	label="Search Table"
	variant="label-hidden"
	type="search"
	placeholder="Search this list.."
	value="{tableSearchInput}"
	oncommit="{handleTableSearchCommit}"
>
</lightning-input>
```

Comment blocks for clarity, using end block comments for large blocks.

```html
<!-- Actions -->
<div class="slds-col">
	<div class="slds-grid slds-gutters_xx-small slds-grid_vertical-align-center">
		<!-- Errors -->
		<template if:true="{errors}">
			<lightning-icon
				class="slds-col"
				icon-name="utility:error"
				alternative-text="Error!"
				variant="error"
				title="Table Errors"
				size="small"
			>
			</lightning-icon>
		</template>
		<!-- Search -->
		<template if:false="{isFilteredByErrors}">
			<div class="slds-col">
				<lightning-input
					name="filteredDataSearch"
					label="Search Table"
					variant="label-hidden"
					type="search"
					placeholder="Search this list.."
					value="{tableSearchInput}"
					oncommit="{handleTableSearchCommit}"
				>
				</lightning-input>
			</div>
		</template>
	</div>
</div>
<!-- /Actions -->
```

## CSS

Use [BEM](https://en.bem.info/methodology/quick-start) convention with dash-case: `block-block__element_modifier`.

```css
/* Datatable container div with fixed height to contain scrollable data-table */
.dynamic-datatable__table_medium {
	height: 298px;
}
.dynamic-datatable__table_small {
	height: 198px;
}
/** Card Footer */
.dynamic-datatable__footer {
	font-size: 1.1em;
}
```
