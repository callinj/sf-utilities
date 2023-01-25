import { LightningElement, api, wire } from 'lwc';
import { showToast, alignConvert, isEmpty, splitString } from 'c/jcUtils';
import { NavigationMixin } from 'lightning/navigation';
import COMMUNITY_ID from '@salesforce/community/Id';
import getArticles from '@salesforce/apex/JCArticleController.getFeaturedArticles';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const DEFAULT_CLASS = 'brandedArticleFeatured';
const DEFAULT_COLUMNS = 2;
const ZERO_STATE_MESSAGE = 'No Articles Found';
const DEFAULT_FIELDS = [
	'Id',
	'Title',
	'Summary',
	'ArticleTotalViewCount',
	'LastPublishedDate',
	'Platform__c',
	'Asset_Type__c'
];
const OBJECT_NAME = 'Knowledge__kav';
const DEFAULT_OPACITY = '.5';
const TOPIC_COUNT = 3;
const TOPIC_POSITION = 'top';

export default class JcArticleFeatured extends NavigationMixin(LightningElement) {
	// Private Properties
	_customClass;
	_darkFont = false;
	_visorColor;
	_visorOpacity = DEFAULT_OPACITY;
	_topicPosition = TOPIC_POSITION;
	_topicCount = TOPIC_COUNT;
	_imageField;

	// Private Reactive Properties
	mediumDeviceSize = DEFAULT_COLUMNS;
	articles = [];
	searchDetails;
	loaded = false;
	fields = DEFAULT_FIELDS;

	get articleOptions() {
		let articleOptions = {
			communityId: COMMUNITY_ID,
			getAssignedTopics: this.retrieveTopics,
			assignedTopicsCount: this.topicCount,
			navigationMenu: this.navigationMenu,
			imageField: !isEmpty(this.imageField) ? this.imageField : null,
			searchOptions: {
				objectName: OBJECT_NAME,
				fields: this.fields,
				filters: [
					{
						field: 'PublishStatus',
						value: 'Online',
						condition: 'AND',
						operator: '='
					}
				]
			},
			searchFilters: {
				matchAll: this.searchDetails?.topicOptions.matchAll ?? null,
				topicIds: !isEmpty(this.searchDetails?.topicOptions.topicIds)
					? this.searchDetails?.topicOptions.topicIds
					: null
			}
		};

		if (this.searchDetails?.filters) {
			articleOptions.searchOptions.filterGroups = [
				{
					condition: 'AND',
					filters: this.searchDetails?.filters
				}
			];
		}
		return articleOptions;
	}

	get displayArticles() {
		return this.articles?.length > 0;
	}
	get statAlignment() {
		return alignConvert(this.textAlignment);
	}
	get showStats() {
		return this.showViews || this.showDate;
	}
	get showTopTopics() {
		return this.retrieveTopics && this.topicPosition === 'top';
	}
	get showBottomTopics() {
		return this.retrieveTopics && this.topicPosition === 'bottom';
	}
	get retrieveTopics() {
		return this.topicCount !== 0;
	}

	// Public Properties
	@api navigationMenu;
	@api showViews = false;
	@api showDate = false;
	@api showSummary = false;
	@api defaultBackground;
	@api contentAlign;
	@api textAlignment;
	@api truncateTitle;
	@api truncateSummary;
	@api imageScale;
	@api imagePosition;
	@api visorBlendMode;
	@api searchIdentifier;
	@api columns;

	@api get imageField() {
		return this._imageField;
	}
	set imageField(imageField) {
		this._imageField = imageField ? imageField : imageField;
		if (imageField && !this.fields.includes(imageField)) {
			this.fields.push(imageField);
		}
	}
	@api get topicPosition() {
		return this._topicPosition;
	}
	set topicPosition(topicPosition) {
		this._topicPosition = topicPosition.toLowerCase();
	}
	@api get topicCount() {
		return this._topicCount;
	}
	set topicCount(topicCount) {
		this._topicCount = !isNaN(topicCount)
			? parseInt(topicCount, 10)
			: topicCount.toLowerCase() === 'none'
			? 0
			: null;
	}
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
	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		this._darkFont = darkFont;
	}
	// @api get columns() {
	//     return this._columns;
	// }
	// set columns(columns) {
	//     columns = parseInt(columns, 10);
	//     this._columns = 12 / columns;
	//     this.mediumDeviceSize = columns > 2 ? Math.ceil(12 / Math.ceil(columns / 2)) : 12 / columns;
	// }
	@api get removeMargin() {
		return false;
	}
	set removeMargin(removeMargin) {
		this.classList.toggle('no-margin', removeMargin);
	}
	@api get tileHeight() {
		return this._tileHeight;
	}
	set tileHeight(tileHeight) {
		this._tileHeight = tileHeight;
	}
	@api get zeroStateMessage() {
		return this._zeroStateMessage;
	}
	set zeroStateMessage(zeroStateMessage) {
		this._zeroStateMessage = zeroStateMessage ? zeroStateMessage : ZERO_STATE_MESSAGE;
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}

	@wire(MessageContext)
	messageContext;

	@wire(getArticles, { articleOptions: '$articleOptions' })
	articleInformation({ error, data }) {
		if (data) {
			if (data.success) {
				data.results.forEach((article) => {
					article = { ...article };
					if (isEmpty(article.image)) {
						article.image = this.defaultBackground;
					}
					article.class =
						article?.assetType.toLowerCase().trim().replace(/\s/g, '-') +
						' ' +
						article?.platform.toLowerCase().trim().replace(/\s/g, '-');
					this.articles.push(article);
				});
			} else {
				data.messages.forEach((message) => {
					showToast('error', '', message, 'dismissable');
					console.error('Error Processing getArticles: ', message);
				});
			}
			this.loaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getArticles: ', error);
		}
	}

	connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
		if (!this.subscription) {
			this.subscription = subscribe(this.messageContext, SELECTED_CHANNEL, (event) => this.handleSearch(event));
		}
	}

	disconnectedCallback() {
		unsubscribe(this.subscription);
		this.subscription = null;
	}

	handleSearch(event) {
		if (event.identifier === this.searchIdentifier) {
			this.searchDetails = event.details;
		}
	}

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
