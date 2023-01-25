import { LightningElement, api } from 'lwc';
import { splitString, alignConvert, parseIconString, trackRegion } from 'c/jcUtils';

const DEFAULT_CLASSES = 'jc-cta';

export default class JCCta extends LightningElement {
	// Private properties
	_customClass = DEFAULT_CLASSES;
	_iconSize = 'Medium';
	_darkFont = true;
	_removeMargin;
	_imageReference;

	// Private reactive properties
	iconName;
	imageSrc;
	regionSize;
	get size() {
		return this._iconSize.toLowerCase();
	}
	get buttonType() {
		return this.showButton ? 'brand' : '';
	}
	get postion1() {
		return this.iconName || this.imageSrc ? splitString(this.iconPosition, '-', 'strip')[0] : null;
	}
	get position2() {
		return splitString(this.iconPosition, '-', 'strip')[1];
	}

	get iconLeft() {
		return this.postion1 === 'Left';
	}
	get iconRight() {
		return this.postion1 === 'Right';
	}
	get iconTop() {
		return this.postion1 === 'Top';
	}
	get iconTopClass() {
		return this.showSection ? 'slds-var-p-bottom_small' : '';
	}
	get iconAlign() {
		return alignConvert(this.position2);
	}
	get contentAlign() {
		return alignConvert(this.textAlign);
	}
	get showContent() {
		return this.heading || this.description || this.showActions;
	}
	get showSection() {
		return this.showContent || this.iconRight || this.iconLeft;
	}
	get showActions() {
		return this.showFirstAction || this.showSecondAction;
	}
	get showFirstAction() {
		return this.firstActionText && this.firstActionUrl;
	}
	get showSecondAction() {
		return this.secondActionText && this.secondActionUrl;
	}
	get imageAssertiveText() {
		return `${this.heading?.replace(/[^A-Za-z0-9\s]/g, '')} Call To Action Image`;
	}

	// Public properties
	@api heading;
	@api description;
	@api firstActionText;
	@api firstActionUrl;
	@api secondActionText;
	@api secondActionUrl;
	@api showButton = false;
	@api iconPosition = 'Left - Middle';
	@api textAlign = 'Left';

	@api get imageReference() {
		return this._imageReference;
	}
	set imageReference(imageReference) {
		this._imageReference = imageReference;
		const parsedIcon = parseIconString(imageReference);
		if (parsedIcon.valid) {
			this.iconName = parsedIcon.formatted;
		} else {
			this.imageSrc = imageReference;
		}
	}
	@api get iconSize() {
		return this._iconSize;
	}
	set iconSize(iconSize) {
		this._iconSize = iconSize;
	}
	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		this._darkFont = darkFont;
	}
	@api get removeMargin() {
		return this._removeMargin;
	}
	set removeMargin(removeMargin) {
		this._removeMargin = removeMargin;
		this.classList.toggle('no-margin', removeMargin);
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass += customClass ? ` ${customClass}` : '';
	}
	connectedCallback() {
		this.classList.add(...this.customClass.split(' '));
	}
	renderedCallback() {
		if (!this.regionSize) {
			trackRegion(this);
		}
	}
}
