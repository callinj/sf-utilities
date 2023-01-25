import { LightningElement, api } from 'lwc';

const DEFAULT_VARIANT = 'text';
const ICON_VARIANT = 'icon';
const TEXT_ALIGN_CENTER = 'slds-text-align_center';
const COMFY = 'around-small';
const COMPACT = 'horizontal-small';
const FOLLOW_CLASS = 'followClass';
const VERTICAL_RULE_CLASS = 'vertical-rule';

export default class JcTopicStats extends LightningElement {
	// Private Properties
	_record;
	_alignment;
	_variant = DEFAULT_VARIANT;
	_showFollowSeparator;
	_alignFollowSeparator;
	_darkFont;
	_followPadding = false;

	// Private Reactive Properties
	verticalRule;
	followStyles = `${FOLLOW_CLASS} ${TEXT_ALIGN_CENTER}`;

	get isIcon() {
		return this._variant === ICON_VARIANT;
	}
	get isDefault() {
		return this._variant === DEFAULT_VARIANT;
	}
	get followers() {
		return this.record.followers ? this.record.followers : 0;
	}
	get articles() {
		return this.record.articles ? this.record.articles : 0;
	}
	get discussions() {
		return this.record.discussions ? this.record.discussions : 0;
	}
	get showStats() {
		return this.showFollowerCount || this.showArticleCount || this.showDiscussionCount;
	}
	get followClass() {
		return this.followStyles;
	}
	get padding() {
		return this.followPadding ? COMFY : COMPACT;
	}
	get followerLabel() {
		return this.followers === 1 ? 'Follower' : 'Followers';
	}
	get articleLabel() {
		return this.articles === 1 ? 'Article' : 'Articles';
	}
	get discussionLabel() {
		return this.discussions === 1 ? 'Discussion' : 'Discussions';
	}

	// Public Properties
	@api showFollowerCount = false;
	@api showArticleCount = false;
	@api showDiscussionCount = false;
	@api showFollowButton = false;
	@api multiLineStats = false;
	@api multiLineFollow = false;

	@api
	get record() {
		return this._record;
	}
	set record(record) {
		this._record = record;
	}
	@api get alignment() {
		return this._alignment;
	}
	set alignment(alignment) {
		this._alignment = alignment;
	}
	@api get variant() {
		return this._variant;
	}
	set variant(variant) {
		this._variant = variant;
	}
	@api get showFollowSeparator() {
		return this._showFollowSeparator;
	}
	set showFollowSeparator(showFollowSeparator) {
		this._showFollowSeparator = showFollowSeparator;
		if (showFollowSeparator && this.showFollowButton) {
			this.verticalRule = VERTICAL_RULE_CLASS;
		}
	}
	@api get alignFollowSeparator() {
		return this._alignFollowSeparator;
	}
	set alignFollowSeparator(alignFollowSeparator) {
		this._alignFollowSeparator = alignFollowSeparator;
		if (alignFollowSeparator) {
			this.followStyles += ` align-follow`;
		}
	}
	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		this._darkFont = darkFont;
		if (this.isIcon) {
			this._darkFont = undefined;
		}
	}
	@api get followPadding() {
		return this._followPadding;
	}
	set followPadding(followPadding) {
		this._followPadding = followPadding;
	}
}
