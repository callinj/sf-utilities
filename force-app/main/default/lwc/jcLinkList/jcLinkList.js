import { LightningElement, api } from 'lwc';

export default class JcLinkList extends LightningElement {
	// Private Properties
	_items;

	// Private Reactive Properties
	get list() {
		return this.displayType === 'List';
	}
	get inline() {
		return this.displayType === 'Inline Text';
	}
	get verticalRule() {
		return this.separator === '|';
	}

	// Public Properties
	@api separator = '|';
	@api displayType = 'List';
	@api showFollow = false;

	@api
	get items() {
		return this._items;
	}
	set items(value) {
		this._items = value;
	}

	handleFollowChange() {
		this.dispatchEvent(new CustomEvent('followchange'));
	}
}
