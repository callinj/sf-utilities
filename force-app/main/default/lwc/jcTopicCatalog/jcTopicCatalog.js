import { LightningElement, api, wire } from 'lwc';
import { showToast, splitString } from 'c/jcUtils';
import getTopicTree from '@salesforce/apex/JCTopicController.getTopicTree';
import COMMUNITY_ID from '@salesforce/community/Id';
import COMMUNITY_PATH from '@salesforce/community/basePath';

const DEFAULT_CLASS = 'brandedTopicCatalog';
const PLACEHOLDER = 'Filter Topics...';
const ZERO_STATE_MESSAGE = 'No Topics Found';
// const DEFAULT_ICON_TEXT = 'utility:ribbon Featured';

export default class JcTopicCatalog extends LightningElement {
	// Private properties
	_customClass;
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_placeholder = PLACEHOLDER;

	// Private reactive properties
	searchTerm;
	isLoaded = false;
	topicTree = [];
	selected;
	iconName;
	iconText;

	get topicOptions() {
		let topicOptions = {
			searchOptions: {
				querySorts: [
					{
						field: 'Name',
						descending: false,
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
		if (this.searchTerm) {
			topicOptions.searchOptions.filterGroups = [
				{
					condition: 'AND',
					filters: [
						{
							field: 'Name',
							value: `%${this.searchTerm}%`,
							condition: 'OR',
							operator: 'LIKE'
						}
					]
				}
			];
		}
		return topicOptions;
	}
	get displayRecords() {
		return this.topicTree.length > 0;
	}

	// Public properties
	@api showSearch = false;
	@api expandedTopicStructure;
	@api recordId;
	// @api highlightFeaturedTopics;
	// @api showFollowerCount;
	// @api showArticleCount;
	// @api showDisucssionCount;
	// @api showFollowButtons;

	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	@api get zeroStateMessage() {
		return this._zeroStateMessage;
	}
	set zeroStateMessage(zeroStateMessage) {
		this._zeroStateMessage = zeroStateMessage ? zeroStateMessage : ZERO_STATE_MESSAGE;
	}
	@api get placeholder() {
		return this._placeholder;
	}
	set placeholder(placeholder) {
		this._placeholder = placeholder ? placeholder : PLACEHOLDER;
	}

	// Grabs all the Topics along with their children
	@wire(getTopicTree, { topicOptions: '$topicOptions' })
	searchResults({ error, data }) {
		if (data) {
			this.topicTree = this.searchTopics(data.results);
			this.filterTopics(this.topicTree);
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getTopicTree: ', error);
		}
	}

	connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
	}

	// Returns the Topic data in the needed structure for a lightning-tree
	searchTopics = (topics) => {
		let topicList = [];
		topics.forEach((topic) => {
			let topicObject = {
				label: topic.name,
				name: topic.id,
				href: `${COMMUNITY_PATH}/topic/${topic.id}`,
				expanded: false
			};

			if (topic.children != null) {
				topicObject.items = this.searchTopics(topic.children);
			}
			topicList.push(topicObject);
		});
		return topicList;
	};

	// Handles which Topics get expanding depending on expandedTopicStructure
	filterTopics = (topics) => {
		topics.forEach((topic) => {
			switch (this.expandedTopicStructure) {
				case 'All':
				case 'all':
					topic.expanded = true;
					if (topic.items) {
						this.filterTopics(topic.items);
					}
					break;
				case 'Expand 1st Level Topics':
				case 'first-level':
					topic.expanded = true;
					break;
				case 'Expand Current Topic':
				case 'current':
					this.selected = this.recordId;
					if (topic.name === this.recordId) {
						topic.expanded = true;
					}
					if (topic.items) {
						this.filterTopics(topic.items);
					}
					break;
				default:
					break;
			}
		});
	};

	// Sets the searchTerm to the value of the search bar input
	handleChange = (event) => {
		this.searchTerm = event.target.value;
	};
}
