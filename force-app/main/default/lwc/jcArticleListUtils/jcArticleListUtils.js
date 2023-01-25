import { LightningElement, wire } from 'lwc';
import COMMUNITY_ID from '@salesforce/community/Id';
import { showToast, isEmpty } from 'c/jcUtils';
import getArticles from '@salesforce/apex/JCArticleController.getArticles';
import lightningKnowledgeEnabled from '@salesforce/apex/JCArticleController.lightningKnowledgeEnabled';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const DEFAULT_FIELDS = ['Id', 'Title', 'Summary', 'ArticleTotalViewCount', 'LastPublishedDate', 'Platform__c'];
const IMAGE_FIELD = 'FeaturedImageUrl__c';
const SORT_OPTIONS = 'A^,Z^,Trending,Recent,Most Viewed';
const CLASSIC_OBJECT = 'KnowledgeArticleVersion';
const LIGHTNING_OBJECT = 'Knowledge__kav';

export default class JcArticleListUtils extends LightningElement {
	// Private Properties
	_connected = false;
	_paginationChange = false;
	get _goToTop() {
		return this.backToTop && this._paginationChange;
	}

	// Private Reactive Properties
	sortOptions = SORT_OPTIONS;
	articles;
	loaded = false;
	articlesLength;
	pageSize = 5;
	pageNumber = 1;
	// previousIcon = { icon: '', label: '', position: '' };
	// nextIcon = { icon: '', label: '', position: '' };
	_subscription = null;
	searchDetails;
	// fontColor = getComputedStyle(document.body).getPropertyValue('--lwc-colorTextDefault');

	get objectName() {
		return this.lightningKnowledge.data ? LIGHTNING_OBJECT : CLASSIC_OBJECT;
	}
	get isAscending() {
		return this.defaultSortOrder === 'a^';
	}
	get isDescending() {
		return this.defaultSortOrder === 'z^';
	}
	get isTrending() {
		return this.defaultSortOrder === 'trending';
	}
	get showTopPagination() {
		return this.paginationLocation === 'Top' || this.paginationLocation === 'Both';
	}
	get showBottomPagination() {
		return this.paginationLocation === 'Bottom' || this.paginationLocation === 'Both';
	}
	get displayRecords() {
		return this.articles?.length > 0;
	}

	get articleOptions() {
		let fieldlist = DEFAULT_FIELDS.concat(IMAGE_FIELD);
		let offset;
		let queryLimit;
		if (this.showTopPagination || this.showBottomPagination) {
			offset = (this.pageNumber - 1) * this.pageSize;
		}
		queryLimit = this.pageSize;

		let articleOptions = {
			communityId: COMMUNITY_ID,
			sortOption: this.defaultSortOrder?.toLowerCase(),
			getAssignedTopics: true,
			imageField: IMAGE_FIELD,
			articleType: this.articleType !== 'All' ? this.articleType : null,
			searchOptions: {
				objectName: this.objectName,
				offset: offset,
				queryLimit: queryLimit,
				fields: fieldlist,
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
				descending: this.isAscending ? this.isDescending : true,
				nullsLast: true
			};

			switch (this.defaultSortOrder) {
				case 'a^':
				case 'z^':
					querySort.field = 'Title';
					break;
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

	@wire(MessageContext)
	messageContext;

	@wire(lightningKnowledgeEnabled)
	lightningKnowledge;

	@wire(getArticles, { articleOptions: '$articleOptions' })
	articleInformation({ error, data }) {
		if (data) {
			if (data.success) {
				this.articles = this.formatArticles(data.results);
				this.articlesLength = data.totalPaginationResults;
			} else {
				data.messages.forEach((message) => {
					showToast('error', '', message, 'dismissable');
					console.error('Error Processing getArticles: ', message);
				});
			}
			this.loaded = true;
			if (this._goToTop && this._connected) {
				this.template.querySelector(`:host .jc-component`).scrollIntoView({ behavior: 'smooth' });
			}
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getArticles: ', error);
		}
	}

	formatArticles = (data) => {
		let articles = [];
		data.forEach((item) => {
			let updatedItem = { description: item.summary, name: item.title };
			if (isEmpty(item.image)) {
				updatedItem.image = this.defaultBackground;
			}
			articles.push(Object.assign(updatedItem, item));
		});
		return articles;
	};

	connectedCallback() {
		this._connected = true;
		this.classList.add(this._defaultClass);
		if (this._customClasses) {
			// FIXME rework the optional chaining
			// eslint-disable-next-line no-unsafe-optional-chaining
			this.classList.add(...this._customClasses?.split(' '));
		}
		if (isEmpty(this._searchSubscription) && !isEmpty(this.searchIdentifier)) {
			this._subscription = subscribe(this.messageContext, SELECTED_CHANNEL, (event) => this.handleSearch(event));
		}
	}

	disconnectedCallback() {
		unsubscribe(this._subscription);
		this._subscription = null;
	}

	handleSearch = (event) => {
		if (event.identifier === this.searchIdentifier) {
			this.searchDetails = event.details;
			this.pageNumber = 1;
		}
	};

	handlePaginatorChange = (event) => {
		let eventDetails = event.detail;
		this._paginationChange = true;
		this.pageNumber = eventDetails.pageNumber;
		this.pageSize = eventDetails.pageSize;
	};

	handleSortOption = (event) => {
		this.defaultSortOrder = event.detail;
		this.pageNumber = 1;
	};
}
