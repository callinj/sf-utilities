import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getMyPendingFeedbackRequests from '@salesforce/apex/JCFeedbackController.pendingRequests';

import { showToast } from 'c/jcUtils';

const ZERO_STATE_MESSAGE = 'No Records Found';

export default class JCRequestList extends LightningElement {
	// Private Properties
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_feedbackItems;
	_pageSizeOptions;
	_previousButton = 'Prev';
	_nextButton = 'Next';
	_showAsButtons;
	_columnWidthsMode = 'auto';

	// Private Reactive Properties
	requests = [];
	requestTotal;
	isLoaded = false;
	pageNumber = 1;
	pageSize;
	buttonVariant;

	get feedbackOptions() {
		let feedbackOptions = {
			objectName: 'Feedback_Request__c',
			fields: ['Id', 'Name', 'Requester__r.Name', 'Reviewer__r.Name', 'RequestText__c', 'CreatedDate'],
			queryLimit: this.pageSize,
			offset: (this.pageNumber - 1) * this.pageSize,
			filters: [
				{ field: 'Reviewer__c', value: userId, condition: 'AND', operator: '=' },
				// { field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
				{ field: 'Responded__c', value: false, condition: 'AND', operator: '=' }
			]
		};

		return feedbackOptions;
	}

	get columns() {
		let columns = [
			{
				label: this.firstColumnHeader,
				fieldName: 'recordUrl',
				type: 'url',
				typeAttributes: {
					label: { fieldName: 'information' }
				},
				hideDefaultActions: true,
				fixedWidth: null
			},
			{
				label: this.secondColumnHeader,
				fieldName: 'createdDate',
				type: 'date',
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
		return this.requests.length > 0;
	}

	//Public Properties
	@api columnWidth;
	@api firstColumnHeader;
	@api secondColumnHeader;
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

	@wire(getMyPendingFeedbackRequests, { searchOptions: '$feedbackOptions' })
	wireMyPendingFeedbackRequests(response) {
		this._feedbackItems = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this.requests = data.results;
				this.requestTotal = data.totalResults;
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissible');
				console.error('Error Processing Data', data.messages[0]);
			}
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissible');
			console.error('Error Processing getMyPendingFeedbackRequests', error.body.message);
			this.isLoaded = true;
		}
	}
	renderedCallback() {
		refreshApex(this._feedbackItems);
	}

	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};
}
