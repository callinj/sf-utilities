import { LightningElement, api, wire } from 'lwc';
import { showToast, isInBuilder, splitString, stripAllSpaces } from 'c/jcUtils';
import checkUserCanShare from '@salesforce/apex/JCPermissionUtils.checkUserCanShare';
import recordPermissionList from '@salesforce/apex/JCPermissionUtils.recordPermissionList';
import shareRecord from '@salesforce/apex/JCUtils.shareRecord';
import { refreshApex } from '@salesforce/apex';
const DEFAULT_CLASSES = 'jc-share-record-action';
const COLUMNS = ['sharedName', 'reasonLabel', 'level', 'whoName', 'sharedDatetime'];
const RESET_CLASS = 'reset-field';

export default class JcShareRecordAction extends LightningElement {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_shareItemResponse;
	_permissions;
	_showRecordId;
	_showDate = false;
	_showWhoShared = false;
	_showLevel = false;
	_showReason = false;
	_showForm = false;
	_sortOrder;
	_sortOrderString;
	_columns = [
		{
			label: 'Full Name',
			fieldName: 'sharedName',
			type: 'text',
			hideDefaultActions: true,
			fixedWidth: null
		}
	];

	// Private reactive properties
	// showForm = false;
	records;
	formLoaded = false;
	listLoaded = false;
	newUserId;

	get showForm() {
		return this._showForm;
	}
	set showForm(showForm) {
		this._showRecordId = this.recordId;
		this.formLoaded = !this.canShare;
		this._showForm = showForm;
	}

	get isLoaded() {
		return this.showForm && this.formLoaded;
	}

	get canShare() {
		return this._permissions?.hasShare || isInBuilder();
	}
	get columns() {
		return this._columns;
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

	@api get showReason() {
		return this._showReason;
	}
	set showReason(value) {
		this._showReason = value;
		if (value) {
			this._columns.push({
				label: 'Reason',
				fieldName: 'reasonLabel',
				type: 'text',
				hideDefaultActions: true,
				fixedWidth: null
			});
		}
	}
	@api get showLevel() {
		return this._showLevel;
	}
	set showLevel(value) {
		this._showLevel = value;
		if (value) {
			this._columns.push({
				label: 'Access Level',
				fieldName: 'level',
				type: 'text',
				hideDefaultActions: true,
				fixedWidth: null
			});
		}
	}
	@api get showWhoShared() {
		return this._showWhoShared;
	}
	set showWhoShared(value) {
		this._showWhoShared = value;
		if (value) {
			this._columns.push({
				label: 'Who Gave Access',
				fieldName: 'whoName',
				type: 'text',
				hideDefaultActions: true,
				fixedWidth: null
			});
		}
	}
	@api get showDate() {
		return this._showDate;
	}
	set showDate(value) {
		this._showDate = value;
		if (value) {
			this._columns.push({
				label: 'Access Date',
				fieldName: 'sharedDatetime',
				type: 'date',
				hideDefaultActions: true,
				fixedWidth: null,
				typeAttributes: {
					month: 'short',
					day: '2-digit',
					year: 'numeric'
				}
			});
		}
	}
	@api get sortOrder() {
		return this._sortOrder;
	}
	set sortOrder(value) {
		this._sortOrderString = stripAllSpaces(value);
		this._sortOrder = splitString(value, ',', 'trim');
	}

	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}
	@wire(recordPermissionList, { recordId: '$_showRecordId', customSortOrder: '$_sortOrder' })
	recordPermissionListMethod(response) {
		this._shareItemResponse = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this.records = data.results.map((result) => ({
					...result,
					sharedName: result.sharedWith.name,
					id: result.sharedWith.id,
					whoName: result.whoShared.name,
					reasonLabel: result.reason.label
				}));
			} else {
				data.messages.forEach((message) => {
					showToast('error', message, 'Error Message', true);
					console.error('Error Processing recordPermissionList data:', message);
				});
			}
			this.listLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing recordPermissionList: ', error);
		}
	}
	@wire(checkUserCanShare, { recordId: '$recordId', validLevel: 'Read', validReasons: '$_sortOrder' })
	recordPermissionsForUserMethod({ error, data }) {
		if (data) {
			if (data.success) {
				this._permissions = data.results[this.recordId];
			} else {
				showToast('error', data.messages[0], 'Error Message', true);
				console.error('Error Processing checkUserCanShare data:', data.messages[0]);
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing checkUserCanShare: ', error);
		}
	}
	connectedCallback() {
		// TODO fix short circuit chaining issues
		// this.classList.add(...this.customClasses?.split(' '));
		this._columns = this._columns.sort(
			(predecessor, successor) => COLUMNS.indexOf(predecessor.fieldName) - COLUMNS.indexOf(successor.fieldName)
		);
	}
	renderedCallback() {
		refreshApex(this._shareItemResponse);
	}
	closeModal = () => {
		this.showForm = false;
		this.formLoaded = false;
	};
	actionClick = () => {
		this.showForm = true;
	};
	handleLoad = () => {
		this.formLoaded = true;
	};

	submitForm = () => {
		this.template.querySelector('lightning-button.slds-hide').click();
	};

	handleSubmit = (event) => {
		event.preventDefault(); // stop the form from submitting
		shareRecord({ parentId: this.recordId, userId: this.newUserId })
			.then((data) => {
				if (data.success) {
					this.showForm = false;
					showToast('success', 'You have successfully shared this record.', 'Success', 'dismissable');
				} else {
					showToast('error', data.messages[0], 'Error Message', 'dismissable');
					console.error('Error Processing shareRecord: ', data.messages[0]);
				}
			})
			.catch((error) => {
				showToast('error', error, 'Error Message', 'dismissable');
				console.error('Error Processing shareRecord: ', error);
			})
			.finally(() => {
				this.formLoaded = true;
			});
	};
	handleUserSelect = (event) => {
		this.newUserId = event.detail.value[0];
	};
	handleSuccess = () => {
		this.resetFields();
	};
	resetFields = () => {
		const inputFields = this.template.querySelectorAll(`.${RESET_CLASS}`);
		if (inputFields) {
			inputFields.forEach((field) => {
				field.reset();
			});
		}
	};
}
