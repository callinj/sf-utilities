import { LightningElement, api, wire } from 'lwc';
import { showToast, splitString, isEmpty } from 'c/jcUtils';
import { getRecord } from 'lightning/uiRecordApi';

const DEFAULT_CLASSES = 'jc-talent-decision-detail';
const DEFAULT_FIELDS = ['Effective_Date__c', 'Decision__c', 'Performance_Period__c', 'Rewards__c'];

export default class JcTalentDecisionDetail extends LightningElement {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_cssVariables = {};
	_fieldsMap = new Map();
	_customFields = DEFAULT_FIELDS;
	_finalized;

	// Private reactive properties
	fields;

	get objectName() {
		return 'Talent_Decision__c';
	}

	// Public properties
	@api recordId;
	// @api objectName;
	@api hideEmptyFields = false;
	@api columns;

	@api get customFields() {
		return this._customFields;
	}
	set customFields(value) {
		let valueList = splitString(value, ',', 'strip');
		if (valueList.at(-1) === 'Finalized__c') {
			this._finalized = valueList.pop();
		}
		this._customFields = valueList;
	}
	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(value) {
		this._customClasses += value ? ` ${value}` : '';
	}

	@wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
	getCurrentObjectNameMethod({ error, data }) {
		if (data) {
			this._fieldsMap = data.fields;
			this.setFields();
		} else if (error) {
			if (error.body.statusCode !== 404) {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error(`Error Processing getRecord: `, error);
			}
		}
	}
	setFields = () => {
		let fields = new Set(this.customFields);

		if (
			this._fieldsMap?.Equity__c?.value?.toLowerCase() !== 'no award' &&
			this._fieldsMap?.Equity__c?.value?.toLowerCase() !== 'no'
		) {
			fields.add('Equity__c');
		}

		if (!isEmpty(this._finalized)) {
			fields.add(this._finalized);
		}
		this.fields = Array.from(fields).toString();
	};

	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
	}
	renderedCallback() {
		// FIXME figure out how to do css variables
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
	}
}
