import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTopics from '@salesforce/apex/JCTopicController.getTopics';
import COMMUNITY_ID from '@salesforce/community/Id';
import { showToast, isEmpty, alignConvert, splitString } from 'c/jcUtils';
// import { CurrentPageReference } from 'lightning/navigation';
// import { register } from 'c/jcPubsub';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const DEFAULT_CLASS = 'brandedTopicFeatured';
const DEFAULT_TILE_HEIGHT = '250px';
const DEFAULT_COLUMNS = 2;
const DEFAULT_DISPLAY_TYPE = 'Image Tiles';
const ZERO_STATE_MESSAGE = 'No Topics Found';
const DEFAULT_OPACITY = '.5';

export default class JcTopicFeatured extends NavigationMixin(LightningElement) {
	// Private Properties
	_customClass;
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_columns = DEFAULT_COLUMNS;
	_displayType = DEFAULT_DISPLAY_TYPE;
	_tileHeight = DEFAULT_TILE_HEIGHT;
	_darkFont = false;
	_defineFeaturedTopics;
	_backgroundImage;
	_visorColor;
	_visorOpacity = DEFAULT_OPACITY;

	// Private Reactive Properties
	mediumDeviceSize = DEFAULT_COLUMNS;
	searchDetails;
	featuredTopics = [];
	imageTiles = false;
	list = false;
	// scroller = false;
	subscription = null;
	isLoaded = false;

	get displayTopics() {
		return this.featuredTopics?.length > 0;
	}
	get statAlignment() {
		return alignConvert(this.textAlignment);
	}
	get topicOptions() {
		let topicOptions = {
			featuredTopics: true,
			searchOptions: {
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
		if (isEmpty(this.defineFeaturedTopics) && this.defineFeaturedTopics?.length === 0) {
			topicOptions.searchOptions.querySorts.push({
				field: 'Name',
				descending: false,
				nullsLast: true
			});
		}

		if (!isEmpty(this.defineFeaturedTopics) && this.defineFeaturedTopics?.length > 0) {
			topicOptions.definedTopics = this.defineFeaturedTopics;
			topicOptions.searchOptions.filters.push({
				field: 'Name',
				value: this.defineFeaturedTopics,
				condition: 'AND',
				operator: 'IN'
			});
		} else {
			topicOptions.searchOptions.filters.push({
				field: 'ManagedTopicType',
				value: '%Featured%',
				condition: 'AND',
				operator: 'LIKE'
			});
		}
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
	get verticalAlign() {
		let alignment = splitString(this.contentAlign, '-', 'strip');
		return alignConvert(alignment[0]);
	}
	get horizontalAlign() {
		let alignment = splitString(this.contentAlign, '-', 'strip');
		return alignConvert(alignment[1]);
	}

	// Public Properties
	@api truncation;
	@api textAlignment;
	@api contentAlign;
	@api showFollowerCount = false;
	@api showArticleCount = false;
	@api showDiscussionCount = false;
	@api showFollowButton = false;
	@api visorBlendMode;
	@api imageScale;
	@api imagePosition;
	@api iconSize;
	@api iconPosition;
	@api hasRoundedCorners = false;
	@api searchIdentifier;
	@api defaultBackground;
	@api multiLineStats = false;
	@api multiLineFollow = false;

	@api get visorColor() {
		return this._visorColor;
	}
	set visorColor(visorColor) {
		this._visorColor = visorColor;
	}
	@api get visorOpacity() {
		return this._visorOpacity;
	}
	set visorOpacity(visorOpacity) {
		this._visorOpacity = visorOpacity;
	}
	@api get defineFeaturedTopics() {
		return this._defineFeaturedTopics;
	}
	set defineFeaturedTopics(defineFeaturedTopics) {
		if (!isEmpty(defineFeaturedTopics)) {
			this._defineFeaturedTopics = splitString(defineFeaturedTopics, ',', 'trim');
		}
	}
	@api get zeroStateMessage() {
		return this._zeroStateMessage;
	}
	set zeroStateMessage(zeroStateMessage) {
		this._zeroStateMessage = zeroStateMessage ? zeroStateMessage : ZERO_STATE_MESSAGE;
	}
	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		this._darkFont = darkFont;
	}
	@api get columns() {
		return this._columns;
	}
	set columns(columns) {
		columns = parseInt(columns, 10);
		this._columns = 12 / columns;
		this.mediumDeviceSize = columns > 2 ? Math.ceil(12 / Math.ceil(columns / 2)) : 12 / columns;
	}
	@api get removeMargin() {
		return this._removeMargin;
	}
	set removeMargin(removeMargin) {
		this._removeMargin = removeMargin;
		this.classList.toggle('no-margin', removeMargin);
	}
	@api get displayType() {
		return this._displayType;
	}
	set displayType(displayType) {
		switch (displayType) {
			case 'Image Tiles':
				this._displayType = displayType;
				this.imageTiles = true;
				break;
			case 'List':
				this._displayType = displayType;
				this.list = true;
				break;
			// case 'Scroller':
			//     this._displayType = displayType;
			//     this.scroller = true;
			//     break;
			default:
				this._displayType = 'Image Tiles';
				this.imageTiles = true;
		}
	}
	@api get backgroundImage() {
		return this._backgroundImage;
	}
	set backgroundImage(backgroundImage) {
		this._backgroundImage = backgroundImage;
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	@api get tileHeight() {
		return this._tileHeight;
	}
	set tileHeight(tileHeight) {
		this._tileHeight = tileHeight;
	}

	// Wires the CurrentPageReference to the component for the 'searchIdentifier' functionality
	// @wire(CurrentPageReference)
	// wirePageRef(reference) {
	//     this.pageRef = reference;
	//     this.registerEvent();
	// }

	@wire(MessageContext)
	messageContext;

	// Grabs all the Featured Topics in the Community and sets the topicArray array to the results
	@wire(getTopics, { topicOptions: '$topicOptions' })
	searchResults({ error, data }) {
		if (data) {
			let topicArray = [];
			data.results.forEach((topic) => {
				let featured = {
					articles: topic.articles,
					discussions: topic.discussions,
					followers: topic.followers,
					id: topic.id,
					title: topic.name,
					summary: topic.description,
					isFeatured: topic.isFeatured,
					isFollowing: topic.isFollowing,
					isNavigational: topic.isNavigational,
					image: this.defaultBackground
				};
				switch (this.backgroundImage) {
					case 'Topic Featured Image':
						if (topic.featuredImage) {
							featured.image = topic.featuredImage;
						}
						break;
					case 'Topic Banner Image':
						if (topic.bannerImage) {
							featured.image = topic.bannerImage;
						}
						break;
					default:
				}
				topicArray.push(featured);
			});
			this.featuredTopics = topicArray;
			this.isLoaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getTopics: ', error);
		}
	}

	// Handles the Pubsub functionality; If 'searchIdentifier' is populated, register it's value via the 'register' method on the Pubsub utils class.
	// registerEvent = () => {
	//     if (this.searchIdentifier) {
	//         register(this.searchIdentifier.toLowerCase(), this.handleSearchEvent, this);
	//     }
	// };
	// Handles the search functionality; Sets searchDetails to the new value of the search input.
	// handleSearchEvent = (event) => {
	//     this.searchDetails = event.details;
	// };

	handleSearch(event) {
		if (event.identifier === this.searchIdentifier) {
			this.searchDetails = event.details;
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

	// Handles the click functionality;  If the user clicks on a specific topic, utilizes the NavigationMixin functionality and redirects to the Topic Detail Page with the topicId
	handleClick = (event) => {
		let topicId = event.target.dataset.id;
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: topicId,
				actionName: 'view'
			}
		});
	};
	// Handles the click functionality;  If the user clicks on a specific topic, utilizes the NavigationMixin functionality and redirects to the Topic Detail Page with the topicId
	handleTileClick = (event) => {
		event.stopPropagation();
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: event.detail.id,
				actionName: 'view'
			}
		});
	};
}
