import { LightningElement, api } from 'lwc';

const DEFAULT_CLASSES = 'jc-record-detail';

export default class JcRecordDetail extends LightningElement {
	// Private properties
	_customClasses = DEFAULT_CLASSES;

	// Private reactive properties

	// Public properties
	@api recordId;
	@api objectName;
	@api enableUpload = false;
	@api defaultValues;
	@api recordTypeLabel;
	@api disableRedirect = false;
	@api isEditMode = false;
	@api hideActions = false;
	@api hideEmptyFields = false;
	@api hideEmptySpaces = false;
	@api customFields;
	@api columns;
	@api disabledFields;
	@api successMessage;

	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}

	connectedCallback() {
		this.classList.add(...this._customClasses.split(' '));
	}
	@api
	submitForm = (event) => {
		this.template.querySelector('c-jc-record-detail-upsert').submitForm(event);
	};
	handleLoad = () => {
		this.dispatchEvent(new CustomEvent('load'));
	};
	handleClose = () => {
		this.dispatchEvent(new CustomEvent('close'));
	};
}
