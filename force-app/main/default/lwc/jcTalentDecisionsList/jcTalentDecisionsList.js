import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getTalentDecisions from '@salesforce/apex/JCTalentDecisionController.getTalentDecisions';
import { showToast } from 'c/jcUtils';

const ZERO_STATE_MESSAGE = 'No Records Found';
const DEFAULT_FIELDS = ['Id', 'Performance_Period__c', 'Decision__c', 'Effective_Date__c'];

export default class JcTalentDecisionsList extends LightningElement {
	// Private Properties
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_talentDecisionItems;
	_pageSizeOptions;
	_previousButton = 'Prev';
	_nextButton = 'Next';
	_showAsButtons;
	_columnWidthsMode = 'auto';

	// Private Reactive Properties
	talentDecisions = [];
	talentDecisionTotal;
	isLoaded = false;
	pageNumber = 1;
	pageSize;
	buttonVariant;

	get talentDecisionOptions() {
		let talentDecisionOptions = {
			objectName: 'Talent_Decision__c',
			fields: DEFAULT_FIELDS,
			queryLimit: this.pageSize,
			offset: (this.pageNumber - 1) * this.pageSize,
			filters: [
				{ field: 'Employee__c', value: userId, condition: 'AND', operator: '=' },
				{ field: 'Finalized__c', value: true, condition: 'AND', operator: '=' }
			],
			querySorts: [{ field: 'CreatedDate', descending: true, nullsLast: true }]
		};
		return talentDecisionOptions;
	}

	get columns() {
		let columns = [
			{
				label: this.firstColumnHeader,
				fieldName: 'recordUrl',
				type: 'url',
				typeAttributes: {
					label: { fieldName: 'period' }
				},
				hideDefaultActions: true,
				fixedWidth: null
			},
			{
				label: this.secondColumnHeader,
				fieldName: 'effectiveDate',
				type: 'date-local',
				hideDefaultActions: true,
				fixedWidth: null
			},
			{
				label: this.thirdColumnHeader,
				fieldName: 'decision',
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
		return this.talentDecisions.length > 0;
	}

	// Public Properties
	@api columnWidth;
	@api firstColumnHeader;
	@api secondColumnHeader;
	@api thirdColumnHeader;
	@api showCheckboxes = false;
	@api showRowNumbers = false;
	@api showTableHeader = false;
	@api enableColumnResizing = false;
	@api enablePaginationFeature = false;
	@api largeButtons = false;

	@api get pageSizeOptions() {
		return this._pageSizeOptions;
	}
	set pageSizeOptions(pageSizeOptions) {
		if (pageSizeOptions) {
			this._pageSizeOptions = pageSizeOptions;
			this.pageSize = parseInt(pageSizeOptions?.split(',')[0], 10);
		}
	}
	@api get columnWidthsMode() {
		return this._columnWidthsMode;
	}
	set columnWidthsMode(columnWidthsMode) {
		this._columnWidthsMode = columnWidthsMode.toLowerCase();
	}
	@api get previousButton() {
		return this._previousButton;
	}
	set previousButton(previousButton) {
		this._previousButton = previousButton;
	}
	@api get nextButton() {
		return this._nextButton;
	}
	set nextButton(nextButton) {
		this._nextButton = nextButton;
	}
	@api get showAsButtons() {
		return this._showAsButtons;
	}
	set showAsButtons(showAsButtons) {
		this._showAsButtons = showAsButtons;
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

	@wire(getTalentDecisions, { searchOptions: '$talentDecisionOptions' })
	wireGetTalentDecisions(response) {
		this._talentDecisionItems = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this.talentDecisions = data.results;
				this.talentDecisionTotal = data.totalResults;
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissible');
				console.error('Error Processing Data', data.messages[0]);
			}
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissible');
			console.error('Error Processing getTalentDecisions', error.body.message);
			this.isLoaded = true;
		}
	}

	renderedCallback() {
		refreshApex(this._talentDecisionItems);
	}

	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};
}
