import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { convertIcon } from 'c/jcUtils';

const SPACING_TIGHT = 'slds-var-m-vertical_small';
const SPACING_DEFAULT = 'slds-var-m-vertical_large';

export default class JcBasicList extends NavigationMixin(LightningElement) {
	// Private properties
	_items;
	_showSummary = false;

	// Private reactive properties
	spacingClass = SPACING_DEFAULT;
	iconName;
	iconLabel;
	iconPosition = 'Left';
	showPreviewModal = false;
	articleId;
	articleTitle;
	previousElement = null;
	fontColor = getComputedStyle(document.body).getPropertyValue('--lwc-colorTextDefault');

	get showFeatured() {
		return this.featuredText?.length > 0;
	}
	get iconLeft() {
		return this.iconPosition === 'Left';
	}
	get iconRight() {
		return this.iconPosition === 'Right';
	}
	get iconBoth() {
		return this.iconPosition === 'Both';
	}

	// Public properties
	// TODO | Only for Topic List component
	// TODO | Create separate 'IMP' todo item
	@api showFollowerCount = false;
	@api showArticleCount = false;
	@api showDiscussionCount = false;
	@api showFollowButton = false;
	@api showFollowSeparator = false;
	@api alignFollowSeparator = false;
	@api topicList = false;
	@api sortOptions;
	@api defaultSort;

	// TODO | Only for Article List Component
	@api showViews = false;
	@api showDate = false;
	@api showTopics = false;
	@api articleList = false;
	@api enablePreview = false;

	@api get items() {
		return this._items;
	}
	set items(items) {
		this._items = items;
	}
	@api get tightenSpacing() {
		return this._tightenSpacing;
	}
	set tightenSpacing(tightenSpacing) {
		this._tightenSpacing = tightenSpacing;
		this.spacingClass = tightenSpacing ? SPACING_TIGHT : SPACING_DEFAULT;
	}
	@api get showSummary() {
		return this._showSummary;
	}
	set showSummary(showSummary) {
		this._showSummary = showSummary;
	}
	@api get featuredText() {
		return this._featuredText;
	}
	set featuredText(featuredText) {
		this._featuredText = featuredText;
		if (featuredText) {
			let icon = convertIcon(featuredText);
			this.iconLabel = icon.iconLabel;
			this.iconName = icon.iconName;
			this.iconPosition = icon.iconPosition;
		}
	}

	// Navigates user to recordPage via id of current item
	navigateToRecord = () => {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.articleId,
				actionName: 'view'
			}
		});
	};

	openPreview(event) {
		this.previousElement = this.template.activeElement;
		this.articleId = event.target.dataset.id;
		this.articleTitle = event.target.dataset.title;
		this.showPreviewModal = true;
	}
	closePreview() {
		this.showPreviewModal = false;
		this.previousElement.focus();
	}

	handleUpdate = (event) => {
		this.dispatchEvent(
			new CustomEvent('update', {
				detail: event.detail
			})
		);
	};
}
