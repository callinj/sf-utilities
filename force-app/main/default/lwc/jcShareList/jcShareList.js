import { LightningElement, api, wire, track } from 'lwc';
import getSharedWithMe from '@salesforce/apex/JCFeedbackController.getSharedWithMe';
import userId from '@salesforce/user/Id';
import { showToast } from 'c/jcUtils';
import { refreshApex } from '@salesforce/apex';

const ZERO_STATE_MESSAGE = 'No Records Found';

export default class JcShareList extends LightningElement {
	// Private Properties
	@track _feedbackOptions;
	@track _prioritiesOptions;

	_listItems;
	_pageSizeOptions;
	_previousButton = 'Prev';
	_nextButton = 'Next';
	_showAsButtons = false;
	_columnWidthsMode = 'auto';
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_direction;
	_oldFeedbackOffset = 0;
	_oldPriorityOffset = 0;
	_isLast = false;
	_feedbackOffset = 0;
	_priorityOffset = 0;

	get _feedbackSearchOptions() {
		let offset = 0;
		let filterGroups = this._filterGroups;
		filterGroups[0].filters.push({
			field: 'RowCause',
			value: 'Share_With_Provider__c',
			condition: 'OR',
			operator: '='
		});

		if ((this.showTopPagination || this.showBottomPagination) && this.pageNumber !== 1) {
			offset =
				this._direction === 'next'
					? this._oldFeedbackOffset + this._feedbackOffset
					: this._oldFeedbackOffset - this._feedbackOffset;
			offset = offset < 0 ? 0 : offset;
		}

		let searchOptions = {
			objectName: 'Feedback__Share',
			fields: ['Id', 'ParentId', 'Parent.Title__c', 'LastModifiedDate'],
			queryLimit: this.pageSize,
			offset: offset,
			filters: this._filters,
			filterGroups: filterGroups,
			querySorts: this._querySorts
		};
		return searchOptions;
	}
	get _prioritySearchOptions() {
		let offset = 0;
		let filterGroups = this._filterGroups;
		filterGroups[0].filters.push({
			field: 'RowCause',
			value: 'Share_record_with_receiver__c',
			condition: 'OR',
			operator: '='
		});

		if ((this.showTopPagination || this.showBottomPagination) && this.pageNumber !== 1) {
			offset =
				this._direction === 'next'
					? this._oldPriorityOffset + this._priorityOffset
					: this._oldPriorityOffset - this._priorityOffset;
			offset = offset < 0 ? 0 : offset;
		}

		let searchOptions = {
			objectName: 'Goal__Share',
			fields: ['Id', 'ParentId', 'Parent.Title__c', 'Parent.Name', 'LastModifiedDate'],
			queryLimit: this.pageSize,
			offset: offset,
			filters: this._filters,
			filterGroups: filterGroups,
			querySorts: this._querySorts
		};
		return searchOptions;
	}
	get _filters() {
		return [
			{ field: 'UserOrGroupId', value: userId, condition: 'AND', operator: '=' }
			// { field: 'LastModifiedDate', value: 'THIS_FISCAL_YEAR', condition: 'AND', operator: '=' },
			// { field: 'RowCause', value: 'Manual', condition: 'AND', operator: '=' },
			// { field: 'RowCause', value: 'Share_With_Provider__c', condition: 'AND', operator: '=' }
		];
	}
	get _filterGroups() {
		return [
			{
				condition: 'AND',
				filters: [{ field: 'RowCause', value: 'Manual', condition: 'OR', operator: '=' }]
			}
		];
	}
	get _querySorts() {
		return [{ field: 'LastModifiedDate', descending: true, nullsLast: true }];
	}

	// Private Reactive Properties
	records = [];
	recordsTotal;
	isLoaded = false;
	pageNumber = 1;
	pageSize;
	buttonVariant;

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
				initialWidth: 150
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
		return this.records.length > 0;
	}
	get showTopPagination() {
		return this.paginationLocation === 'Top' || this.paginationLocation === 'Both';
	}
	get showBottomPagination() {
		return this.paginationLocation === 'Bottom' || this.paginationLocation === 'Both';
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
	@api paginationLocation;

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

	@wire(getSharedWithMe, { feedbackOptions: '$_feedbackOptions', goalOptions: '$_prioritiesOptions' })
	wireSharedWithMe(response) {
		this._listItems = response;
		const { data, error } = response;
		if (data) {
			if (data.success) {
				this.records = data.results;
				this.recordsTotal = data.totalResults;

				this._oldFeedbackOffset = this._feedbackSearchOptions?.offset;
				this._oldPriorityOffset = this._prioritySearchOptions?.offset;

				if (!this._isLast) {
					this._feedbackOffset = data.offsets?.Feedback__Share ? data.offsets?.Feedback__Share : 0;
					this._priorityOffset = data.offsets?.Goal__Share ? data.offsets?.Goal__Share : 0;
				}
			} else {
				showToast('error', data.message, 'Error Message', 'dismissable');
				console.error('Error Processing getSharedGoals', data.message);
			}
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getSharedGoals', error.body.message);
			this.isLoaded = true;
		}
	}

	connectedCallback() {
		this.updateOptions();
	}

	renderedCallback() {
		refreshApex(this._listItems);
	}

	updateOptions = () => {
		this._feedbackOptions = this._feedbackSearchOptions;
		this._prioritiesOptions = this._prioritySearchOptions;
	};

	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
		this._direction = eventDetails.direction;
		this._isLast = eventDetails.isLast;
		this.updateOptions();
	};
}
