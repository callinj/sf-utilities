import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getMyGoals from '@salesforce/apex/JCGoalController.getGoals';

import { showToast } from 'c/jcUtils';

const ZERO_STATE_MESSAGE = 'No Records Found';

export default class JcGoalList extends LightningElement {
	// Private Properties
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_goalItems;
	_pageSizeOptions;
	_previousButton = 'Prev';
	_nextButton = 'Next';
	_showAsButtons;
	_columnWidthsMode = 'auto';

	// Private Reactive Properties
	goals = [];
	goalTotal;
	isLoaded = false;
	pageNumber = 1;
	pageSize;
	buttonVariant;

	get goalOptions() {
		let goalOptions = {
			objectName: 'Goal__c',
			fields: ['Id', 'Name', 'Status__c', 'CreatedDate', 'Target_Completion_Date__c'],
			queryLimit: this.pageSize,
			offset: (this.pageNumber - 1) * this.pageSize,
			filters: [
				{ field: 'CreatedById', value: userId, condition: 'AND', operator: '=' }
				// { field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' }
			]
		};
		return goalOptions;
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
			},
			{
				label: this.secondColumnHeader,
				fieldName: 'status',
				type: 'string',
				hideDefaultActions: true,
				fixedWidth: null
			},
			{
				label: this.thirdColumnHeader,
				fieldName: 'targetCompletionDate',
				type: 'date-local',
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
		return this.goals.length > 0;
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

	@wire(getMyGoals, { searchOptions: '$goalOptions' })
	wireGetMyGoals(response) {
		this._goalItems = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this.goals = data.results;
				this.goalTotal = data.totalResults;
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissible');
				console.error('Error Processing Data', data.messages[0]);
			}
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissible');
			console.error('Error Processing getMyGoals', error.body.message);
			this.isLoaded = true;
		}
	}

	renderedCallback() {
		refreshApex(this._goalItems);
	}

	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};
}
