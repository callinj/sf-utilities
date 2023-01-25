import { LightningElement, api } from 'lwc';
import { splitString } from 'c/jcUtils';

const DEFAULT_CLASS = 'spacer';

export default class JCSpacer extends LightningElement {
	// Private properties
	_customClass;
	_size;

	// Private reactive properties
	spacerClass = 'jc-component';

	// Public properties
	@api rule = false;
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	@api get size() {
		return this._size;
	}
	set size(size) {
		this._size = size;
		switch (size.toLowerCase()) {
			case 'xxx-small':
				this.spacerClass += ' xxx-small-space';
				break;
			case 'xx-small':
				this.spacerClass += ' slds-var-p-vertical_xxx-small';
				break;
			case 'x-small':
				this.spacerClass += ' slds-var-p-vertical_xx-small';
				break;
			case 'small':
				this.spacerClass += ' small-space';
				break;
			case 'large':
				this.spacerClass += ' slds-var-p-vertical_small';
				break;
			case 'x-large':
				this.spacerClass += ' slds-var-p-vertical_medium';
				break;
			case 'xx-large':
				this.spacerClass += ' slds-var-p-vertical_large';
				break;
			case 'xxx-large':
				this.spacerClass += ' slds-var-p-vertical_x-large';
				break;
			case 'xxxx-large':
				this.spacerClass += ' slds-var-p-vertical_xx-large';
				break;
			case 'medium':
			default:
				this.spacerClass += ' slds-var-p-vertical_x-small';
				break;
		}
	}
	connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
	}
}
