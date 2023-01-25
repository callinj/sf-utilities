import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { isInBuilder, showToast } from 'c/jcUtils';

const DEFAULT_CLASSES = 'jc-record-form-action';
const DEFAULT_RECORDTYPE_LABEL = 'Master';

export default class JcRecordFormAction extends LightningElement {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_objectInfo;
	_canModify = false;

	// Private reactive properties
	showForm = false;
	formLoaded = false;

	get actionsDisabled() {
		return !this.formLoaded;
	}
	get showAction() {
		return this._canModify || isInBuilder();
	}

	// Public properties
	@api recordId;
	@api objectApiName; // TODO | Remove
	@api actionVariant;
	@api actionLabel;
	@api objectName;
	@api enableUpload = false;
	@api displaySaveNew = false;
	@api actionLeftIcon;
	@api actionRightIcon;
	@api actionAlign;
	@api actionFullWidth;
	@api actionOverSized;
	@api actionUnderline;
	@api actionBorderRadius;
	@api actionBorderThickness;
	@api actionCustomColor;
	@api defaultValues;
	@api recordTypeLabel;
	@api formTitle = 'New Record';
	@api formDescription;
	@api disableRedirect = false;
	@api disabledFields;
	@api successMessage;
	@api isEditMode = false;

	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}

	@wire(getObjectInfo, { objectApiName: '$objectName' })
	getObjectInfoMethod({ error, data }) {
		if (data) {
			this._objectInfo = data;
			const recordTypes = data.recordTypeInfos;
			let currentType = Object.values(recordTypes).find(
				(recordType) => recordType.name === this.recordTypeLabel?.trim()
			);
			if (!currentType) {
				currentType = Object.values(recordTypes).find(
					(recordType) => recordType.name === DEFAULT_RECORDTYPE_LABEL
				);
			}
			if (currentType.available) {
				this._canModify = this.recordId ? data?.updateable : data?.createable;
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error(`Error Processing ${this.objectName} getObjectInfo: `, error);
		}
	}

	connectedCallback() {
		this.classList.add(...this._customClasses.split(' '));
	}
	actionClick = () => {
		this.showForm = true;
	};
	submitForm = (event) => {
		this.template.querySelector('c-jc-record-detail').submitForm(event);
	};
	handleLoad = () => {
		this.formLoaded = true;
	};
	handleClose = () => {
		this.showForm = false;
	};
}
