import { LightningElement, api } from 'lwc';
import { splitString, alignConvert, convertOpacity, isEmpty, isValidStyle, parseIconString } from 'c/jcUtils';

const DEFAULT_CLASSES = 'jc-tile';
const VISOR_CLASS = 'tile-visor';
const CONTENT_CLASS = 'tile-content slds-is-relative';
const MIN_HEIGHT = '250px';
const DEFAULT_VARIANT = 'link';

export default class JCTile extends LightningElement {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_hasRoundedCorners = false;
	_hasBorder = false;
	_hasShadow = false;
	_removeMargin;
	_tileIcon = parseIconString();
	_truncationHeading;
	_truncationDescription;
	_backgroundAttachment;
	_firstActionColor;
	_secondActionColor;
	_darkFont = false;
	_visorColor;
	_visorOpacity = '.5';
	_backgroundRepeat = 'no-repeat';
	_firstActionVariant = DEFAULT_VARIANT;
	_secondActionVariant = DEFAULT_VARIANT;
	_hideOnMobile = true;
	_tileHeight = MIN_HEIGHT;
	_cssVariables = {};
	_actionBorderRadius;

	get _contentAlign() {
		return splitString(this.contentAlign, '-', 'strip');
	}
	get _backgroundPosition() {
		return this.backgroundPosition?.includes('-')
			? splitString(this.backgroundPosition?.toLowerCase(), '-', 'strip').join(' ')
			: this.backgroundPosition;
	}

	// Private reactive properties
	visorClass = VISOR_CLASS;
	contentClass = CONTENT_CLASS;

	get showActions() {
		return this.showFirstAction || this.showSecondAction;
	}
	get showFirstAction() {
		return this.firstActionText && this.firstActionUrl;
	}
	get showSecondAction() {
		return this.secondActionText && this.secondActionUrl;
	}
	get contentVerticalAlign() {
		return this._contentAlign ? alignConvert(this._contentAlign[0]) : null;
	}
	get contentHorizontalAlign() {
		return this._contentAlign ? alignConvert(this._contentAlign[1]) : null;
	}
	get actionAlignment() {
		return alignConvert(this.textAlign);
	}
	get showVisor() {
		return this.visorOpacity && this.visorOpacity !== 0;
	}
	get iconAssertiveText() {
		return `${this.heading} Tile Icon`;
	}

	// Public properties
	@api recordId;
	@api actionDetail;
	@api heading;
	@api description;
	@api firstActionText;
	@api firstActionUrl;
	@api secondActionText;
	@api secondActionUrl;
	@api borderThickness;
	@api imageUrl;
	// @api visorOpacity = '1';
	@api contentAlign = 'Top - Left';
	@api backgroundSize;
	@api backgroundPosition = 'Left - Top';
	@api blendMode = 'Normal';
	@api textAlign = 'Left';
	@api get actionBorderRadius() {
		return this._actionBorderRadius;
	}
	set actionBorderRadius(actionBorderRadius) {
		this._actionBorderRadius = actionBorderRadius;
	}
	@api get tileHeight() {
		return this._tileHeight;
	}

	set tileHeight(value) {
		this._tileHeight = value ? value : this._tileHeight;
	}

	@api get firstActionVariant() {
		return this._firstActionVariant;
	}
	set firstActionVariant(firstActionVariant) {
		this._firstActionVariant = firstActionVariant ? firstActionVariant : DEFAULT_VARIANT;
	}
	@api get firstActionColor() {
		return this._firstActionColor;
	}
	set firstActionColor(firstActionColor) {
		this._firstActionColor = firstActionColor;
	}
	@api get secondActionVariant() {
		return this._secondActionVariant;
	}
	set secondActionVariant(secondActionVariant) {
		this._secondActionVariant = secondActionVariant ? secondActionVariant : DEFAULT_VARIANT;
	}
	@api get secondActionColor() {
		return this._secondActionColor;
	}
	set secondActionColor(secondActionColor) {
		this._secondActionColor = secondActionColor;
	}
	@api get backgroundAttachment() {
		return this._backgroundAttachment;
	}
	set backgroundAttachment(backgroundAttachment) {
		if (backgroundAttachment === 'None') {
			this._backgroundAttachment = backgroundAttachment?.toLowerCase();
		}
	}
	@api get backgroundRepeat() {
		return this._backgroundRepeat;
	}
	set backgroundRepeat(backgroundRepeat) {
		this._backgroundRepeat = backgroundRepeat?.toLowerCase();
	}
	@api get visorColor() {
		return this._visorColor;
	}
	set visorColor(visorColor) {
		if (!isEmpty(visorColor)) {
			if (isValidStyle(visorColor, 'color')) {
				this._cssVariables['--jc-tile-visor-background-color'] = visorColor;
			} else if (isValidStyle(visorColor, 'background-image')) {
				this._cssVariables['--jc-tile-visor-background-image'] = visorColor;
				this.visorClass += ' gradient';
			}
		}
		this._visorColor = visorColor;
	}
	@api get visorOpacity() {
		return this._visorOpacity;
	}
	set visorOpacity(visorOpacity) {
		visorOpacity = convertOpacity(visorOpacity);
		if (!isEmpty(visorOpacity) && isValidStyle(visorOpacity, 'opacity')) {
			this._cssVariables['--jc-tile-visor-opacity'] = visorOpacity;
		}
		this._visorOpacity = visorOpacity;
	}
	@api get truncationHeading() {
		return this._truncationHeading;
	}
	set truncationHeading(truncationHeading) {
		this._truncationHeading = truncationHeading;
	}
	@api get truncationDescription() {
		return this._truncationDescription;
	}
	set truncationDescription(truncationDescription) {
		this._truncationDescription = truncationDescription;
	}
	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		darkFont = !!darkFont;
		this._darkFont = darkFont;
		if (darkFont) {
			this.contentClass += ' darkFont';
		}
	}
	@api get hasRoundedCorners() {
		return this._hasRoundedCorners;
	}
	set hasRoundedCorners(hasRoundedCorners) {
		hasRoundedCorners = !!hasRoundedCorners;
		this._hasRoundedCorners = hasRoundedCorners;
		this.classList.toggle('roundedCorners', hasRoundedCorners);
	}
	@api get hasBorder() {
		return this._hasBorder;
	}
	set hasBorder(hasBorder) {
		hasBorder = !!hasBorder;
		this._hasBorder = hasBorder;
		this.classList.toggle('borders', hasBorder);
	}
	@api get hasShadow() {
		return this._hasShadow;
	}
	set hasShadow(hasShadow) {
		hasShadow = !!hasShadow;
		this._hasShadow = hasShadow;
		this.classList.toggle('shadow', hasShadow);
	}
	@api get removeMargin() {
		return this._removeMargin;
	}
	set removeMargin(removeMargin) {
		removeMargin = !!removeMargin;
		this._removeMargin = removeMargin;
		this.classList.toggle('no-margin', removeMargin);
	}
	@api get tileIcon() {
		return this._tileIcon;
	}
	set tileIcon(tileIcon) {
		tileIcon = parseIconString(tileIcon);
		this._tileIcon = tileIcon;
	}
	@api get borderRadius() {
		return this._borderRadius;
	}
	set borderRadius(borderRadius) {
		if (!isEmpty(borderRadius) && isValidStyle(borderRadius, 'border-radius')) {
			this._cssVariables['--jc-tile-border-radius'] = borderRadius;
		}
		this._borderRadius = borderRadius;
	}
	@api get hideOnMobile() {
		return this._hideOnMobile;
	}
	set hideOnMobile(hideOnMobile) {
		this._customClasses += hideOnMobile ? ' mobile-hide' : '';
		this._hideOnMobile = !!hideOnMobile;
	}
	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}
	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
	}
	renderedCallback() {
		const wrapper = this.template.querySelector(`.jc-component`);
		// TODO fix how I am setting css variables
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component?.style?.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
		if (!isEmpty(this.imageUrl)) {
			wrapper.style.backgroundImage = `url('${this.imageUrl}')`;
		}
		wrapper.style.height = this.tileHeight;
		wrapper.style.backgroundSize = this.backgroundSize ? this.backgroundSize : null;
		wrapper.style.backgroundPosition = this._backgroundPosition;
		if (isValidStyle(this.backgroundRepeat, 'backgroundRepeat')) {
			wrapper.style.backgroundRepeat = this.backgroundRepeat;
		}
		if (!isEmpty(this.backgroundAttachment)) {
			wrapper.style.backgroundAttachment = this.backgroundAttachment;
		}

		// Sets visor color and opacity
		if (this.showVisor) {
			const visor = this.template.querySelector(`.${VISOR_CLASS}`);
			// if (isValidStyle(this.visorColor)) {
			// 	let backColor = cssColor(this.visorColor);
			// 	visor.style.backgroundColor = backColor.toRgbaString();
			// } else {
			// 	visor.style.backgroundImage = this.visorColor?.toLowerCase();
			// }
			visor.style.mixBlendMode = this.blendMode?.toLowerCase();
			// visor.style.opacity = convertOpacity(this.visorOpacity);
		}
	}
	handleSlotChange = (event) => {
		let parentElement = event.target.parentElement;
		if (!parentElement.classList.contains('slds-hide')) {
			parentElement = parentElement.parentElement;
		}
		parentElement.classList.remove('slds-hide');
	};
}
