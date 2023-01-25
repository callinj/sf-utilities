import { LightningElement, wire, api } from 'lwc';
import { showToast, proxyLog } from 'c/jcUtils';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getCounselees from '@salesforce/apex/JCCounseleeController.getCounselees';

const DEFAULT_CLASSES = 'jc-counselee-list';
const ZERO_STATE_MESSAGE = 'No Records Found';

export default class JcCounseleeList extends NavigationMixin(LightningElement) {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_cssVariables = {};
	_counseleeData;
	_pageSizeOptions;
	_columnWidthsMode;
	_previousButton;
	_nextButton;
	_showAsButtons;

	// Private reactive properties
	counselees = [];
	counseleeTotal = [];
	loaded = false;
	pageSize;
	pageNumber = 1;
	buttonVariant;

	get counseleeOptions() {
		let counseleeOptions = {
			objectName: 'User',
			fields: ['Id', 'Name'],
			queryLimit: this.pageSize,
			offset: (this.pageNumber - 1) * this.pageSize,
			filters: [
				{ field: 'People_Lead__c', value: userId, condition: 'AND', operator: '=' },
				{ field: 'IsActive', value: true, condition: 'AND', operator: '=' }
			]
		};
		return counseleeOptions;
	}
	get columns() {
		let columns = [
			{
				label: this.firstColumnHeader,
				fieldName: 'recordUrl',
				type: 'url',
				typeAttributes: {
					label: { fieldName: 'name' }
				},
				hideDefaultActions: true,
				fixedWidth: null
			}
		];
		if (this.columnWidth && this.columnWidthsMode === 'fixed') {
			columns.forEach((column) => {
				column.fixedWidth = this.columnWidth;
			});
		}
		return columns;
	}
	get hasResults() {
		return this.counselees.length > 0;
	}

	// Public properties
	@api columnWidth;
	@api firstColumnHeader;
	@api showCheckboxes = false;
	@api showRowNumbers = false;
	@api showTableHeader = false;
	@api enableColumnResizing = false;
	@api enablePaginationFeature = false;
	@api largeButtons = false;

	@api get pageSizeOptions() {
		return this._pageSizeOptions;
	}
	set pageSizeOptions(value) {
		if (value) {
			this._pageSizeOptions = value;
			this.pageSize = parseInt(value?.split(',')[0], 10);
		}
	}
	@api get columnWidthsMode() {
		return this._columnWidthsMode;
	}
	set columnWidthsMode(value) {
		this._columnWidthsMode = value.toLowerCase();
	}
	@api get previousButton() {
		return this._previousButton;
	}
	set previousButton(value) {
		this._previousButton = value;
	}
	@api get nextButton() {
		return this._nextButton;
	}
	set nextButton(value) {
		this._nextButton = value;
	}
	@api get showAsButtons() {
		return this._showAsButtons;
	}
	set showAsButtons(value) {
		this._showAsButtons = value;
		if (this._showAsButtons) {
			this.buttonVariant = 'brand-outline';
		}
	}
	@api get zeroStateMessage() {
		return this._zeroStateMessage;
	}
	set zeroStateMessage(zeroStateMessage) {
		this._zeroStateMessage = zeroStateMessage ? zeroStateMessage : ZERO_STATE_MESSAGE;
	}
	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(value) {
		this._customClasses += value ? ` ${value}` : '';
	}

	@wire(getCounselees, { searchOptions: '$counseleeOptions' })
	wireGetCounselees(response) {
		this._counseleeData = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this.counselees = data.results;
				this.counseleeTotal = data.totalResults;
				proxyLog('data === ', this.counselees);
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissible');
				console.error('Error Processing Data', data.messages[0]);
			}
			this.loaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissible');
			console.error('Error Processing getMyGoals', error.body.message);
			this.loaded = true;
		}
	}
	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
	}
	renderedCallback() {
		// FIXME figure out how to set css variables properly
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
		refreshApex(this._counseleeData);
	}
	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};
}
