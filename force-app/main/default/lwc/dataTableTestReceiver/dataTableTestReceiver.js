import { LightningElement, wire, api } from 'lwc';
import getFeedbackItems from '@salesforce/apex/JCFeedbackController.getFeedbackItems';
import userId from '@salesforce/user/Id';
import { showToast } from 'c/jcUtils';

const ZERO_STATE_MESSAGE = 'No Records Found';

export default class DataTableTestReceiver extends LightningElement {
	// Private Properties
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_listType;
	_pageSizeOptions;
	_previousButton = 'Prev';
	_nextButton = 'Next';
	_showAsButtons;

	// Private Reactive Propertie
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
				label: { fieldName: 'name' }
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

	@api get listType() {
		return this._listType;
	}

	set listType(value) {
		this._listType = value.toLowerCase();
	}

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
		let queryLimit = this.pageSize;
		let offset = (this.pageNumber - 1) * this.pageSize;
		let feedbackOptions = {
			objectName: 'Feedback__c',
			fields: ['Id', 'Title__c', 'InteractionDate__c', 'Provider__r.Name', 'Receiver__r.Name', 'CreatedDate'],
			queryLimit: queryLimit,
			offset: offset
		};
		let filters = [];
		let querySorts = [];

		switch (this.listType) {
			case 'provided':
				filters.push(
					{ field: 'Provider__c', value: userId, condition: 'AND', operator: '=' },
					{ field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
					{ field: 'RecordType.DeveloperName', value: 'Self', condition: 'AND', operator: '!=' }
				);
				break;

			case 'feedback':
				filters.push(
					{ field: 'Receiver__c', value: userId, condition: 'AND', operator: '=' },
					{ field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
					{ field: 'RecordType.DeveloperName', value: 'Feedback', condition: 'AND', operator: '=' }
				);
				break;

			case 'conversations':
				filters.push(
					{ field: 'Receiver__c', value: userId, condition: 'AND', operator: '=' },
					{ field: 'InteractionDate__c', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
					{ field: 'RecordType.DeveloperName', value: 'Conversation', condition: 'AND', operator: '=' }
				);
				querySorts.push({ field: 'InteractionDate__c', descending: true, nullsLast: true });
				break;

			case 'self':
				filters.push(
					{ field: 'CreatedById', value: userId, condition: 'AND', operator: '=' },
					{ field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
					{ field: 'RecordType.DeveloperName', value: 'Self', condition: 'AND', operator: '=' }
				);
				querySorts.push({ field: 'CreatedDate', descending: true, nullsLast: true });
				break;

			default:
				break;
		}

		feedbackOptions.filters = filters;

		if (querySorts.length > 0) {
			feedbackOptions.querySorts = querySorts;
		}
		return feedbackOptions;
	}

	@wire(getFeedbackItems, { searchOptions: '$feedbackOptions' })
	wireFeedbackItems({ error, data }) {
		if (data) {
			if (data.success) {
				this.data = data.results;
				this.totalResults = data.totalResults;
				//console.log('data.results ==>', data.results);
			} else {
				showToast('error', data.message, 'Error Message', 'dismissable');
				console.error('Error Processing getFeedbackItems', data.message);
			}
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getFeedbackItems', 'error.body.message');
			this.isLoaded = true;
		}
	}

	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};
}
