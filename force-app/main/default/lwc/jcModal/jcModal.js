import { LightningElement, api } from 'lwc';

const MODAL_CLASS = 'slds-modal slds-fade-in-open';
const CANCEL_BUTTON = 'Cancel';
const ACCEPT_BUTTON = 'Accept';

export default class JcModal extends LightningElement {
	// Private Properties
	_size = 'medium';
	_cancelButton = CANCEL_BUTTON;
	_acceptButton = ACCEPT_BUTTON;

	// Private Reactive Properties
	modalClass = MODAL_CLASS;

	get headerSlot() {
		return this.template.querySelector('slot[name=title]');
	}
	get header() {
		return this.template.querySelector('header');
	}

	// Public Properties
	@api title;

	@api get size() {
		return this._size;
	}
	set size(size) {
		this._size = size;
	}
	@api get cancelButton() {
		return this._cancelButton;
	}
	set cancelButton(cancelButton) {
		this._cancelButton = cancelButton ? cancelButton : CANCEL_BUTTON;
	}
	@api get acceptButton() {
		return this._acceptButton;
	}
	set acceptButton(acceptButton) {
		this._acceptButton = acceptButton ? acceptButton : ACCEPT_BUTTON;
	}
	connectedCallback() {
		this.modalClass += ` slds-modal_${this.size}`;
	}
	renderedCallback() {
		if (this.headerSlot?.assignedElements().length > 0 || this.title) {
			this.header.classList.remove('slds-modal__header_empty');
		}
		this.template.querySelector('slds-modal__container')?.focus();
	}

	handleCancel() {
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	handleAccept() {
		this.dispatchEvent(new CustomEvent('accept'));
	}
}
