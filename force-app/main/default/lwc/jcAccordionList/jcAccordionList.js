import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const SPACING_TIGHT = 'slds-var-m-vertical_small';
const SPACING_DEFAULT = 'slds-var-m-vertical_large';

export default class JcAccordionList extends NavigationMixin(LightningElement) {
	// Private Properties
	_items;
	_tightenSpacing;

	// Private Reactive Properties
	spacingClass = SPACING_DEFAULT;
	showPreviewModal = false;
	selectedId;
	selectedTitle;
	previousElement;

	get showStats() {
		return this.showViews || this.showDate || this.showTopics;
	}

	// Public Properties
	@api showDescription = false;
	@api showViews = false;
	@api showDate = false;
	@api showTopics = false;
	@api showViewArticle = false;
	@api enablePreview = false;
	@api sortOptions;
	@api defaultSort;

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

	handleUpdate = (event) => {
		this.dispatchEvent(
			new CustomEvent('update', {
				detail: event.detail
			})
		);
	};
	navigateToRecord = () => {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.selectedId,
				actionName: 'view'
			}
		});
	};
}
