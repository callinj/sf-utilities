import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getFeedbackItems from '@salesforce/apex/JCFeedbackController.getFeedbackItems';
import userId from '@salesforce/user/Id';
import { showToast } from 'c/jcUtils';

const ZERO_STATE_MESSAGE = 'No Records Found';

export default class JCFeedbackList extends LightningElement {
	// Private Properties
	_feedbackData;
	_listType;
	_pageSizeOptions;
	_previousButton = 'Prev';
	_nextButton = 'Next';
	_showAsButtons = false;
	_showModal = true;
	_columnWidthsMode = 'auto';
	_zeroStateMessage = ZERO_STATE_MESSAGE;

	// Private Reactive Properties
	feedbacks = [];
	feedbackTotal;
	isLoaded = false;
	pageNumber = 1;
	pageSize;
	buttonVariant;

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
					// { field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
					{ field: 'RecordType.DeveloperName', value: 'Self', condition: 'AND', operator: '!=' }
				);
				break;
			case 'feedback':
				filters.push(
					{ field: 'Receiver__c', value: userId, condition: 'AND', operator: '=' },
					// { field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
					{ field: 'RecordType.DeveloperName', value: 'Feedback', condition: 'AND', operator: '=' }
				);
				querySorts.push({ field: 'CreatedDate', descending: true, nullsLast: true });
				break;
			case 'conversations':
				filters.push(
					{ field: 'Receiver__c', value: userId, condition: 'AND', operator: '=' },
					// { field: 'InteractionDate__c', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
					{ field: 'RecordType.DeveloperName', value: 'Conversation', condition: 'AND', operator: '=' }
				);
				querySorts.push({ field: 'InteractionDate__c', descending: true, nullsLast: true });
				break;
			case 'self':
				filters.push(
					{ field: 'CreatedById', value: userId, condition: 'AND', operator: '=' },
					// { field: 'CreatedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
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
		return this.feedbacks.length > 0;
	}

	// Public Properties
	@api columnWidth;
	@api firstColumnHeader;
	@api secondColumnHeader;
	@api showCheckboxes = false;
	@api showRowNumbers = false;
	@api showTableHeader = false;
	@api enableColumnResizing = false;
	@api enablePaginationFeature = false;
	@api largeButtons = false;

	@api get listType() {
		return this._listType;
	}
	set listType(listType) {
		this._listType = listType.toLowerCase();
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

	@wire(getFeedbackItems, { searchOptions: '$feedbackOptions' })
	wireFeedbackItems(response) {
		this._feedbackData = response;
		const { error, data } = response;
		if (data) {
			if (data.success) {
				this.feedbacks = data.results;
				this.feedbackTotal = data.totalResults;
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissable');
				console.error('Error Processing getFeedbackItems', data.messages[0]);
			}
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getFeedbackItems', error.body.message);
			this.isLoaded = true;
		}
	}

	renderedCallback() {
		refreshApex(this._feedbackData);
	}

	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};
}
