import { LightningElement, api, wire } from 'lwc';
import { isEmpty, columnSizes, alignConvert, isValidStyle } from 'c/jcUtils';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SELECTED_CHANNEL from '@salesforce/messageChannel/jcSearch__c';

const ZERO_STATE_MESSAGE = 'No Items Found';
const SORT_OPTIONS = 'A^,Z^,Trending,Recent,Most Viewed';
const DEFAULT_OPACITY = '.5';
const DEFAULT_CLASSES = 'jc-grid-list';

export default class JCGridList extends LightningElement {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_borderColor;
	_iconColor;
	_iconHoverColor;
	_gutterSize;
	_darkFont = false;
	_visorOpacity = DEFAULT_OPACITY;
	_pageSizeOptions;
	_showSortOptions = false;
	_columns = columnSizes(3);
	_defaultSortOrder = 'a^';
	_showAsButtons = false;
	_previousButton = 'Previous';
	_nextButton = 'Next';
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_listType = 'list';
	_cssVariables = {};
	_searchSubscription = null;
	_visorColor;
	_visorColorHover;

	// Private reactive properties
	pageSize = 5;
	pageNumber = 1;
	get showTopPagination() {
		return this.paginationLocation === 'Top' || this.paginationLocation === 'Both';
	}
	get showBottomPagination() {
		return this.paginationLocation === 'Bottom' || this.paginationLocation === 'Both';
	}
	get statAlignment() {
		return alignConvert(this.textAlignment);
	}
	get showArticleStats() {
		return this.showViews || this.showDate;
	}
	get showTopicStats() {
		return this.showFollowerCount || this.showArticleCount || this.showDiscussionCount || this.showFollowButton;
	}
	get showTopTopics() {
		return this.retrieveTopics && this.topicPosition === 'top';
	}
	get showBottomTopics() {
		return this.retrieveTopics && this.topicPosition === 'bottom';
	}
	get retrieveTopics() {
		return this.showTopics && this.topicCount !== 0;
	}
	get displayItems() {
		return this.items?.length > 0;
	}

	// Public properties
	@api items;
	@api totalItems;
	@api isLoaded = false;
	@api showViews = false;
	@api showDate = false;
	@api showFollowerCount = false;
	@api showArticleCount = false;
	@api showDiscussionCount = false;
	@api showFollowButton = false;
	@api multiLineStats = false;
	@api multiLineFollow = false;
	@api showTopics = false;
	@api showSummary = false;
	@api paginationLocation;
	@api largeButtons = false;
	@api defaultBackground;
	@api contentAlign;
	@api textAlignment;
	@api truncateTitle;
	@api truncateSummary;
	@api imageScale;
	@api imagePosition;
	@api borderRadius;
	@api visorBlendMode;
	@api showBorder = false;
	@api searchIdentifier;
	// @api visorColor;
	// @api visorColorHover;
	@api tileIcon;
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
	@api get columns() {
		return this._columns;
	}
	set columns(columns) {
		this._columns = columnSizes(columns);
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
	@api get imageHeight() {
		return this._imageHeight;
	}
	set imageHeight(imageHeight) {
		this._imageHeight = imageHeight;
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
	@api get iconHoverColor() {
		return this._iconHoverColor;
	}
	set iconHoverColor(iconHoverColor) {
		if (!isEmpty(iconHoverColor)) {
			this._cssVariables['--jc-grid-tile-icon-color-hover'] = iconHoverColor;
		}
		this._iconHoverColor = iconHoverColor;
	}
	@api get iconColor() {
		return this._iconColor;
	}
	set iconColor(iconColor) {
		if (!isEmpty(iconColor)) {
			this._cssVariables['--jc-grid-tile-icon-color'] = iconColor;
		}
		this._iconColor = iconColor;
	}
	@api get borderColor() {
		return this._borderColor;
	}
	set borderColor(borderColor) {
		if (!isEmpty(borderColor)) {
			this._cssVariables['--jc-grid-tile-border-color'] = borderColor;
		}
		this._borderColor = borderColor;
	}
	@api get gutterSize() {
		return this._gutterSize;
	}
	set gutterSize(gutterSize) {
		if (!isEmpty(gutterSize)) {
			this._cssVariables['--jc-grid-gutter-size'] = gutterSize;
		}
		this._gutterSize = gutterSize;
	}
	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += !isEmpty(customClasses) ? ` ${customClasses}` : '';
	}
	@api get visorColor() {
		return this._visorColor;
	}
	set visorColor(visorColor) {
		if (!isEmpty(visorColor)) {
			if (isValidStyle(visorColor, 'color')) {
				this._cssVariables['--jc-grid-tile-visor-background-color'] = visorColor;
			} else if (isValidStyle(visorColor, 'background-image')) {
				this._cssVariables['--jc-grid-tile-visor-background-image'] = visorColor;
			}
		}
		this._visorColor = visorColor;
	}
	@api get visorColorHover() {
		return this._visorColorHover;
	}
	set visorColorHover(visorColorHover) {
		if (!isEmpty(visorColorHover)) {
			if (isValidStyle(visorColorHover, 'color')) {
				this._cssVariables['--jc-grid-tile-visor-background-color-hover'] = visorColorHover;
			} else if (isValidStyle(visorColorHover, 'background-image')) {
				this._cssVariables['--jc-grid-tile-visor-background-image-hover'] = visorColorHover;
			}
		}
		this._visorColorHover = visorColorHover;
	}
	@wire(MessageContext)
	messageContext;
	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
		if (isEmpty(this._searchSubscription) && !isEmpty(this.searchIdentifier)) {
			this._searchSubscription = subscribe(this.messageContext, SELECTED_CHANNEL, (event) =>
				this.handleSearch(event)
			);
		}
	}
	renderedCallback() {
		// FIXME need to figure how to set css variables properly
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
	}
	disconnectedCallback() {
		unsubscribe(this._searchSubscription);
		this._searchSubscription = null;
	}
	handleSearch = (event) => {
		if (event.identifier === this.searchIdentifier) {
			this.pageNumber = 1;
		}
	};
	handleSortChange = (event) => {
		this.pageNumber = 1;
		this.dispatchEvent(
			new CustomEvent('sortchange', {
				detail: event.detail
			})
		);
	};
	handlePaginationChange = (event) => {
		this.pageNumber = event.detail.pageNumber;
		this.pageSize = event.detail.pageSize;
		this.dispatchEvent(
			new CustomEvent('paginationchange', {
				detail: {
					pageNumber: this.pageNumber,
					pageSize: this.pageSize
				}
			})
		);
	};
	handleClick = (event) => {
		this.dispatchEvent(
			new CustomEvent('tileclick', {
				detail: this.items[event.currentTarget.dataset.index]
			})
		);
	};
}
