import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { showToast, splitString } from 'c/jcUtils';
import getTabSetting from '@salesforce/apex/JCRelatedTabsController.getTabSetting';
import getListItems from '@salesforce/apex/JCRelatedTabsController.getListItems';
import { loadStyle } from 'lightning/platformResourceLoader';
import JCRelatedTabsStyles from '@salesforce/resourceUrl/JCRelatedTabsStyles';
const DEFAULT_CLASS = 'jcRelatedTabs';
const METADATA_FIELDS = [
	'JCRelatedTabsSetting__mdt.MasterLabel',
	'JCRelatedTabsSetting__mdt.List_Title__c',
	'JCRelatedTabsSetting__mdt.Filter_Values__c',
	'JCRelatedTabsSetting__mdt.Icon_Field__c',
	'JCRelatedTabsSetting__mdt.Reference_Field__c',
	'JCRelatedTabsSetting__mdt.Related_Object__c',
	'JCRelatedTabsSetting__mdt.Scrollable__c',
	'JCRelatedTabsSetting__mdt.Show_Percentage__c',
	'JCRelatedTabsSetting__mdt.Filter_Field__c',
	'JCRelatedTabsSetting__mdt.Success_Icon__c',
	'JCRelatedTabsSetting__mdt.Label_Field__c',
	'JCRelatedTabsSetting__mdt.Warning_Icon__c'
];

export default class JCRelatedTabs extends LightningElement {
	// Private properties
	_customClass;
	_totalSuccess = 0;
	_scrollable = false;
	get _fieldString() {
		return [this.iconField, this.labelField].filter(Boolean).join(',');
	}
	get _settings() {
		return this.settings && this.settings.length > 0;
	}

	// Private reactive properties
	tabSetting;
	variant;
	items;
	settings;
	tabList;
	selectedFilter = '';
	get loaded() {
		return this.settings != null && this.tabList != null;
	}
	get filterList() {
		let list;
		if (this.tabSetting && this.tabSetting.Filter_Values__c.value) {
			let filterValues = this.tabSetting.Filter_Values__c.value;
			if (typeof filterValues === 'string') {
				list = [
					{
						label: 'Show All',
						value: ''
					}
				];
				splitString(filterValues, ',').forEach((value) => {
					list.push({
						label: value,
						value: value
					});
				});
			} else if (Array.isArray(filterValues) && filterValues.length > 0) {
				if (filterValues[0].label && filterValues[0].value) {
					list = filterValues;
				}
			} else {
				console.error(
					'This is an issue with the the filter list. Filter list should be a comma separated string or in the format oulined here: https://developer.salesforce.com/docs/component-library/bundle/lightning-combobox/example'
				);
			}
			// this.filterList = list;
		}
		return list;
	}
	get displayTabs() {
		return this.tabList.length > 0;
	}
	get validConfig() {
		let display = false;
		if (this.settings) {
			display = this.settings.length > 0;
		}
		return display;
	}
	get successStats() {
		if (this.tabList) {
			return {
				totalItems: this.tabList.length,
				totalSuccess: this._totalSuccess,
				successPercentage:
					this.tabList.length > 0 ? Math.round((this._totalSuccess / this.tabList.length) * 100) : 0
			};
		}
		return null;
	}
	get showPercentage() {
		if (this._settings) {
			return this.tabSetting.Show_Percentage__c.value;
		}
		return false;
	}
	get scrollable() {
		return this._scrollable;
	}
	set scrollable(scrollable) {
		this.classList.toggle('tabScroll', scrollable);
		this._scrollable = Boolean(scrollable);
	}
	get listTitle() {
		return this.tabSetting.List_Title__c.value;
	}
	get relatedObject() {
		if (this.tabSetting) {
			return this.tabSetting.Related_Object__c.value;
		}
		return null;
	}
	get referenceField() {
		if (this.tabSetting) {
			return this.tabSetting.Reference_Field__c.value;
		}
		return null;
	}
	get labelField() {
		if (this.tabSetting) {
			return this.tabSetting.Label_Field__c.value;
		}
		return null;
	}
	get filterField() {
		if (this.tabSetting) {
			return this.tabSetting.Filter_Field__c.value;
		}
		return null;
	}
	get iconField() {
		if (this.tabSetting) {
			return this.tabSetting.Icon_Field__c.value;
		}
		return null;
	}
	get iconSuccessValue() {
		if (this.tabSetting) {
			return this.tabSetting.Success_Icon__c.value;
		}
		return null;
	}
	get iconWarningValue() {
		if (this.tabSetting) {
			return this.tabSetting.Warning_Icon__c.value;
		}
		return null;
	}
	// Public properties
	@api recordId;
	@api customSetting;
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	@wire(getRecord, { recordId: '$customSetting', fields: METADATA_FIELDS })
	wireTabSettings({ error, data }) {
		if (data) {
			this.tabSetting = data.fields;
			this.scrollable = this.tabSetting.Scrollable__c.value;
		} else if (error) {
			showToast('error', error, 'Error Message', 'dismissable');
			console.error('Error Processing Tab Settings getRecord: ', error);
		}
	}
	@wire(getTabSetting, { tabSetting: '$tabSetting.MasterLabel.value' })
	wireRelatedSettings({ error, data }) {
		if (data) {
			this.settings = data;
			this.getItems();
		} else if (error) {
			showToast('error', error, 'Error Message', 'dismissable');
			console.error('Error Processing getTabSetting ', error);
		}
	}
	connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
		Promise.all([loadStyle(this, JCRelatedTabsStyles)]);
	}
	getItems = () => {
		let params = {
			recordId: this.recordId,
			relatedObject: this.relatedObject,
			referenceField: this.referenceField,
			fieldsString: this._fieldString,
			orderField: this.labelField,
			filterField: this.filterField,
			selectedFilter: this.selectedFilter
		};
		getListItems({ queryParams: params })
			.then((data) => {
				this._totalSuccess = 0;
				this.setList(data);
			})
			.catch((error) => {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error('Error Processing getListItems: ', error);
			});
	};
	tabActivated = (event) => {
		const activatedEvent = new CustomEvent('activated', { detail: event.target.value });
		this.dispatchEvent(activatedEvent);
	};
	setList = (data) => {
		let list = [];
		let iconFieldArray = splitString(this.iconField, '.', true);
		data.forEach((relatedItem) => {
			let iconValue = relatedItem;
			iconFieldArray?.forEach((prop) => {
				iconValue = iconValue?.[prop];
			});
			list.push({
				id: relatedItem.Id,
				title: relatedItem?.[this.labelField],
				label: relatedItem?.[this.labelField],
				icon: this.setIcon(iconValue)
			});
		});
		this.tabList = list;
	};
	setIcon = (value) => {
		let icon;
		if (value === this.iconSuccessValue) {
			icon = 'utility:success';
			this._totalSuccess++;
		} else if (value === this.iconWarningValue) {
			icon = 'utility:warning';
		}
		return icon;
	};
	filterChange = (event) => {
		this.selectedFilter = event.target.value;
		this.getItems();
	};
	handleSlotChange = (event) => {
		event.target.parentElement.classList.remove('slds-hide');
	};
}
