import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { showToast, isEmpty, splitString, columnSizes } from 'c/jcUtils';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecordCreateDefaults, getRecord, getFieldValue, deleteRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import assignFilesToRecord from '@salesforce/apex/JCFilesController.assignFilesToRecord';

const DEFAULT_CLASSES = 'jc-record-detail-upsert';
const DEFAULT_RECORDTYPE_LABEL = 'Master';
const RESET_CLASS = 'reset-field';

const CURRENT_USER_KEY = 'CurrentUser';
const BEGIN_KEY = '{>';
const END_KEY = '}';
const FIELD_KEY = '[a-zA-Z0-9_]+';
const OBJECT_KEY = `(${FIELD_KEY}\\.)`;
const FIELD_REGEX = new RegExp(`${BEGIN_KEY}${OBJECT_KEY}+(${FIELD_KEY})${END_KEY}`, 'g');
const USER_REGEX = new RegExp(`${BEGIN_KEY}${CURRENT_USER_KEY}\\.${OBJECT_KEY}*(${FIELD_KEY})${END_KEY}`, 'g');
const USER_REPLACE_REGEX = new RegExp(`${CURRENT_USER_KEY}`, 'g');
const REPLACE_REGEX = new RegExp(`${OBJECT_KEY}`, 'g');
const EXPRESSION_REGEX = new RegExp(`${BEGIN_KEY}|${END_KEY}`, 'g');

export default class JcRecordDetailUpsert extends NavigationMixin(LightningElement) {
	// TODO add ability to hide and show action if user does not have acess to current record
	// TODO add ability to pull accepted file types from org/community
	// TODO add functionality to allow for accepted file types to be set on individual basis
	// TODO add ability to open record in edit mode
	// TODO hookup borderRadius
	// BUG some times the sections load a second copy after submitting form
	// BUG look into loading state clunkiness
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_userId = USER_ID;
	_recordId;
	_layoutType = 'Compact';
	_currentObjectName;
	_canModify = false;
	_recordsChecked = false;
	_objectInfo;
	_recordTypeId;
	_actionType;
	_newRecord;
	_disabledFields = [];
	_sections = [];
	_formTitle = 'New Record';
	_successMessage = 'The record has been submitted successfully';
	_defaultsMap = new Map();
	_fieldMapping = new Map();
	_fieldLists = new Map();
	_userFields;
	_recordFields;
	_uploadedFileIds;
	_objectFieldCount = 0;

	// Private reactive properties
	loaded = false;

	get recordsChecked() {
		return this._recordsChecked;
	}
	set recordsChecked(value) {
		if (value && (this._recordsChecked || isEmpty(this.recordId))) {
			if (!isEmpty(this.defaultValues)) {
				this.setFieldMappings();
			} else {
				this._currentObjectName = this.objectName;
			}
		}
		this._recordsChecked = value;
	}
	get hasSections() {
		return this.sections?.length > 0;
	}
	get sections() {
		return this._sections;
	}
	set sections(sections) {
		let sectionsHolder = [];
		if (!isEmpty(sections)) {
			sections?.forEach((section, sectionIndex) => {
				let currentSection = {
					key: 'section' + sectionIndex,
					heading: section.useHeading ? section.heading : null,
					columns: columnSizes(section.columns),
					class: sectionIndex !== 0 && section.useHeading ? 'slds-var-m-top_medium' : '',
					rows: []
				};
				section.layoutRows.forEach((row, rowIndex) => {
					let sectionRow = {
						key: currentSection.key + 'Row' + rowIndex,
						fields: []
					};
					row.layoutItems.forEach((item) => {
						const apiName = item.layoutComponents[0].apiName;
						let fieldInfo = {};
						let fieldValue = null;
						if (this._defaultsMap.has(apiName)) {
							fieldValue = this._defaultsMap.get(apiName);
							this._defaultsMap.delete(apiName);
						}
						fieldInfo.key = currentSection.key + sectionRow.key + apiName;
						fieldInfo.apiName = apiName;
						fieldInfo.required = item.required;
						fieldInfo.disabled = this.disabledFields.indexOf(apiName) !== -1;
						fieldInfo.layoutClass = apiName === null ? 'slds-show_medium' : '';
						fieldInfo.fieldClass = fieldValue == null ? RESET_CLASS : '';
						if (!isEmpty(fieldValue)) {
							fieldInfo.value = fieldValue;
						}
						sectionRow.fields.push(fieldInfo);
					});
					currentSection.rows.push(sectionRow);
				});
				sectionsHolder.push(currentSection);
			});
		}
		this._sections = sectionsHolder;
	}

	// Public properties
	@api objectName;
	@api enableUpload = false;
	@api defaultValues;
	@api recordTypeLabel;
	@api formTitle = 'New Record';
	@api formDescription;
	@api disableRedirect = false;
	@api hideEmptyFields = false;

	@api get recordId() {
		return this._recordId;
	}
	set recordId(value) {
		this._recordId = value;
	}
	@api get customFields() {
		return this._customFields;
	}
	set customFields(customFields) {
		if (!isEmpty(customFields)) {
			this._customFields = splitString(customFields, ',', 'strip');
		}
	}
	@api get disabledFields() {
		return this._disabledFields;
	}
	set disabledFields(disabledFields) {
		if (!isEmpty(disabledFields)) {
			this._disabledFields = splitString(disabledFields, ',', 'strip');
		}
	}
	@api get columns() {
		return this._columns;
	}
	set columns(columns) {
		this._columns = columnSizes(columns);
	}
	@api get successMessage() {
		return this._successMessage;
	}
	set successMessage(successMessage) {
		this._successMessage = successMessage;
	}
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
			this._recordTypeId = currentType.recordTypeId;
			if (currentType.available) {
				this._canModify = this.recordId ? data?.updateable : data?.createable;
			}
			this.recordsChecked = this._canModify;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error(`Error Processing ${this.objectName} getObjectInfo: `, error);
		}
	}
	@wire(getRecord, { recordId: '$recordId', layoutTypes: '$_layoutType' })
	getCurrentObjectNameMethod({ error, data }) {
		if (data) {
			this.recordsChecked = true;
		} else if (error) {
			if (error.body.statusCode !== 404) {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error(`Error Processing ${this.objectName} getRecordUi: `, error);
			}
		}
	}
	@wire(getRecordCreateDefaults, { objectApiName: '$_currentObjectName', recordTypeId: '$_recordTypeId' })
	getRecordCreateDefaultsMethod({ error, data }) {
		if (data) {
			this.sections = data.layout.sections;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error(`Error Processing ${this.objectName} getRecordCreateDefaults: `, error);
		}
	}
	@wire(getRecord, { recordId: '$recordId', optionalFields: '$_recordFields' })
	getCurrentRecordMethod({ error, data }) {
		if (data) {
			this.setFieldValues(this._recordFields, data);
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error(`Error Processing ${this.objectName} getRecord: `, error);
		}
	}
	@wire(getRecord, { recordId: '$_userId', optionalFields: '$_userFields' })
	getUserRecordMethod({ error, data }) {
		if (data) {
			this.setFieldValues(this._userFields, data);
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error(`Error Processing ${this.objectName} getRecord: `, error);
		}
	}
	connectedCallback() {
		this.classList.add(...this._customClasses.split(' '));
	}
	disconnectedCallback() {
		this.deleteUploadedFiles();
	}
	@api
	submitForm = (event) => {
		this._actionType = event.target.dataset.name;
		this.template.querySelector('lightning-button.slds-hide').click();
	};
	handleSubmit = (event) => {
		this.loaded = false;
		const fields = event.detail.fields;
		event.preventDefault(); // stop the form from submitting

		fields.RecordTypeId = this._recordTypeId;
		this._defaultsMap.forEach((value, key) => {
			fields[key] = value;
		});
		this.template.querySelector('lightning-record-edit-form').submit(fields);
	};
	handleSuccess = (event) => {
		this._newRecord = event.detail.id;
		if (!isEmpty(this._uploadedFileIds)) {
			assignFilesToRecord({
				fileIds: this._uploadedFileIds,
				recordId: this._newRecord
			})
				.then((data) => {
					if (data.success) {
						this._uploadedFileIds = null;
						this.handleComplete();
					} else {
						showToast('error', data.messages[0], 'Error Message', 'dismissable');
						console.error('Error Processing assignFilesToRecord: ', data.messages[0]);
					}
				})
				.catch((error) => {
					showToast('error', error.body.message, 'Error Message', 'dismissable');
					console.error('Error Processing assignFilesToRecord: ', error);
				});
		} else {
			this.handleComplete();
		}
	};
	handleError = (event) => {
		const eventDetails = event.detail;
		let errors = [];
		if (!isEmpty(eventDetails.detail)) {
			errors.push(eventDetails.detail);
		} else if (!isEmpty(eventDetails.output?.errors)) {
			errors = eventDetails.output?.errors;
		} else if (!isEmpty(eventDetails.output?.fieldErrors)) {
			const fieldErrors = eventDetails.output?.fieldErrors;
			for (const field in fieldErrors) {
				if (Object.prototype.hasOwnProperty.call(fieldErrors, field)) {
					fieldErrors[field].forEach((error) => {
						errors.push(error.message);
					});
				}
			}
		} else {
			errors.push(event.detail.message);
		}
		errors.forEach((errorMessage) => {
			showToast('error', errorMessage);
			console.error(`Error Processing ${this.recordTypeLabel} ${this.objectName} form: `, errorMessage);
		});
		this.loaded = true;
	};
	handleComplete = () => {
		showToast('success', this.successMessage);
		if (this._actionType === 'save') {
			if (!this.disableRedirect) {
				this.goToRecord();
			} else {
				this.loaded = false;
			}
			this.dispatchEvent(new CustomEvent('close'));
		} else {
			this.resetFields();
			this.loaded = true;
		}
	};
	closeModal = () => {
		this.loaded = false;
		this.deleteUploadedFiles();
	};
	handleLoad = () => {
		this.loaded = true;
		this.dispatchEvent(new CustomEvent('load'));
	};
	resetFields() {
		const inputFields = this.template.querySelectorAll(`.${RESET_CLASS}`);
		if (inputFields) {
			inputFields.forEach((field) => {
				field.reset();
			});
		}
	}
	handleUploadFinished(event) {
		if (!isEmpty(this._uploadedFileIds)) {
			this._uploadedFileIds.push(...event.detail.files.map((file) => file.documentId));
		} else {
			this._uploadedFileIds = event.detail.files.map((file) => file.documentId);
		}
	}

	deleteUploadedFiles() {
		if (!isEmpty(this._uploadedFileIds)) {
			Promise.all(this._uploadedFileIds.map((id) => deleteRecord(id)))
				.then(() => {
					showToast('success', 'Files have successfully been removed');
					this._uploadedFileIds = null;
				})
				.catch((error) => {
					showToast('error', error.body.message);
					console.error(`Error Processing deleteRecord: `, error.body.message);
				});
		}
	}
	goToRecord = () => {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this._newRecord,
				actionName: 'view'
			}
		});
	};
	setFieldValues = (fieldList, data) => {
		fieldList?.forEach((currentField) => {
			this._fieldMapping.get(currentField).forEach((mappedField) => {
				this._defaultsMap.set(mappedField, getFieldValue(data, currentField));
				this._objectFieldCount--;
			});
		});
		if (this._objectFieldCount === 0) {
			this._currentObjectName = this.objectName;
		}
	};

	setFieldMappings = () => {
		let values = splitString(this.defaultValues, ',', 'trim');
		let userFields = [];
		let recordFields = [];
		values?.forEach((string) => {
			const fieldString = splitString(string, ':', 'trim');
			let fieldName = fieldString[0];
			let fieldValue = fieldString[1];
			let isReference = false;
			this._defaultsMap.set(fieldName, fieldValue);
			if (fieldValue?.match(USER_REGEX)) {
				this._objectFieldCount++;
				isReference = true;
				fieldValue = fieldValue.replace(USER_REPLACE_REGEX, 'User').replace(EXPRESSION_REGEX, '');
				if (!userFields.includes(fieldValue)) {
					userFields.push(fieldValue);
				}
			} else if (fieldValue?.match(FIELD_REGEX)) {
				this._objectFieldCount++;
				isReference = true;
				fieldValue = fieldValue.replace(REPLACE_REGEX, `${this.objectName}.`).replace(EXPRESSION_REGEX, '');
				if (!recordFields.includes(fieldValue)) {
					recordFields.push(fieldValue);
				}
			}
			if (isReference) {
				if (!this._fieldMapping.has(fieldValue)) {
					this._fieldMapping.set(fieldValue, [fieldName]);
				} else {
					let fields = this._fieldMapping.get(fieldValue);
					fields.push(fieldName);
					this._fieldMapping.set(fieldValue, fields);
				}
			}
		});
		if (this._canModify) {
			this._userFields = userFields;
			this._recordFields = recordFields;
		}
	};
}
