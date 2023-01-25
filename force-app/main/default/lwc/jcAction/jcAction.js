import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; // TODO | Enhancement: implement into jcUtils
import { cssColor, isEmpty, splitString, alignConvert, parseString, isValidStyle } from 'c/jcUtils';

const DEFAULT_CLASS = 'brandedAction';
const ICON_CLASS = 'slds-button__icon slds-current-color';
const BLACK = cssColor('black').toRgbString();
const WHITE = cssColor('white').toRgbString();
const REGEX_SALESFORCE = new RegExp('^([a-zA-Z0-9]{15}|[a-zA-Z0-9]{18})$');

export default class JcAction extends NavigationMixin(LightningElement) {
	// TODO Figure out if we want to handle icon buttons and button groups
	// TODO look into util class to add classes dynamically
	// Private properties
	_customClass;
	_action;
	_customColor;
	_hoverColor;
	_activeColor;
	_disableCustom = false;
	_fullWidth;
	_overSized;
	_bold;
	_underline;
	_truncate;
	_setBackgroundColor = false;
	_setBorderColor = false;
	_setTextColor = false;
	_actionAlign;
	_leftIcon;
	_rightIcon;
	_label;
	_borderRadius;
	_cssVariables = {};
	_labelIcons = {
		right: null,
		left: null
	};

	// Private reactive properties
	actionClass = '';
	leftActionIcon;
	rightActionIcon;
	truncateClass;
	buttonVariant;
	icon;
	iconClass = ICON_CLASS;
	iconLeftClass = ICON_CLASS;
	iconRightClass = ICON_CLASS;
	iconSize = 'xx-small';
	flexibility = 'auto';

	get title() {
		return this.label;
	}
	get showLeft() {
		const show = !isEmpty(this.leftActionIcon);
		if (show) {
			this.iconLeftClass += ' slds-button__icon_left';
		}
		return show;
	}
	get showRight() {
		const show = !isEmpty(this.rightActionIcon);
		if (show) {
			this.iconRightClass += ' slds-button__icon_right';
		}
		return show;
	}

	get showAsLink() {
		return !isEmpty(this.url);
	}
	get showAction() {
		if (!this.label) {
			this.actionClass += ` iconOnly`;
		}
		return this.label || this.showLeft || this.showRight;
	}

	// TODO Add support for the Aria labels
	// state = {
	//     accesskey: null,
	//     ariaAtomic: null,
	//     ariaControls: null,
	//     ariaDescribedBy: null,
	//     ariaExpanded: null,
	//     ariaLabel: null,
	//     ariaLive: null,
	//     disabled: false
	// };
	// set accessKey(value) {
	//     this.state.accesskey = value;
	// }
	// @api get accessKey() {
	//     return this.state.accesskey;
	// }

	// Public properties
	// @api label;
	@api disabled;
	// TODO Discuss error card/state. For invalid icon selection
	@api iconName;
	@api iconPosition = 'Left';
	@api url;
	@api borderThickness;
	@api printPage = false;

	@api get borderRadius() {
		return this._borderRadius;
	}
	set borderRadius(borderRadius) {
		if (!isEmpty(borderRadius) && isValidStyle(borderRadius, 'borderRadius')) {
			this._cssVariables['--jc-action-border-radius'] = borderRadius;
		}
		this._borderRadius = borderRadius;
	}

	@api get variant() {
		return this._variant;
	}
	set variant(variant) {
		variant = variant?.replace(/\s+/g, '-').toLowerCase();
		switch (variant) {
			case 'neutral':
				this.actionClass += ' slds-button slds-button_neutral isBare';
				break;
			case 'brand':
				this.actionClass += ' slds-button slds-button_brand';
				break;
			case 'brand-outline':
				this.actionClass += ' slds-button slds-button_outline-brand isBare';
				break;
			case 'destructive':
				this.actionClass += ' slds-button slds-button_destructive';
				this._disableCustom = true;
				break;
			case 'destructive-text':
				this.actionClass += ' slds-button slds-button_text-destructive';
				this._disableCustom = true;
				break;
			case 'inverse':
				this.actionClass += ' slds-button slds-button_inverse';
				break;
			case 'success':
				this.actionClass += ' slds-button slds-button_success';
				this._disableCustom = true;
				break;
			default:
				this.actionClass += this.showAsLink ? ' isBare' : ' slds-button isBare';
				break;
		}
		this._variant = variant;
	}
	@api get label() {
		return this._label;
	}
	set label(label) {
		const parsedLabel = parseString(label);
		this._labelIcons.left = parsedLabel?.leftIcon;
		this._labelIcons.right = parsedLabel?.rightIcon;
		this._label = parsedLabel.text;
	}
	@api get leftIcon() {
		return this._leftIcon;
	}
	set leftIcon(leftIcon) {
		if (!isEmpty(leftIcon) && leftIcon !== ' ') {
			this.leftActionIcon = leftIcon;
			this._leftIcon = leftIcon;
		}
	}
	@api get rightIcon() {
		return this._rightIcon;
	}
	set rightIcon(rightIcon) {
		if (!isEmpty(rightIcon) && rightIcon !== ' ') {
			this.rightActionIcon = rightIcon;
			this._rightIcon = rightIcon;
		}
	}
	@api get actionAlign() {
		return this._actionAlign;
	}
	set actionAlign(actionAlign) {
		this._actionAlign = actionAlign ? alignConvert(actionAlign) : null;
	}
	@api get fullWidth() {
		return this._fullWidth;
	}
	set fullWidth(fullWidth) {
		this._fullWidth = fullWidth;
		if (fullWidth) {
			this.actionClass += ' slds-button_stretch';
			this.flexibility = 'grow';
		}
	}
	@api get overSized() {
		return this._overSized;
	}
	set overSized(overSized) {
		this._overSized = overSized;
		if (overSized) {
			this.actionClass += ' overSized';
			this.iconSize = 'x-small';
		}
	}
	@api get bold() {
		return this._bold;
	}
	set bold(bold) {
		this._bold = bold;
		if (bold) {
			this.actionClass += ' bold';
		} else {
			this.actionClass = this.actionClass.replace(' bold', '');
		}
	}
	@api get underline() {
		return this._underline;
	}
	set underline(underline) {
		this._underline = underline;
		if (underline) {
			this.actionClass += ' underline';
		}
	}
	@api get truncate() {
		return this._truncate;
	}
	set truncate(truncate) {
		this._truncate = truncate;
		if (truncate) {
			this.actionClass += ' slds-truncate';
			this.truncateClass = 'slds-truncate';
		}
	}
	@api get customColor() {
		return this._customColor;
	}
	set customColor(color) {
		let customColor = color ? cssColor(color) : color;
		let hoverColor = color ? cssColor(color) : color;
		let activeColor = color ? cssColor(color) : color;

		if (hoverColor) {
			hoverColor.darker(6.1);
			if (hoverColor.toRgbString() === BLACK) {
				hoverColor.lighter(26.1);
			}
		}

		// Active color not added due to Salesforce out-of-the-box not supporting one
		// if (activeColor) {
		//     activeColor.darker(20);
		// }

		this._customColor = customColor;
		this._hoverColor = hoverColor;
		this._activeColor = activeColor;
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	@api focus() {
		if (this._connected) {
			this._action.focus();
		}
	}
	@api click() {
		if (this._connected) {
			this._action.click();
		}
	}
	connectedCallback() {
		this._connected = true;
		this.classList.add(DEFAULT_CLASS);
		if (this._customColor) {
			this.setColorClasses();
		}
		if (!!isEmpty(this.leftIcon) && !isEmpty(this._labelIcons.left)) {
			this.leftActionIcon = this._labelIcons?.left;
		}
		if (!!isEmpty(this.rightIcon) && !isEmpty(this._labelIcons.right)) {
			this.rightActionIcon = this._labelIcons?.right;
		}
		this.setIconClasses();
	}
	renderedCallback() {
		let selector = this.showAsLink ? 'a' : 'button';
		this._action = this.template.querySelector(selector);
		// TODO fix firstChild issue
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}

		if (this._customColor && !this._disableCustom) {
			this.setColors();
		}

		// if (this.borderRadius) {
		//     this._action.style.borderRadius = this.borderRadius;
		// }
		if (this.borderThickness) {
			this._action.style.borderWidth = this.borderThickness;
		}
	}
	disconnectedCallback() {
		this._connected = false;
	}
	handleFocus = () => {
		this.dispatchEvent(new CustomEvent('focus'));
	};
	handleBlur = () => {
		this.dispatchEvent(new CustomEvent('blur'));
	};
	// TODO build out util that handles any type of navigation
	handleClick = () => {
		if (this.url) {
			if (REGEX_SALESFORCE.test(this.url)) {
				this[NavigationMixin.Navigate]({
					type: 'standard__recordPage',
					attributes: {
						recordId: this.url,
						actionName: 'view'
					}
				});
			} else {
				this[NavigationMixin.Navigate]({
					type: 'standard__webPage',
					attributes: {
						url: this.url
					}
				});
			}
		} else {
			if (this.printPage) {
				window.print();
			}
		}
	};
	handleKeyPress = (event) => {
		if (event.keyCode === 32 || event.keyCode === 13) {
			this.handleClick();
		}
	};
	setColorClasses = () => {
		if (this._customColor && !this._disableCustom) {
			this.actionClass += ' customColor';
			if (!this._customColor.isDark()) {
				this.actionClass += ' darkFont';
			}
			if (!this._hoverColor.isDark()) {
				this.actionClass += ' isHoverLight';
			}
			if (!this._activeColor.isDark()) {
				this.actionClass += ' isActiveLight';
			}
		}
	};

	// Sets the colors to the _customColor based off variant
	setColors = () => {
		switch (this.variant) {
			case 'brand':
				this._action.style.backgroundColor = this._customColor.toRgbString();
				this._action.style.borderColor = this._customColor.toRgbString();
				this._setBackgroundColor = true;
				this._setBorderColor = true;
				// this.createListeners(true, true, false);
				break;
			case 'brand-outline':
				this._action.style.borderColor = this._customColor.toRgbString();
				this._action.style.color = this._customColor.toRgbString();
				this._hoverColor = cssColor(this._customColor.toRgbString(), 0.05);
				this._setBackgroundColor = true;
				this._setBorderColor = true;
				this._setTextColor = true;
				// this.createListeners(true, true, true);
				break;
			case 'neutral':
				this._action.style.color = this._customColor.toRgbString();
				this._hoverColor = cssColor(this._customColor.toRgbString(), 0.05);
				this._setBackgroundColor = true;
				// this.createListeners(true, false, false);
				break;
			case 'inverse':
				this._action.style.color = this._customColor.toRgbString();
				this._action.style.borderColor = this._customColor.toRgbString();
				this._setBackgroundColor = true;
				this._setBorderColor = true;
				// this.createListeners(true, true, false);
				break;
			default:
				this._action.style.color = this._customColor.toRgbString();
				this._setTextColor = true;
				// this.createListeners(false, false, true);
				break;
		}
		this._action.addEventListener('mouseenter', this.setFocusState);
		this._action.addEventListener('focus', this.setFocusState);
		this._action.addEventListener('mouseleave', this.setUnfocusState);
		this._action.addEventListener('blur', this.setUnfocusState);
	};
	setIconClasses = () => {
		if (this.leftActionIcon) {
			this.iconLeftClass += ' slds-button__icon_left';
		}
		if (this.rightActionIcon) {
			this.iconRightClass += ' slds-button__icon_right';
		}
	};
	setFocusState = () => {
		if (this._setBackgroundColor) {
			this._action.style.backgroundColor = this._hoverColor.toRgbaString();
		}
		if (this._setBorderColor) {
			this._action.style.borderColor = this._hoverColor.toRgbString();
		}
		if (this._setTextColor) {
			this._action.style.color = this._hoverColor.toRgbString();
		}
	};
	setUnfocusState = () => {
		if (this._setBackgroundColor) {
			this._action.style.backgroundColor =
				this.variant === 'neutral' || this.variant === 'brand-outline'
					? WHITE
					: this.variant === 'inverse'
					? 'transparent'
					: this._customColor.toRgbString();
		}
		if (this._setBorderColor) {
			this._action.style.borderColor = this._customColor.toRgbString();
		}
		if (this._setTextColor) {
			this._action.style.color = this._customColor.toRgbString();
		}
	};
}
