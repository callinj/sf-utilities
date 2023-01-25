import { api } from 'lwc';
// import COMMUNITY_ID from '@salesforce/community/Id';
import { splitString, isEmpty } from 'c/jcUtils';
// import getArticles from '@salesforce/apex/JCArticleController.getArticles';
// import lightningKnowledgeEnabled from '@salesforce/apex/JCArticleController.lightningKnowledgeEnabled';
// import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
// import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const DEFAULT_CLASS = 'brandedArticleList';
const ZERO_STATE_MESSAGE = 'No Articles Found';
// const DEFAULT_FIELDS = ['Id', 'Title', 'Summary', 'ArticleTotalViewCount', 'LastPublishedDate', 'Platform__c'];
const SORT_OPTIONS = 'A^,Z^,Trending,Recent,Most Viewed';
// const CLASSIC_OBJECT = 'KnowledgeArticleVersion';
// const LIGHTNING_OBJECT = 'Knowledge__kav';
import JcArticleListUtils from 'c/jcArticleListUtils';

export default class JcArticleList extends JcArticleListUtils {
	// Private Properties
	_customClass;
	_articles;
	_pageSizeOptions;
	_showSortOptions = false;
	_defaultSortOrder = 'a^';
	_showAsButtons = false;
	_previousButton = 'Previous';
	_nextButton = 'Next';
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_articleType;
	_backToTop = false;
	_listType = 'list';
	_defaultClass = DEFAULT_CLASS;

	// Private Reactive Properties
	get isAccordion() {
		return this.enableAccordion;
	}
	get isList() {
		return !this.enableAccordion;
	}

	// Public Properties
	@api showTopics = false;
	@api enableAccordion = false;
	@api showViews = false;
	@api showDate = false;
	@api showSummary = false;
	@api paginationLocation;
	@api tightenSpacing = false;
	@api largeButtons = false;
	@api enablePreview = false;
	@api showViewArticle = false;
	@api searchIdentifier;

	@api get listType() {
		return this._listType;
	}
	set listType(listType) {
		this._listType = listType?.toLowerCase();
	}

	@api get showSortOptions() {
		return this._showSortOptions;
	}
	set showSortOptions(showSortOptions) {
		if (showSortOptions) {
			this.sortOptions = SORT_OPTIONS;
		} else {
			this.sortOptions = null;
		}
	}
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
	@api get defaultSortOrder() {
		return this._defaultSortOrder;
	}
	set defaultSortOrder(defaultSortOrder) {
		this._defaultSortOrder = defaultSortOrder?.toLowerCase().replace(/\s+/g, '');
	}
	@api get pageSizeOptions() {
		return this._pageSizeOptions;
	}
	set pageSizeOptions(pageSizeOptions) {
		if (pageSizeOptions) {
			this._pageSizeOptions = pageSizeOptions;
			this.pageSize = parseInt(pageSizeOptions?.split(',')[0], 10);
		}
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
		this._showAsButtons = showAsButtons ? 'brand-outline' : '';
	}
	@api get backToTop() {
		return this._backToTop;
	}
	set backToTop(backToTop) {
		this._backToTop = backToTop;
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
		customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...customClass);
		this._customClass = customClass;
	}
	// connectedCallback() {
	//     this.classList.add(DEFAULT_CLASS);
	// }
}
