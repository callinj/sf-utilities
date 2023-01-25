import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getMyPendingFeedbackRequests from '@salesforce/apex/JCFeedbackController.pendingRequests';

import { showToast } from 'c/jcUtils';

const ZERO_STATE_MESSAGE = 'No Records Found';

export default class DataTableTestPending extends LightningElement {
	// Private Properties
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_feedbackItems;
	_pageSizeOptions;
	_previousButton = 'Prev';
	_nextButton = 'Next';
	_showAsButtons;

	// Private Reactive Properties
	pageNumber = 1;
	pageSize;
	totalResults;
	data;
	isLoaded = false;

	//Public Properties
	columns = [
		{
			label: 'Description',
			fieldName: 'recordUrl',
			type: 'url',
			typeAttributes: {
				label: { fieldName: 'information' }
			},
			hideDefaultActions: true
		},
		{
			label: 'Created Date',
			fieldName: 'createdDate',
			type: 'date',
			hideDefaultActions: true
		}
	];

	get hasResults() {
		return this.data?.length > 0;
	}

	@api largeButtons = false;
	@api showPaginationCondition;

	@api get hideCheckboxColumn() {
		return this.checkboxValue;
	}

	set hideCheckboxColumn(value) {
		this.checkboxValue = value;
	}

	@api get hideRowNumberColumn() {
		return this.rowNumValue;
	}

	set hideRowNumberColumn(value) {
		this.rowNumValue = !value;
	}

	@api get columnWidthsMode() {
		return this.colWidthValue;
	}

	set columnWidthsMode(value) {
		this.colWidthValue = value;
	}

	@api get resizeColumns() {
		return this.resizeValue;
	}

	set resizeColumns(value) {
		this.resizeValue = value;
	}

	@api get hideColumnHeader() {
		return this.colHeaderValue;
	}

	set hideColumnHeader(value) {
		this.colHeaderValue = value;
	}

	@api get zeroStateMessage() {
		return this._zeroStateMessage;
	}

	set zeroStateMessage(value) {
		this._zeroStateMessage = value ? value : ZERO_STATE_MESSAGE;
	}

	@api get pageSizeOptions() {
		return this._pageSizeOptions;
	}

	set pageSizeOptions(pageSizeOptions) {
		if (pageSizeOptions) {
			this._pageSizeOptions = pageSizeOptions;
			this.pageSize = parseInt(pageSizeOptions?.split(',')[0], 10);
		}
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
		this._showAsButtons = showAsButtons ? 'brand-outline' : '';
	}

	get feedbackOptions() {
		let feedbackOptions = {
			objectName: 'Feedback_Request__c',
			fields: ['Id', 'Name', 'Requester__r.Name', 'Reviewer__r.Name', 'RequestText__c', 'CreatedDate'],
			queryLimit: this.pageSize,
			offset: (this.pageNumber - 1) * this.pageSize,
			filters: [
				{ field: 'Reviewer__c', value: userId, condition: 'AND', operator: '=' },
				{ field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
				{ field: 'Responded__c', value: false, condition: 'AND', operator: '=' }
			]
		};

		return feedbackOptions;
	}

	@wire(getMyPendingFeedbackRequests, { searchOptions: '$feedbackOptions' })
	wireMyPendingFeedbackRequests(response) {
		this._feedbackItems = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this.data = data.results;
				this.totalResults = data.totalResults;
				//console.log('PENDING data.results ==>', data.results);
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissible');
				console.error('Error Processing Data', data.messages[0]);
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissible');
			console.error('Error Processing getMyPendingFeedbackRequests', error.body.message);
		}
		this.isLoaded = true;
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
