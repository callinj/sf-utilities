import { api } from 'lwc';
import { splitString, alignConvert } from 'c/jcUtils';
import JcRecordUtils from 'c/jcRecordUtils';

const DEFAULT_CLASS = 'brandedText';
const DEFAULT_HEADING = 'H1';
const HEADING_MARGIN = '';
const PARAGRAPH_MARGIN = '';
const TOP_MARGIN = '';
const TEXT_UPPER = 'text-upper';
const TEXT_LOWER = 'text-lower';
const TEXT_CAP = 'text-cap';
const BOLD = 'bold';

export default class JCText extends JcRecordUtils {
	// Private properties
	_customClass;
	@api flexipageRegionWidth;
	_align = 'Left';
	_noSpace = false;
	_truncation;
	_bold = false;
	_darkFont = true;
	_removeMargin;

	// Private reactive properties
	type = DEFAULT_HEADING.toLowerCase();
	contentClass = '';
	textClass = 'jc-component';
	h1 = false;
	h2 = false;
	h3 = false;
	h4 = false;
	h5 = false;
	h6 = false;
	text;
	truncateClass = '';
	get isHeading() {
		return !this.type.includes('p');
	}
	get align() {
		if (this._align) {
			this.contentClass += ` slds-text-align_${this._align.toLowerCase()}`;
		}
		return alignConvert(this._align);
	}
	get loaded() {
		return this.converted;
	}
	// Public properties
	@api recordId;
	@api get contentType() {
		return this.type;
	}
	set contentType(contentType) {
		const typeSplit = splitString(contentType, '.', 'strip');
		const type = contentType != null ? typeSplit[0].toLowerCase() : DEFAULT_CLASS.toLowerCase();
		this.type = type;
		this.contentClass += typeSplit[1] !== undefined ? ` ${typeSplit[1]}` : '';
		if (this.isHeading) {
			this[type] = true;
			this.textClass += ` ${HEADING_MARGIN}`;
			if (type === 'h1') {
				this.textClass += ` ${TOP_MARGIN}`;
			}
		} else {
			this.textClass += ` ${PARAGRAPH_MARGIN}`;
		}
	}
	@api get contentText() {
		return this.text;
	}
	set contentText(contentText) {
		this.text = contentText?.toString();
	}
	@api get contentAlign() {
		return this._align;
	}
	set contentAlign(contentAlign) {
		this._align = contentAlign;
	}
	@api get contentTransform() {
		return 'None';
	}
	set contentTransform(contentTransform) {
		switch (contentTransform) {
			case 'Capitalize':
				this.contentClass += ` ${TEXT_CAP}`;
				break;
			case 'Uppercase':
				this.contentClass += ` ${TEXT_UPPER}`;
				break;
			case 'Lowercase':
				this.contentClass += ` ${TEXT_LOWER}`;
				break;
			default:
				break;
		}
	}
	@api get noSpace() {
		return this._noSpace;
	}
	set noSpace(noSpace) {
		this._noSpace = noSpace;
		this.classList.toggle('no-space', noSpace);
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
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}
	@api get truncation() {
		return this._truncation;
	}
	set truncation(truncation) {
		this._truncation = truncation;
		switch (truncation) {
			case 'None':
				break;
			case '1':
				this.contentClass += ` slds-line-clamp_xx-small`;
				break;
			case '2':
				this.contentClass += ` slds-line-clamp_x-small`;
				break;
			case '3':
				this.contentClass += ` slds-line-clamp_small`;
				break;
			case '5':
				this.contentClass += ` slds-line-clamp_medium`;
				break;
			case '7':
				this.contentClass += ` slds-line-clamp_large`;
				break;
			default:
				break;
		}
	}
	@api get bold() {
		return this._bold;
	}
	set bold(bold) {
		this._bold = bold;
		if (bold) {
			this.classList.add(`${BOLD}`);
			// this.contentClass += ` ${BOLD}`;
		} else {
			this.classList.remove(`${BOLD}`);
			// this.contentClass = this.contentClass.replace(` ${BOLD}`, '');
		}
	}
	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		this._darkFont = darkFont;
		if (!darkFont) {
			this.classList.add('lightFont');
		}
	}
	async connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
		this.stringsToConvert.set('text', this.text);
		if (!this.loaded) {
			this.convertStrings();
		}
	}
}
