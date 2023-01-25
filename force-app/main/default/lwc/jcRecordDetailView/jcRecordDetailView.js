import { LightningElement, api, wire } from 'lwc';
import { showToast, isEmpty, splitString, columnSizes } from 'c/jcUtils';
import { getRecord } from 'lightning/uiRecordApi';

const DEFAULT_CLASSES = 'jc-record-detail-view';

export default class JcRecordDetailView extends LightningElement {
	// Private Properties
	_customClasses = DEFAULT_CLASSES;
	_customFields = [];
	_sections = [];
	_fieldsMap = new Map();

	// Private Reactive Properties
	loaded = false;

	get hasCustomFields() {
		return this._customFields.length > 0;
	}
	get hasSections() {
		return this.sections?.length > 0 && !this.hasCustomFields;
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
						fieldInfo.key = currentSection.key + sectionRow.key + apiName;
						fieldInfo.apiName = apiName;
						fieldInfo.layoutClass = apiName === null ? 'slds-show_medium' : '';

						if (this.hideEmptyFields) {
							if (this.isFieldPopulated(apiName)) {
								sectionRow.fields.push(fieldInfo);
							}
						} else {
							sectionRow.fields.push(fieldInfo);
						}
					});
					currentSection.rows.push(sectionRow);
				});
				sectionsHolder.push(currentSection);
			});
		}
		this._sections = sectionsHolder;
	}
	get fields() {
		return this._fields;
	}
	set fields(value) {
		let fields = [];
		value.forEach((field) => {
			if (this.hideEmptyFields) {
				if (this.isFieldPopulated(field)) {
					fields.push(field);
				}
			} else {
				fields.push(field);
			}
		});
		this._fields = fields;
		// return this._fields;
	}

	// Public Properties
	@api recordId;
	@api objectName;
	@api hideEmptyFields = false;

	@api get customFields() {
		return this._customFields;
	}
	set customFields(customFields) {
		if (!isEmpty(customFields)) {
			if (typeof customFields == 'string') {
				customFields = splitString(customFields, ',', 'strip');
			}
			this._customFields = customFields;
			this.fields = this.customFields;
		}
	}
	@api get columns() {
		return this._columns;
	}
	set columns(columns) {
		this._columns = columnSizes(columns);
	}
	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}

	@wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
	getCurrentObjectNameMethod({ error, data }) {
		if (data) {
			if (isEmpty(this.objectName)) {
				// eslint-disable-next-line @lwc/lwc/no-api-reassignments
				this.objectName = data.apiName;
			}
			this._fieldsMap = data.fields;
			this.fields = this.customFields;
		} else if (error) {
			if (error.body.statusCode !== 404) {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error(`Error Processing ${this.objectName} getRecordUi: `, error);
			}
		}
	}

	connectedCallback() {
		this.classList.add(...this._customClasses.split(' '));
	}
	handleLoad = () => {
		this.loaded = true;
		this.dispatchEvent(new CustomEvent('load'));
	};
	isFieldPopulated = (field) => {
		return this._fieldsMap[field] && this._fieldsMap[field].value;
	};
}
