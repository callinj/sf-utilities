import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { showToast, isInBuilder } from 'c/jcUtils';
import { getRecord, getFieldValue, updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import recordPermissionsForUser from '@salesforce/apex/JCPermissionUtils.recordPermissionsForUser';
import getQueryObjectResults from '@salesforce/apex/JCQueryHelper.getQueryObjectResults';
import currentUserId from '@salesforce/user/Id';

const DEFAULT_CLASSES = 'jc-td-release-action';

export default class JcTdReleaseAction extends NavigationMixin(LightningElement) {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_cssVariables = {};
	_hasRecord = false;
	_permissions;
	_currentRecord;
	_updateRecordId;
	_fields = ['User.Id', 'User.People_Lead__c', 'User.FirstName'];
	get _isPeopleLead() {
		return getFieldValue(this.currentRecord, this._fields[1]) === currentUserId;
	}
	get _objectApiName() {
		// return this.currentRecordInfo?.data.objectName;
		return 'Feedback_Request__c';
	}
	get _canModify() {
		return this._permissions?.hasEdit;
	}
	// Private reactive properties

	get showAction() {
		return (this._hasRecord && this._isPeopleLead && this._canModify) || isInBuilder();
	}

	get currentRecord() {
		return this._currentRecord;
	}
	set currentRecord(value) {
		this._currentRecord = value;
	}
	get queryOptions() {
		let value = {
			objectName: 'Talent_Decision__c',
			fields: ['Id'],
			filters: [
				{ field: 'Employee__c', value: this.recordId },
				{ field: 'Finalized__c', value: false },
				{ field: 'MD__c', value: true },
				{ field: 'Effective_Date__c', value: 'THIS_FISCAL_YEAR' }
			]
			// querySorts: [{ field: 'CreatedDate', descending: true, nullsLast: true }]
		};
		return value;
	}

	// Public properties
	@api recordId;
	@api actionVariant;
	@api actionLabel;
	@api actionLeftIcon;
	@api actionRightIcon;
	@api actionAlign;
	@api actionFullWidth;
	@api actionOverSized;
	@api actionUnderline;
	@api actionBorderRadius;
	@api actionBorderThickness;
	@api actionCustomColor;
	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(value) {
		this._customClasses += value ? ` ${value}` : '';
	}
	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
	}
	renderedCallback() {
		// FIXME Accessing firstChild on this.template is unsafe
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
	}
	@wire(recordPermissionsForUser, { recordIds: '$_updateRecordId' })
	recordPermissionsForUserMethod({ error, data }) {
		if (data) {
			if (data.success) {
				this._permissions = data.results[this._updateRecordId];
			} else {
				showToast('error', data.message, 'Error Message', true);
				console.error('Error Processing recordPermissionsForUser data:', data.message);
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing recordPermissionsForUser: ', error);
		}
	}

	@wire(getRecord, { recordId: '$recordId', fields: '$_fields' })
	getRecordMethod({ error, data }) {
		if (data) {
			this._currentRecord = data;
			this.updateCurrentUser();
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getRecord: ', error);
		}
	}
	@wire(getQueryObjectResults, { queryOptions: '$queryOptions' })
	getQueryObjectResultsMethod(response) {
		this._queryResults = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this._hasRecord = data.results?.length > 0;
				this._updateRecordId = data?.results[0]?.Id;
			} else {
				data.messages.forEach((message) => {
					showToast('error', message, 'Error Message', true);
					console.error('Error Processing getQueryObjectResults data:', message);
				});
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getQueryObjectResults: ', error);
		}
	}
	actionClick = () => {
		const params = {
			fields: {
				Id: this._updateRecordId,
				Finalized__c: true
			}
		};
		updateRecord(params)
			.then(() => {
				showToast(
					'success',
					`You have released the Talent Decision for ${getFieldValue(this.currentRecord, this._fields[2])}`
				);
				refreshApex(this._queryResults);
				getRecordNotifyChange([{ recordId: this._updateRecordId }]);
			})
			.catch((error) => {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error('Error Processing methodName: ', error);
			});
	};
	updateCurrentUser = () => {
		let params = {
			fields: {
				Id: currentUserId,
				Viewing_Counselee__c: this._isPeopleLead
			}
		};
		updateRecord(params)
			.then(() => {
				getRecordNotifyChange([{ recordId: currentUserId }]);
			})
			.catch((error) => {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error('Error Processing methodName: ', error);
			});
	};
}
