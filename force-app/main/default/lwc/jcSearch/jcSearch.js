import { LightningElement, api, wire, track } from 'lwc';
import { isEmpty, showToast, splitString, columnSizes } from 'c/jcUtils';
import { publish, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';
import getTopics from '@salesforce/apex/JCTopicController.getTopics';
import COMMUNITY_ID from '@salesforce/community/Id';

const DEFAULT_CLASS = 'brandedSearch';
const PLACEHOLDER = 'Search...';
const DROPDOWN_PLACEHOLDER = '-- Select --';
const REGEX_QUOTE = /[^\s"']+|"([^"]*)"|'([^']*)'/g;
const DEFAULT_SEARCH_FIELD = ['Name'];

export default class JcSearch extends LightningElement {
	// Private Properties
	_customClass;
	_searchFields = DEFAULT_SEARCH_FIELD;
	_placeholder = PLACEHOLDER;
	_dropdownPlaceholder = DROPDOWN_PLACEHOLDER;
	_topicDropdowns = 0;
	_matchAll = false;
	_topics;
	_selectedTopics = [null, null, null, null];

	// Private Reactive Properties
	topicOptions;
	filters;
	inputValue = null;
	@track dropdowns = [];

	get showDropdowns() {
		return this.dropdowns?.length > 0;
	}
	get columns() {
		return columnSizes(this.topicDropdowns);
	}
	get displayToggle() {
		return this.showToggle && this.topicDropdowns > 1;
	}

	// Public Properties
	@api searchIdentifier;
	@api showToggle = false;
	@api recordId;

	@api get topicDropdowns() {
		return this._topicDropdowns;
	}
	set topicDropdowns(topicDropdowns) {
		if (topicDropdowns !== 'None') {
			this.topicOptions = {
				searchOptions: {
					querySorts: [
						{
							field: 'Name',
							descending: true,
							nullsLast: true
						}
					],
					filters: [
						{
							field: 'NetworkId',
							value: COMMUNITY_ID,
							condition: 'AND',
							operator: '='
						}
					]
				}
			};
		}
		this._topicDropdowns = topicDropdowns !== 'None' ? parseInt(topicDropdowns, 10) : 0;
	}
	@api get matchAll() {
		return this._matchAll;
	}
	set matchAll(matchAll) {
		this._matchAll = matchAll;
	}
	@api
	get searchFields() {
		return this._searchFields;
	}
	set searchFields(searchFields) {
		this._searchFields = !isEmpty(searchFields) ? splitString(searchFields, ',', 'trim') : DEFAULT_SEARCH_FIELD;
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	@api
	get placeholder() {
		return this._placeholder;
	}
	set placeholder(placeholder) {
		this._placeholder = placeholder ? placeholder : PLACEHOLDER;
	}
	@api get dropdownPlaceholder() {
		return this._dropdownPlaceholder;
	}
	set dropdownPlaceholder(dropdownPlaceholder) {
		this._dropdownPlaceholder = dropdownPlaceholder ? dropdownPlaceholder : DROPDOWN_PLACEHOLDER;
	}

	@wire(MessageContext)
	messageContext;

	@wire(getTopics, { topicOptions: '$topicOptions' })
	searchResults({ error, data }) {
		if (data) {
			let topicsArray = [];
			topicsArray.push({ label: this.dropdownPlaceholder, value: null });
			data.results?.forEach((topic) => {
				if (topic.id !== this.recordId) {
					topicsArray.push({ label: topic.name, value: topic.id });
				}
			});
			this.setDropdowns(topicsArray);
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getTopics: ', error);
		}
	}

	// Sets the dropdown options
	setDropdowns(topics) {
		let options = [];
		for (let index = 0; index < this.topicDropdowns; index++) {
			options.push({
				index: index,
				// class: index != 0 ? 'slds-var-m-left_x-small' : '',
				options: topics,
				selected: this._selectedTopics[index]
			});
		}
		this.dropdowns = options;
		this._topics = options[0].options;
		this.filterDropdowns();
	}

	// Handles dropdown functionality
	handleDropdown(event) {
		let id = event.target.dataset.id;
		let value = event.target.value;
		this._selectedTopics[id] = value;

		this.filterDropdowns();
		this.publishSearchEvent();
	}

	filterDropdowns() {
		this.dropdowns.forEach((dropdown, index) => {
			let removedValues = [...this._selectedTopics];
			removedValues.splice(index, 1);
			dropdown.options = this._topics.filter((element) => {
				return !removedValues.includes(element.value) || element.value == null;
			});
		});
	}

	// Sends an object to the sibling component with data from this component
	handleChange = (event) => {
		let value = event.target.value;
		let matchRegex = value.match(REGEX_QUOTE);
		let fields = [];
		this.inputValue = value;

		if (matchRegex != null) {
			matchRegex.forEach((item) => {
				let formattedItem = item.replace(/["']/g, '');
				this.searchFields.forEach((field) => {
					let object = {
						field: field.trim(),
						value: `%${formattedItem.trim()}%`,
						condition: 'OR',
						operator: 'LIKE'
					};
					fields.push(object);
				});
			});
		}
		this.filters = fields;
		this.publishSearchEvent();
	};

	handleToggle(event) {
		// FIXME need to fix the reassignment of a public property
		// eslint-disable-next-line @lwc/lwc/no-api-reassignments
		this.matchAll = event.target.checked;
		this.publishSearchEvent();
	}

	publishSearchEvent() {
		// Set session variables for topics/matchall/search
		// setSessionStorage('searchFilters', { topics: this._selectedTopics, input: this.inputValue, filters: this.filters, matchAll: this.matchAll });
		console.log('publish event');
		publish(this.messageContext, SELECTED_CHANNEL, {
			identifier: this.searchIdentifier,
			details: {
				filters: this.filters,
				topicOptions: {
					matchAll: this.matchAll,
					topicIds: this._selectedTopics.filter((topic) => topic != null)
				}
			}
		});
	}

	connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
	}

	renderedCallback() {
		// if (getSessionStorage('searchFilters')) {
		//     let storage = getSessionStorage('searchFilters');
		//     this._selectedTopics = storage.topics;
		//     this.inputValue = storage.input;
		//     this.filters = storage.filters;
		//     this.matchAll = storage.matchAll;
		//     this.publishSearchEvent();
		// }
	}
}
