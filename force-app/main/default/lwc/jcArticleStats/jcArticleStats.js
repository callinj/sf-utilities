import { LightningElement, api } from 'lwc';

export default class JcArticleStats extends LightningElement {
	// Private Properties

	// Private Reactive Properties
	fontColor = getComputedStyle(document.body).getPropertyValue('--lwc-colorTextDefault');

	get views() {
		return this.record.views ? this.record.views : 0;
	}
	get date() {
		return this.record.lastPublishedDate;
	}
	get topics() {
		return this.record.assignedTopics;
	}
	get viewsLabel() {
		return this.views === 1 ? 'View' : 'Views';
	}
	get showDateHyphen() {
		return this.showViews;
	}
	get showTopicHyphen() {
		return this.showDate || this.showViews;
	}
	get displayTopics() {
		return this.showTopics && this.topics;
	}

	// Public Properties
	@api disableActions = false;
	@api showViews = false;
	@api showDate = false;
	@api showTopics = false;
	@api record;

	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		this._darkFont = darkFont;
		this.fontColor = darkFont ? 'black' : 'white';
	}
}
