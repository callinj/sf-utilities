import { LightningElement, api } from 'lwc';
import {
	convertedProperty,
	isEmpty,
	isInBuilder,
	isValidStyle,
	cssColor,
	convertOpacity,
	splitString,
	randomString
} from 'c/jcUtils';

const DEFAULT_CLASS = 'jcBackground';
const BACKGROUND_CLASS = 'background';
const VISOR_CLASS = `${BACKGROUND_CLASS}-visor`;

export default class JcBackground extends LightningElement {
	// Private properties
	_boundaryOffset;
	_customClass = DEFAULT_CLASS;
	_fullPage = false;
	_backgroundElement;
	_backgroundAttachment;
	_backgroundRepeat = 'no-repeat';
	get _offsetObject() {
		return this._boundaryOffset;
	}
	get _backgroundPosition() {
		return this.backgroundPosition
			? splitString(this.backgroundPosition?.toLowerCase(), '-', 'strip').join(' ')
			: null;
	}

	// Private reactive properties
	backgroundClass = BACKGROUND_CLASS;
	visorClass = VISOR_CLASS;
	builderClass;
	get showVisor() {
		return this.visorOpacity && this.visorOpacity !== '0' && !isEmpty(this.visorColor);
	}

	// Public properties
	@api imageUrl;
	@api backgroundSize;
	@api backgroundPosition = 'Top - Left';
	@api visorColor;
	@api visorOpacity = '.5';

	@api blendMode = 'Normal';
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass += customClass ? ` ${customClass}` : '';
	}
	@api get fullPage() {
		return this._fullPage;
	}
	set fullPage(fullPage) {
		// fullPage = fullPage && !isInBuilder();
		this._fullPage = fullPage;
		if (fullPage) {
			this.classList.add('full-page');
		}
	}
	@api get backgroundRepeat() {
		return this._backgroundRepeat;
	}
	set backgroundRepeat(backgroundRepeat) {
		this._backgroundRepeat = backgroundRepeat.toLowerCase();
	}
	@api get backgroundAttachment() {
		return this._backgroundAttachment;
	}
	set backgroundAttachment(backgroundAttachment) {
		// if (backgroundAttachment != 'None') {
		this._backgroundAttachment = backgroundAttachment?.toLowerCase();
		// }
	}
	@api get boundaryOffset() {
		return this._boundaryOffset;
	}
	set boundaryOffset(boundaryOffset) {
		this._boundaryOffset = new convertedProperty(boundaryOffset);
	}
	connectedCallback() {
		if (isInBuilder) {
			this.builderClass = ' jc-in-builder-' + randomString();
			// FIXME rework the reassignment of a public property
			// eslint-disable-next-line @lwc/lwc/no-api-reassignments
			this.customClass += this.builderClass;
		}
		this.classList.add(...this.customClass.split(' '));
		if (this.fullPage) {
			window.addEventListener('resize', this.resizeBackground.bind(this));
		}
	}
	renderedCallback() {
		// const component = this.template.firstChild;
		// console.log('class == ', this.builderClass);
		// console.log('this.template test == ', this.template.querySelector(`.${this.builderClass}`));
		// console.log('this.template == ', this.template);
		// console.log('component == ', component);
		// console.log('component parent == ', component.parentElement);
		this._backgroundElement = this.template.querySelector(`.${BACKGROUND_CLASS}`);
		if (!isEmpty(this.imageUrl)) {
			this._backgroundElement.style.backgroundImage = `url('${this.imageUrl}')`;
		}
		this._backgroundElement.style.backgroundSize = this.backgroundSize ? this.backgroundSize : null;
		this._backgroundElement.style.backgroundPosition = this._backgroundPosition;
		if (!isEmpty(this.backgroundAttachment)) {
			this._backgroundElement.style.backgroundAttachment = this.backgroundAttachment;
		}
		if (isValidStyle(this.backgroundRepeat, 'backgroundRepeat')) {
			this._backgroundElement.style.backgroundRepeat = this.backgroundRepeat;
		}
		if (!isEmpty(this._offsetObject)) {
			this._backgroundElement.style.height =
				'calc(100% + ' + this._offsetObject.top.value + ' + ' + this._offsetObject.bottom.value + ')';
			this._backgroundElement.style.top = this._offsetObject.top.inverse;
			if (!this.fullPage) {
				this._backgroundElement.style.left = this._offsetObject.left.inverse;
				this._backgroundElement.style.width =
					'calc(100% + ' + this._offsetObject.left.value + ' + ' + this._offsetObject.right.value + ')';
			}
		}
		if (this.showVisor) {
			const visor = this.template.querySelector(`.${VISOR_CLASS}`);
			if (isValidStyle(this.visorColor)) {
				let backColor = cssColor(this.visorColor);
				visor.style.backgroundColor = backColor.toRgbaString();
			} else {
				visor.style.backgroundImage = this.visorColor?.toLowerCase();
			}
			visor.style.mixBlendMode = this.blendMode?.toLowerCase();
			visor.style.opacity = convertOpacity(this.visorOpacity);
		}
		if (this.fullPage) {
			this.resizeBackground();
		}
	}
	resizeBackground = () => {
		if (this._backgroundElement) {
			this._backgroundElement.style.left = this.getBoundingClientRect().x * -1 + 'px';
		}
	};
}
