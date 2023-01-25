import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import JCRecordDetailStyles from '@salesforce/resourceUrl/JCRecordDetailStyles';
import { showToast, splitString } from 'c/jcUtils';

const DEFAULT_CLASS = 'recordDetails';
const RELATIVE_CLASS = 'slds-is-relative';
const ACCORDION_NAME = 'recordDetails';
const METADATA_FIELDS = [
	'JCRecordDetailSetting__mdt.Section_Title__c',
	'JCRecordDetailSetting__mdt.Fields__c',
	'JCRecordDetailSetting__mdt.Page_Layout__c',
	'JCRecordDetailSetting__mdt.Accordion__c',
	'JCRecordDetailSetting__mdt.Default_Open__c',
	'JCRecordDetailSetting__mdt.Columns__c'
];

export default class JCRecordDetails extends LightningElement {
	// Private properties
	_customClass;
	_settingLoaded = false;
	// _useCustomSetting = false;
	_title;
	_layout;
	_open;
	_accordion;
	_columns = 2;
	_fields;
	_metaTitle;
	_metaLayout;
	_metaAccordion;
	_metaOpen;
	_metaColumns;
	_metaFields;
	get _openAccordion() {
		return this._useCustomSetting ? this._metaOpen : this._open;
	}
	get _useCustomSetting() {
		return this.customSetting !== 'None' && this.customSetting != null;
	}
	get _apiLoaded() {
		return this.wireRecord.data != null;
	}
	get _metaLoaded() {
		return this._useCustomSetting ? this._settingLoaded : true;
	}

	// Private reactive properties
	accordionName = ACCORDION_NAME;
	get openAccordion() {
		return this._openAccordion ? ACCORDION_NAME : null;
	}
	get columns() {
		console.log('columns = ', this._metaColumns ? this._metaColumns : this._columns);
		return this._metaColumns ? this._metaColumns : this._columns;
	}
	get title() {
		return this._metaTitle ? this._metaTitle : this._title;
	}
	get objectApiName() {
		return this.wireRecord.data.apiName;
	}
	get recordTypeId() {
		return this.wireRecord.data.recordTypeId;
	}
	get objectFields() {
		return this._metaFields ? this._metaFields : this._fields;
	}
	get layout() {
		return this._metaLayout ? this._metaLayout : this._layout;
	}
	get showAccordion() {
		if (this.title) {
			return this._metaAccordion ? this._metaAccordion : this._accordion;
		}
		return false;
	}
	get noSelection() {
		return !this.layout && !this.showCustomForm && this.loaded;
	}
	get showCustomForm() {
		return !this.layout && this.objectFields && this.objectFields?.length > 0 && this.loaded;
	}
	get loaded() {
		return this._apiLoaded && this._metaLoaded;
	}

	// Public properties
	@api recordId;
	@api customSetting = 'None';
	@api flexipageRegionWidth;
	@api get pageLayout() {
		return this.layout;
	}
	@api get sectionColumns() {
		return this._columns;
	}
	set sectionColumns(sectionColumns) {
		this._columns = sectionColumns;
	}
	set pageLayout(pageLayout) {
		if (pageLayout.toLowerCase() === 'full' || pageLayout.toLowerCase() === 'compact') {
			this._layout = pageLayout;
		}
	}
	@api get sectionTitle() {
		return this._title;
	}
	set sectionTitle(sectionTitle) {
		this._title = sectionTitle;
	}
	@api get sectionAccordion() {
		return this._accordion;
	}
	set sectionAccordion(sectionAccordion) {
		this._accordion = sectionAccordion;
	}
	@api get fieldString() {
		return this.objectFields;
	}
	set fieldString(fieldString) {
		this._fields = splitString(fieldString, ',', 'trim');
	}
	@api get openDefault() {
		return this._openAccordion;
	}
	set openDefault(openDefault) {
		this._open = openDefault;
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	renderedCallback() {
		Promise.all([loadStyle(this, JCRecordDetailStyles)]);
	}
	connectedCallback() {
		// this.loadTest = true;
		this.classList.add(DEFAULT_CLASS, RELATIVE_CLASS);
	}

	@wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
	wireRecord;

	@wire(getRecord, { recordId: '$customSetting', fields: METADATA_FIELDS })
	metadata({ error, data }) {
		this._settingLoaded = true;
		console.log('test');
		if (data) {
			this._metaTitle = data.fields.Section_Title__c.value;
			this._metaAccordion = data.fields.Accordion__c.value;
			this._metaColumns = data.fields.Columns__c.value;
			this._metaOpen = data.fields.Default_Open__c.value;
			this._metaFields = splitString(data.fields.Fields__c.value, ',', true);
			if (
				data.fields.Page_Layout__c.value.toLowerCase() === 'full' ||
				data.fields.Page_Layout__c.value.toLowerCase() === 'compact'
			) {
				this._metaLayout = data.fields.Page_Layout__c.value;
			}
		} else if (error) {
			showToast('error', error.body, 'Error Message', 'dismissable');
			console.error('Error Processing getRecord: ', error);
		}
	}
}
