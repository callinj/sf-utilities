import { LightningElement, api, wire } from 'lwc';
import { showToast, isEmpty, splitString } from 'c/jcUtils';
import { NavigationMixin } from 'lightning/navigation';
import getArticles from '@salesforce/apex/JCArticleController.getArticles';
import lightningKnowledgeEnabled from '@salesforce/apex/JCArticleController.lightningKnowledgeEnabled';
import COMMUNITY_ID from '@salesforce/community/Id';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const DEFAULT_CLASS = 'brandedRelatedArticleList';
const DEFAULT_TITLE = 'Trending Articles';
const ZERO_STATE_MESSAGE = 'No Articles Found';
const CLASSIC_OBJECT = 'KnowledgeArticleVersion';
const LIGHTNING_OBJECT = 'Knowledge__kav';
const DEFAULT_FIELDS = ['Id', 'Title', 'Summary', 'ArticleTotalViewCount', 'LastPublishedDate'];

export default class JcArticleRelatedList extends NavigationMixin(LightningElement) {
	// Private Properties
	_customClass;
	_title = DEFAULT_TITLE;
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_articleLimit = 10;
	_listType;
	_articles;
	_articleType;
	_loadedOptions;

	// Private Reactive Properties
	articles;
	selectedId;
	selectedTitle;
	loaded = false;
	showPreviewModal = false;
	subscription = null;
	searchDetails;
	previousElement = null;
	fontColor = getComputedStyle(document.body).getPropertyValue('--lwc-colorTextDefault');

	get objectName() {
		return this.lightningKnowledge.data ? LIGHTNING_OBJECT : CLASSIC_OBJECT;
	}
	get displayArticles() {
		return this.articles?.length > 0;
	}
	get isTrending() {
		return this.listType === 'trending';
	}
	get isRecent() {
		return this.listType === 'recent';
	}
	get isMostViewed() {
		return this.listType === 'mostviewed';
	}
	get _articleOptions() {
		let articleOptions = {
			sortOption: this.listType,
			articleType: this.articleType !== 'All' ? this.articleType : null,
			communityId: COMMUNITY_ID,
			searchOptions: {
				objectName: this.objectName,
				fields: DEFAULT_FIELDS,
				queryLimit: this.articleLimit,
				offset: 0,
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
				definedTopics: this.definedTopics,
				matchAll: this.searchDetails?.topicOptions.matchAll ?? null,
				topicIds: !isEmpty(this.searchDetails?.topicOptions.topicIds)
					? this.searchDetails?.topicOptions.topicIds
					: null
			}
		};

		if (this.lightningKnowledge.data) {
			articleOptions.articleType = 'Knowledge';
		}

		if (!this.isTrending) {
			let querySort = {
				descending: true,
				nullsLast: true
			};

			switch (this.listType) {
				case 'recent':
					querySort.field = 'LastModifiedDate';
					break;
				case 'mostviewed':
					querySort.field = 'ArticleTotalViewCount';
					break;
				default:
					break;
			}

			articleOptions.searchOptions.querySorts = [querySort];
		}

		if (this.articleType !== 'All') {
			articleOptions.searchOptions.filters.push({
				field: this.lightningKnowledge.data ? 'RecordType.Name' : 'ArticleType',
				value: this.lightningKnowledge.data ? this.articleType : this.articleType + '__kav',
				condition: 'AND',
				operator: '='
			});
		}

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

	// Public Properties
	@api enablePreview;
	@api searchIdentifier;

	@api get definedTopics() {
		return this._definedTopics;
	}
	set definedTopics(definedTopics) {
		if (!isEmpty(definedTopics)) {
			this._definedTopics = splitString(definedTopics, ',', 'trim');
		}
	}
	@api get articleType() {
		return this._articleType;
	}
	set articleType(articleType) {
		this._articleType = articleType;
	}
	@api
	get title() {
		return this._title;
	}
	set title(title) {
		this._title = title ? title : DEFAULT_TITLE;
	}
	@api get articleLimit() {
		return this._articleLimit;
	}
	set articleLimit(articleLimit) {
		this._articleLimit = articleLimit ? parseInt(articleLimit, 10) : 10;
	}
	@api get listType() {
		return this._listType;
	}
	set listType(listType) {
		this._listType = listType.replace(/\s+/g, '').toLowerCase();
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

	@wire(lightningKnowledgeEnabled)
	lightningKnowledgeEnabledMethod(response) {
		this.lightningKnowledge = response;
		const { data, error } = response;
		if (data !== undefined) {
			this._loadedOptions = this._articleOptions;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing lightningKnowledgeEnabled: ', error);
		}
	}

	@wire(getArticles, { articleOptions: '$_loadedOptions' })
	articleList({ error, data }) {
		if (data) {
			if (data.success) {
				this.articles = data.results;
			} else {
				data.messages.forEach((message) => {
					showToast('error', '', message, 'dismissable');
					console.error('Error Processing getArticles Data:', message);
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
			this.pageNumber = 1;
		}
	}

	openPreview(event) {
		this.previousElement = this.template.activeElement;
		this.selectedId = event.target.dataset.id;
		this.selectedTitle = event.target.dataset.title;
		this.showPreviewModal = true;
	}

	closePreview() {
		this.showPreviewModal = false;
		this.previousElement.focus();
	}

	navigateUrl() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.selectedId,
				actionName: 'view'
			}
		});
	}
}
