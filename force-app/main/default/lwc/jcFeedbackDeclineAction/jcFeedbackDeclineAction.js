import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { showToast, isInBuilder } from 'c/jcUtils';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import recordPermissionsForUser from '@salesforce/apex/JCPermissionUtils.recordPermissionsForUser';
import currentUserId from '@salesforce/user/Id';
const DEFAULT_CLASSES = 'jc-feedback-decline-action';

export default class JCFeedbackDeclineAction extends NavigationMixin(LightningElement) {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_fields = [`${this._objectApiName}.Reviewer__c`];
	_permissions;
	_currentRecord;
	get _canModify() {
		return this._permissions?.hasEdit;
	}
	get _isReviewer() {
		return getFieldValue(this.currentRecord, this._fields[0]) === currentUserId;
	}
	get _objectApiName() {
		// return this.currentRecordInfo?.data.objectName;
		return 'Feedback_Request__c';
	}

	// Private reactive properties
	get showAction() {
		return (this._canModify && this._isReviewer) || isInBuilder;
	}

	get currentRecord() {
		return this._currentRecord;
	}
	set currentRecord(currentRecord) {
		this._currentRecord = currentRecord;
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
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}
	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
	}
	@wire(recordPermissionsForUser, { recordIds: '$recordId' })
	recordPermissionsForUserMethod({ error, data }) {
		if (data) {
			if (data.success) {
				this._permissions = data.results[this.recordId];
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
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getRecord: ', error);
		}
	}
	actionClick = () => {
		const params = {
			fields: {
				Id: this.recordId,
				Responded__c: true
			}
		};
		updateRecord(params)
			.then(() => {
				showToast('success', 'Your response has been recorded');
				this.goHome();
			})
			.catch((error) => {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error('Error Processing methodName: ', error);
			});
	};
	goHome = () => {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'Home'
			}
		});
	};
}
