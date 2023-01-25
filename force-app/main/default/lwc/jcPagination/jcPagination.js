/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api } from 'lwc';
import { isEmpty } from 'c/jcUtils';

const DEFAULT_RESULT_OPTIONS = [5, 10, 25, 50];
const DEFAULT_PREVIOUS_BUTTON = 'Prev';
const DEFAULT_NEXT_BUTTON = 'Next';

export default class JcPagination extends LightningElement {
	// Private Properties
	_pageNumber = 1;
	_currentSelection = DEFAULT_RESULT_OPTIONS[0];
	_previousButton = DEFAULT_PREVIOUS_BUTTON;
	_nextButton = DEFAULT_NEXT_BUTTON;
	_variant = 'neutral';
	_direction;

	// Private Reactive Properties
	loaded = false;

	get totalPages() {
		return Math.ceil(this.totalItems / this.currentSelection);
	}
	get previousButtonDisabled() {
		return this.pageNumber === 1;
	}
	get nextButtonDisabled() {
		return this.pageNumber === this.totalPages || this.totalItems === 0;
	}
	get customResultOptions() {
		let options = !isEmpty(this.resultOptions) ? this.resultOptions.split(',') : DEFAULT_RESULT_OPTIONS;
		let results = [];
		options.forEach((item) => {
			results.push({
				value: parseInt(item, 10),
				label: item
			});
		});
		this._currentSelection = results?.some((option) => option.value === parseInt(this.currentSelection, 10))
			? parseInt(this.currentSelection, 10)
			: results[0].value;
		return results;
	}
	get disableResulOptions() {
		return this.customResultOptions?.length <= 1;
	}
	get pageOptions() {
		let options = [];
		for (let index = 1; index <= this.totalPages; index++) {
			options.push({
				value: index,
				label: index
			});
		}
		return options;
	}
	get pageOptionsDisabled() {
		return this.pageOptions?.length === 1;
	}
	get showPagination() {
		let isVisible = true;
		if (this.showPaginationCondition) {
			isVisible = this.totalItems > this.customResultOptions[0].value;
		}
		return isVisible;
	}
	get itemAlignment() {
		return this.disableResulOptions && this.disablePageSelection ? 'end' : 'spread';
	}

	// Public Properties
	@api totalItems;
	@api resultOptions;
	@api largeButtons;
	@api showPaginationCondition = false; // TODO | Refactor name
	@api disablePageSelection = false;

	@api get variant() {
		return this._variant;
	}
	set variant(variant) {
		this._variant = variant;
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
	@api get currentSelection() {
		return this._currentSelection;
	}
	set currentSelection(currentSelection) {
		if (currentSelection) {
			this._currentSelection = currentSelection;
		}
	}
	@api get pageNumber() {
		return this._pageNumber;
	}
	set pageNumber(value) {
		this._direction = value > this.pageNumber ? 'next' : 'previous';
		this._pageNumber = value;
		// this.sendEvent();
	}

	// Once the component is rendered, send the update event
	connectedCallback() {
		if (!this.loaded) {
			this.sendEvent();
			this.loaded = true;
			// console.log('totalItems', this.totalItems);
			// console.log('showPagCond', this.showPaginationCondition);
		}
	}
	// Sets the currentSelection to the value of the dropdown
	handleDropdownChange(event) {
		this.currentSelection = parseInt(event.target.value, 10);
		this.pageNumber = 1;
		this.sendEvent();
	}
	handlePageSelection = (event) => {
		this.pageNumber = parseInt(event.target.value, 10);
		this.sendEvent();
	};
	// Handles the previous functionality
	handlePrevious() {
		this.pageNumber--;
		this.sendEvent();
	}
	// Handles the next functionality
	handleNext() {
		this.pageNumber++;
		this.sendEvent();
	}
	// Sends the pageNumber and pageSize to the parent component
	sendEvent() {
		this.dispatchEvent(
			new CustomEvent('update', {
				detail: {
					pageNumber: this.pageNumber,
					pageSize: this.currentSelection,
					direction: this._direction,
					isFirst: this.previousButtonDisabled, // TODO | Refactor this.previousButtonDisabled to this.previousDisabled
					isLast: this.nextButtonDisabled // TODO | Refactor this.nextButtonDisabled to this.nextDisabled
				}
			})
		);
	}
}
