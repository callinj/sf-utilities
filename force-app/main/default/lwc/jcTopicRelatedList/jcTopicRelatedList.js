import { LightningElement, wire, api } from 'lwc';
import { showToast, splitString } from 'c/jcUtils';
import getTopicTree from '@salesforce/apex/JCTopicController.getTopicTree';
import getSpecifiedRelatedTopics from '@salesforce/apex/JCTopicController.getSpecifiedRelatedTopics';
import COMMUNITY_ID from '@salesforce/community/Id';
import USER_ID from '@salesforce/user/Id';
import { refreshApex } from '@salesforce/apex';
// import { CurrentPageReference } from 'lightning/navigation';
// import { register } from 'c/jcPubsub';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const DEFAULT_CLASS = 'brandedTopicRelatedList';
const DEFAULT_SEPARATOR = '|';
const DEFAULT_DISPLAY_TYPE = 'Inline Text';
const ZERO_STATE_MESSAGE = 'No Topics Found';
const SUGGESTED_TOPICS_TITLE = 'Suggested Topics';

export default class JcTopicRelatedList extends LightningElement {
	// Private Properties
	_customClass;
	_suggestedTopicsToDisplay = null;
	_displayType = DEFAULT_DISPLAY_TYPE;
	_separator = DEFAULT_SEPARATOR;
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_zeroStateMessageSuggested = ZERO_STATE_MESSAGE;
	_topicSource = 'followed';
	_searchIdentifier;
	_suggestedTopicsTitle = SUGGESTED_TOPICS_TITLE;
	_topics = [];
	_suggestedTopics = [];
	_trendingAmount;
	_relatedType;
	_expandedOptions;
	_relatedOptions;

	get _topicOptions() {
		let options = {
			searchOptions: this.searchOptions,
			communityId: COMMUNITY_ID,
			userIds: [USER_ID],
			trendingAmount: 25,
			suggestedCount: this.suggestedTopicsToDisplay,
			relatedType: this._relatedType,
			currentId: this.recordId
		};
		return options;
	}

	// Private Reactive Properties
	// pageRef;
	totalTopics = [];
	isInline = false;
	isVerticalRule = false;
	searchDetails;
	isLoaded = false;
	subscription = null;
	refreshTopics;

	get topics() {
		return this._topics;
	}
	set topics(topics) {
		this._topics = this.getTopicData(topics);
	}
	get suggestedTopics() {
		return this._suggestedTopics;
	}
	set suggestedTopics(suggestedTopics) {
		this._suggestedTopics = this.getTopicData(suggestedTopics);
	}
	get showSuggestedTopics() {
		return this.suggestedTopicsToDisplay !== null;
	}
	get displayZero() {
		return this.topics?.length > 0;
	}
	get displayZeroSuggested() {
		return this.suggestedTopics?.length > 0;
	}
	get searchOptions() {
		let searchOptions = {
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
		};
		if (this.searchDetails?.filters && this.searchDetails.filters?.length > 0) {
			searchOptions.filterGroups = [
				{
					condition: 'AND',
					filters: this.searchDetails?.filters
				}
			];
		}
		return searchOptions;
	}

	// Public Properties
	@api recordId;
	@api showFollow = false;
	// @api showBullets; // Future enhancement

	@api get suggestedTopicsTitle() {
		return this._suggestedTopicsTitle;
	}
	set suggestedTopicsTitle(suggestedTopicsTitle) {
		this._suggestedTopicsTitle = suggestedTopicsTitle ? suggestedTopicsTitle : SUGGESTED_TOPICS_TITLE;
	}
	@api get zeroStateMessage() {
		return this._zeroStateMessage;
	}
	set zeroStateMessage(zeroStateMessage) {
		this._zeroStateMessage = zeroStateMessage ? zeroStateMessage : ZERO_STATE_MESSAGE;
	}
	@api get zeroStateMessageSuggested() {
		return this._zeroStateMessageSuggested;
	}
	set zeroStateMessageSuggested(zeroStateMessageSuggested) {
		this._zeroStateMessageSuggested = zeroStateMessageSuggested ? zeroStateMessageSuggested : ZERO_STATE_MESSAGE;
	}
	@api get searchIdentifier() {
		return this._searchIdentifier;
	}
	set searchIdentifier(searchIdentifier) {
		this._searchIdentifier = searchIdentifier;
	}
	@api get topicSource() {
		return this._topicSource;
	}
	set topicSource(topicSource) {
		this._topicSource = topicSource;
		switch (topicSource) {
			case 'My Followed Topics':
			case 'followed':
				this._relatedType = 'followed';
				break;
			case 'Trending Topics':
			case 'trending':
				this._relatedType = 'trending';
				break;
			default:
				break;
		}
		this.updateTopics(this._topicOptions);
	}
	@api get suggestedTopicsToDisplay() {
		return this._suggestedTopicsToDisplay;
	}
	set suggestedTopicsToDisplay(suggestedTopicsToDisplay) {
		if (suggestedTopicsToDisplay !== 'None') {
			this._suggestedTopicsToDisplay = parseInt(suggestedTopicsToDisplay, 10);
		}
	}
	@api get separator() {
		return this._separator;
	}
	set separator(separator) {
		switch (separator) {
			case 'Vertical Rule':
				this._separator = '|';
				break;
			case 'Comma':
				this._separator = ',';
				break;
			default:
				this._separator = '|';
				break;
		}
	}
	@api get displayType() {
		return this._displayType;
	}
	set displayType(displayType) {
		this._displayType = displayType;
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}

	// Wires the CurrentPageReference to this component to allow the Pubsub functionality to work
	// @wire(CurrentPageReference)
	// wirePageRef(value) {
	//     this.pageRef = value;
	//     this.registerEvent();
	// }

	@wire(MessageContext)
	messageContext;

	// Grabs all the Topics underneath the current Topic
	@wire(getTopicTree, { topicOptions: '$_expandedOptions', currentId: '$recordId' })
	getTopics({ error, data }) {
		if (data) {
			if (data.success) {
				this.topics = data.topic?.children;
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissable');
				console.error('Error Processing getTopicTree: ', data.messages[0]);
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getTopics: ', error);
		}
		this.isLoaded = true;
	}

	// Grabs all the Topics depending on _relatedType
	// _relatedType == 'followed'; Returns all Topics the current user is following
	// _relatedType == 'trending'; Returns all the Topics Trending in the Community
	@wire(getSpecifiedRelatedTopics, { topicOptions: '$_relatedOptions' })
	getFollowedTopics(results) {
		this.refreshTopics = results;
		const { data, error } = results;
		if (data) {
			if (data.success) {
				this.topics = data.results;
				this.suggestedTopics = data.relatedTopics;
			} else {
				showToast('error', data.messages[0], 'Error Message', 'dismissable');
				console.error('Error Processing getSpecifiedRelatedTopics: ', data.messages[0]);
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getFollowedTopics: ', error);
		}
		this.isLoaded = true;
	}

	handleFollowChange() {
		refreshApex(this.refreshTopics);
	}

	handleSearch = (event) => {
		if (event.identifier === this.searchIdentifier) {
			this.searchDetails = event.details;
			this.updateTopics();
		}
	};

	subscribeToMessageChannel() {
		if (!this.subscription) {
			this.subscription = subscribe(this.messageContext, SELECTED_CHANNEL, (event) => this.handleSearch(event));
		}
	}

	unsubscribeToMessageChannel() {
		unsubscribe(this.subscription);
		this.subscription = null;
	}

	connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
		this.subscribeToMessageChannel();
	}

	disconnectedCallback() {
		this.unsubscribeToMessageChannel();
	}

	// Returns the Topic data into the correct object structure for jc-link-list
	getTopicData = (results) => {
		let items = [];
		if (results) {
			results.forEach((item) => {
				items.push({
					id: item.id,
					name: item.name,
					url: `${item.id}`,
					isFollowing: item.isFollowing
				});
			});
		}
		return items;
	};

	// Decides which @wire method that gets executed
	updateTopics = () => {
		if (this._relatedType) {
			this._relatedOptions = this._topicOptions;
		} else {
			this._expandedOptions = this._topicOptions;
		}
	};

	// Handles the Pubsub functionality; If 'searchIdentifier' is populated, register it's value via the 'register' method on the Pubsub utils class.
	// registerEvent = () => {
	//     if (this.searchIdentifier) {
	//         register(this.searchIdentifier.toLowerCase(), this.handleSearchEvent, this);
	//     }
	// };

	// Handles the search functionality; Sets searchDetails to the new value of the search input and updates the _relatedType
	// handleSearchEvent = (event) => {
	//     this.searchDetails = event.details;
	//     this.updateTopics();
	// };
}
