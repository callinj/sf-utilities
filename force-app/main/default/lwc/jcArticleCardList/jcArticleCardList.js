import { api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { splitString, isEmpty } from 'c/jcUtils';
import JcArticleListUtils from 'c/jcArticleListUtils';

const DEFAULT_CLASSES = 'jc-article-card-list';

// TODO Clean up order of variables and methods
// TODO Look for some optimizations
export default class JCArticleCardList extends NavigationMixin(JcArticleListUtils) {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_definedTopics;
	_backToTop = false;
	_listType = 'list';

	// Private reactive properties
	currentArticle = {};
	// TODO add action click that comes from the tile
	showPreviewModal = false;

	// Public properties
	@api articleType;
	@api showViews = false;
	@api showDate = false;
	@api showTopics = false;
	@api showSummary = false;
	@api paginationLocation;
	@api largeButtons = false;
	@api enablePreview = false;
	@api defaultBackground;
	@api contentAlign;
	@api textAlignment;
	@api truncateTitle;
	@api truncateSummary;
	@api imageScale;
	@api imagePosition;
	@api searchIdentifier;
	@api borderRadius;
	@api visorBlendMode;
	@api showBorder = false;
	@api showSortOptions;
	@api defaultSortOrder;
	@api topicPosition;
	@api columns;
	@api previousButton;
	@api nextButton;
	@api showAsButtons;
	@api topicCount;
	@api iconColor;
	@api visorColor;
	@api visorOpacity;
	@api darkFont;
	@api borderColor;
	@api imageHeight;
	@api gutterSize;
	@api zeroStateMessage;
	@api iconHoverColor;
	@api visorColorHover;
	@api tileIcon;
	@api tileHoverIcon;

	@api get pageSizeOptions() {
		return this._pageSizeOptions;
	}
	set pageSizeOptions(pageSizeOptions) {
		if (pageSizeOptions) {
			this._pageSizeOptions = pageSizeOptions;
			this.pageSize = parseInt(pageSizeOptions?.split(',')[0], 10);
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
	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}

	@api get backToTop() {
		return this._backToTop;
	}
	set backToTop(backToTop) {
		this._backToTop = backToTop;
	}
	closePreview() {
		this.showPreviewModal = false;
		this.previousElement.focus();
	}
	handleTileClick = (event) => {
		this.currentArticle = event.detail;
		if (this.enablePreview) {
			this.previousElement = this.template.activeElement;
			this.showPreviewModal = true;
		} else {
			this.navigateToRecord();
		}
	};
	navigateToRecord = () => {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.currentArticle.id,
				actionName: 'view'
			}
		});
	};
}
