import { LightningElement, api } from 'lwc';

const DEFAULT_CLASSES = 'jc-banner';

export default class JCBanner extends LightningElement {
	// Private properties
	_customClass = DEFAULT_CLASSES;

	// Private reactive properties

	// Public properties
	@api recordId;
	@api heading;
	@api description;
	@api firstActionText;
	@api firstActionUrl;
	@api firstActionVariant;
	@api firstActionColor;
	@api secondActionText;
	@api secondActionUrl;
	@api secondActionVariant;
	@api secondActionColor;
	@api borderRadius;
	@api borderThickness;
	@api contentAlign;
	@api textAlign;
	@api truncationHeading;
	@api truncationDescription;
	@api imageUrl;
	@api backgroundSize;
	@api backgroundRepeat;
	@api backgroundAttachment;
	@api backgroundPosition;
	@api visorColor;
	@api visorOpacity;
	@api darkFont;
	@api blendMode;
	@api bannerHeight;
	@api hasBorder;
	@api hasRoundedCorners;
	@api hasShadow;
	@api removeMargin;
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass += customClass ? ` ${customClass}` : '';
	}
	connectedCallback() {
		this.classList.add(...this.customClass.split(' '));
	}
}
