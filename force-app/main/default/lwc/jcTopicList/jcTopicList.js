import { LightningElement, api, track, wire } from 'lwc';
import getTopics from '@salesforce/apex/JCTopicController.getTopics';
import { showToast, convertIcon, splitString } from 'c/jcUtils';
import COMMUNITY_ID from '@salesforce/community/Id';
// import { CurrentPageReference } from 'lightning/navigation';
// import { register } from 'c/jcPubsub';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const DEFAULT_CLASS = 'brandedTopicList';
const DEFAULT_FEATURED = 'utility:ribbon Featured';
const ZERO_STATE_MESSAGE = 'No Topics Found';
const PADDING_SMALL = 'slds-var-m-bottom_small slds-var-m-top_small';
const PADDING_LARGE = 'slds-var-m-bottom_large slds-var-m-top_large';

export default class JcTopicList extends LightningElement {
	// Private Properties
	_customClass;
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_featuredText = DEFAULT_FEATURED;
	_showAsButtons = false;
	_defaultPageSize;
	_tightenSpacing = false;
	_previousButton = 'Previous';
	_nextButton = 'Next';
	_sortOption = 'a^';
	_alignFollowSeparator = false;

	// Private Reactive Properties
	searchDetails;
	pageSize = 5;
	pageNumber = 1;
	featuredIcon = { icon: '', label: '', position: '' };
	previousIcon = { icon: '', label: '', position: '' };
	nextIcon = { icon: '', label: '', position: '' };
	subscription = null;
	@track topics;
	@track topicsLength;
	@track isDecending = false;
	@track spacing = PADDING_LARGE;
	isLoaded = false;

	get showTopPagination() {
		return this.paginationLocation === 'Top' || this.paginationLocation === 'Both';
	}
	get showBottomPagination() {
		return this.paginationLocation === 'Bottom' || this.paginationLocation === 'Both';
	}
	get displayRecords() {
		return this.topics?.length > 0;
	}
	get sortOption() {
		return this._sortOption;
	}
	set sortOption(sortOption) {
		this._sortOption = sortOption;
	}
	get isAscending() {
		return this.sortOption === 'a^';
	}
	get isDescending() {
		return this.sortOption === 'z^';
	}
	get topicOptions() {
		let offset;
		let queryLimit;
		if (this.showTopPagination || this.showBottomPagination) {
			offset = (this.pageNumber - 1) * this.pageSize;
			queryLimit = this.pageSize;
		}

		let topicOptions = {
			searchOptions: {
				offset: offset,
				queryLimit: queryLimit,
				querySorts: [
					{
						field: 'Name',
						descending: this.isDescending,
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

		if (this.searchDetails?.filters && this.searchDetails.filters?.length > 0) {
			topicOptions.searchOptions.filterGroups = [
				{
					condition: 'AND',
					filters: this.searchDetails?.filters
				}
			];
		}
		return topicOptions;
	}

	// Public Properties
	@api showFollowerCount = false;
	@api showArticleCount = false;
	@api showDiscussionCount = false;
	@api showFollowButton = false;
	@api showTopicDescription = false;
	@api paginationLocation = 'Bottom';
	@api searchIdentifier;
	@api largeButtons = false;
	@api showFollowSeparator = false;

	@api get pageSizeOptions() {
		return this._pageSizeOptions;
	}
	set pageSizeOptions(pageSizeOptions) {
		if (pageSizeOptions) {
			this._pageSizeOptions = pageSizeOptions;
			if (!this.defaultPageSize) {
				this.pageSize = parseInt(pageSizeOptions?.split(',')[0], 10);
			}
		}
	}
	@api get alignFollowSeparator() {
		return this._alignFollowSeparator;
	}
	set alignFollowSeparator(alignFollowSeparator) {
		this._alignFollowSeparator = alignFollowSeparator;
	}
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
	@api get showAsButtons() {
		return this._showAsButtons;
	}
	set showAsButtons(showAsButtons) {
		this._showAsButtons = showAsButtons ? 'brand-outline' : '';
	}
	@api get defaultPageSize() {
		return this._defaultPageSize;
	}
	set defaultPageSize(defaultPageSize) {
		if (defaultPageSize) {
			this.pageSize = parseInt(defaultPageSize, 10);
			this._defaultPageSize = defaultPageSize;
		}
	}
	@api get tightenSpacing() {
		return this._tightenSpacing;
	}
	set tightenSpacing(tightenSpacing) {
		this._tightenSpacing = tightenSpacing;
		this.spacing = tightenSpacing ? PADDING_SMALL : PADDING_LARGE;
	}
	@api get featuredText() {
		return this._featuredText;
	}
	set featuredText(featuredText) {
		this._featuredText = featuredText;
	}
	@api get previousButton() {
		return this.previousIcon;
	}
	set previousButton(previousButton) {
		this._previousButton = previousButton;
		if (previousButton) {
			let icon = convertIcon(previousButton);
			this.previousIcon.label = icon.iconLabel;
			this.previousIcon.icon = icon.iconName;
			this.previousIcon.position = icon.iconPosition;
		}
	}
	@api get nextButton() {
		return this.nextIcon;
	}
	set nextButton(nextButton) {
		this._nextButton = nextButton;
		if (nextButton) {
			let icon = convertIcon(nextButton);
			this.nextIcon.label = icon.iconLabel;
			this.nextIcon.icon = icon.iconName;
			this.nextIcon.position = icon.iconPosition;
		}
	}

	// Sets the CurrentPageReference for the Pubsub functionality
	// @wire(CurrentPageReference)
	// pageRef;

	@wire(MessageContext)
	messageContext;

	// Grabs all the Topics based off the search criteria
	@wire(getTopics, { topicOptions: '$topicOptions' })
	searchResults({ error, data }) {
		if (data) {
			this.topics = data.results;
			this.topicsLength = data.totalPaginationResults;
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getTopics: ', error);
		}
	}

	// Filter topics according to pagination
	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};

	handleSearch(event) {
		if (event.identifier === this.searchIdentifier) {
			this.searchDetails = event.details;
			this.pageNumber = 1;
		}
	}

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

	// Sets the sortOption to the either 'A^' or 'Z^'
	handleSortOption = (event) => {
		this.sortOption = event.detail;
		this.pageNumber = 1;
	};

	// Handles the Pubsub functionality; If 'searchIdentifier' is populated, register it's value via the 'register' method on the Pubsub utils class.
	// registerEvent = () => {
	//     if (this.searchIdentifier) {
	//         register(this.searchIdentifier.toLowerCase(), this.handleEvent, this);
	//     }
	// };

	// Handles the search functionality; Sets searchDetails to the new value of the search input.
	// handleEvent = (event) => {
	//     this.searchDetails = event.details;
	//     this.pageNumber = 1;
	// };
}
