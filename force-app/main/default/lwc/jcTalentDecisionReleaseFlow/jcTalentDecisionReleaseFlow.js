/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, wire } from 'lwc';
import { showToast, isEmpty } from 'c/jcUtils';
import getUniquePerformancePeriods from '@salesforce/apex/JCRosterController.getUniquePerformancePeriods';
import getRosters from '@salesforce/apex/JCRosterController.getRosters';
import { refreshApex } from '@salesforce/apex';

const DEFAULT_CLASSES = 'jc-talent-decision-release-flow';

export default class JcTalentDecisionReleaseFlow extends LightningElement {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_cssVariables = {};
	_performancePeriodOptions = [];
	_rosters = [];
	_performanceData;
	_rosterData;

	// Private reactive properties
	loaded = false;

	get rosterOptions() {
		let rosterOptions = {
			objectName: 'Roster__c',
			fields: ['Id', 'Name', 'isReleased__c', 'isPublic__c', 'Performance_Period__c'],
			filters: [
				{ field: 'RecordType.DeveloperName', value: 'Talent_Decision', condition: 'AND', operator: '=' },
				{
					field: 'Performance_Period__c',
					value: this.currentPerformancePeriod,
					condition: 'AND',
					operator: '='
				}
			],
			querySorts: [{ field: 'Name', descending: true, nullsLast: true }]
		};
		return rosterOptions;
	}
	get performancePeriodOptions() {
		return this._performancePeriodOptions;
	}
	set performancePeriodOptions(value) {
		let periods = [];
		if (!isEmpty(value)) {
			value.forEach((item) => {
				periods.push({
					label: item,
					value: item
				});
			});
		}
		this._performancePeriodOptions = periods;
		// TODO fix reassignment of public variable
		this.currentPerformancePeriod = periods[0].value;
		this.loaded = true;
	}
	get rosters() {
		return this._rosters;
	}
	set rosters(value) {
		let rosters = [];
		if (!isEmpty(value)) {
			value.forEach((item) => {
				let tempName = item.name.replaceAll(item.performancePeriod, '').trim();
				if (this.isRelease) {
					rosters.push({ label: tempName, name: item.id, disabled: item.isReleased });
				} else {
					rosters.push({ label: tempName, name: item.id, disabled: !item.isReleased });
				}
			});
		}
		this._rosters = rosters;
	}

	// Public properties
	@api helpText;
	@api rostersToUpdate;
	@api currentPerformancePeriod;
	@api showErrorToast = false;
	@api isRelease = false;

	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(value) {
		this._customClasses += value ? ` ${value}` : '';
	}

	@wire(getUniquePerformancePeriods)
	wireGetUniquePerformancePeriods(results) {
		this._performanceData = results;
		const { error, data } = results;
		if (data) {
			this.performancePeriodOptions = data;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getUniquePerformancePeriods: ', error);
		}
	}
	@wire(getRosters, { searchOptions: '$rosterOptions' })
	wireGetRosters(results) {
		this._rosterData = results;
		const { error, data } = results;
		if (data) {
			this.refreshInputs();
			this.rosters = data.results;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getUserGroupOptions: ', error);
		}
	}

	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
	}
	renderedCallback() {
		// TODO fix how to do css variables
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
		refreshApex(this._performanceData);
		refreshApex(this._rosterData);

		if (this.showErrorToast) {
			showToast('error', 'Please specify a user group', 'Error Message', 'dismissable');
		}
	}
	handleChange = (event) => {
		this.currentPerformancePeriod = event.detail.value;
	};
	refreshInputs = () => {
		let elements = this.template.querySelectorAll('lightning-input');
		elements.forEach((element) => {
			element.checked = false;
		});
	};
	handleCheckboxChange = () => {
		// Empty current rosters
		this.rostersToUpdate = [];
		// TODO rework this to be proper
		// eslint-disable-next-line array-callback-return, no-unused-vars
		const checked = Array.from(this.template.querySelectorAll('lightning-input')).filter((element) => {
			if (element.checked) {
				this.rostersToUpdate.push(element.name);
			}
		});
	};
}
