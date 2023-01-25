import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// const CURRENT_USER_KEY = 'CurrentUser';
// const BEGIN_KEY = '';
// const END_KEY = '';
// const FIELD_KEY = '[a-zA-Z0-9_]+';
// const OBJECT_KEY = `(${FIELD_KEY}\\.)`;
// const FIELD_REGEX = new RegExp(`${BEGIN_KEY}${OBJECT_KEY}+(${FIELD_KEY})${END_KEY}`, 'g');
// const USER_REGEX = new RegExp(`${BEGIN_KEY}${CURRENT_USER_KEY}\\.${OBJECT_KEY}*(${FIELD_KEY})${END_KEY}`, 'g');
// const USER_REPLACE_REGEX = new RegExp(`${CURRENT_USER_KEY}`, 'g');
// const REPLACE_REGEX = new RegExp(`${BEGIN_KEY}${OBJECT_KEY}|${END_KEY}`, 'g');
// const EXPRESSION_REGEX = new RegExp(`${BEGIN_KEY}|${END_KEY}`, 'g');
const LARGE_SIZE = 1024;
const MEDIUM_SIZE = 768;
const LEFT_ICON = new RegExp('^([a-zA-Z]+):([a-zA-Z]+)', 'g');
const RIGHT_ICON = new RegExp('([a-zA-Z]+):([a-zA-Z]+)$', 'g');

const showToast = (variant, message, title, mode) => {
	if (!title) {
		title = variant.toLowerCase() === 'error' ? 'Error' : 'Success';
	}
	const event = new ShowToastEvent({
		title: title,
		message: message,
		variant: variant,
		mode: mode
	});
	dispatchEvent(event);
};
// const setLabel = (label) => {
// 	let labelRegex = /^{\$Label\.([a-zA-Z0-9_]*\.){1}([a-zA-Z0-9_]+)}$/;
// 	if (label !== undefined && label !== '' && labelRegex.test(label)) {
// 		label = eval(`$A.get("$Label.c.testLabel");`);
// 	} else {
// 		label = 'This is an invalid label. Please check it.';
// 	}
// 	return label;
// };
const formatText = (text, ...args) => {
	for (let x = 0; x < args.length; x++) {
		text = text.replace(`{${x}}`, args[x]);
	}
	return text;
};

/**
 * Get param that is passed through the url
 *
 * @author Joe Callin
 * @param requestedParam name of the url parameter to pull from the url
 * @return returns the value of the passed parameter
 * @since 1.0
 */
const getUrlParam = (requestedParam) => {
	const urlParams = new URLSearchParams(window.location.search);
	let paramValue = null;
	if (urlParams && requestedParam && urlParams.has(requestedParam)) {
		paramValue = urlParams.get(requestedParam);
	}
	return paramValue;
};
const isInBuilder = () => {
	let urlToCheck = window.location.hostname;
	urlToCheck = urlToCheck.toLowerCase();
	return (
		urlToCheck.indexOf('sitepreview') >= 0 ||
		urlToCheck.indexOf('livepreview') >= 0 ||
		urlToCheck.indexOf('--live') >= 0
	);
};
const filterItemsOnProp = (items, props, query) => {
	return items.filter(function (item) {
		let found = false;
		props.forEach((prop) => {
			if (item[prop] && item[prop].toLowerCase().indexOf(query.toLowerCase()) !== -1) {
				found = true;
			}
		});
		return found;
	});
};
const setSessionStorage = (prop, value) => {
	sessionStorage.setItem(prop, JSON.stringify(value));
};
const getSessionStorage = (prop) => {
	return JSON.parse(sessionStorage.getItem(prop));
};
const removeSessionStorage = (prop) => {
	sessionStorage.removeItem(prop);
};
const proxyLog = (label, input) => {
	console.log(label, JSON.parse(JSON.stringify(input)));
};
const capitalize = (string) => {
	return typeof string === 'string' ? string.charAt(0).toUpperCase() + string.slice(1) : '';
};
const isEmpty = (value) => {
	let empty = true;
	switch (typeof value) {
		case 'object':
			empty = value === null || !Object.keys(value)?.length;
			break;
		case 'string':
			empty = !value.length;
			break;
		case 'boolean':
			empty = value;
			break;
		case 'number':
			empty = isNaN(value);
			break;
		default:
			empty = true;
	}
	return empty;
};

// const isObjectEmpty = (value) => {}

// const isArrayEmpty = (value) => {}
const stripAllSpaces = (string) => {
	if (!isEmpty(string)) {
		string = string?.replace(/\s+/g, '');
	}
	return string ?? null;
};
/**
 * Splits string based on the separator that is passed in and returns an array of strings.
 *
 * @author Joe Callin
 * @param string this is that string that will be split into an array
 * @param separator this is that string that will be split into an array
 * @param spaceOption can be set to 'strip' or 'trim' and will either trim or strip whitespace based on that option.
 * @return array of strings that was split from the passed in sting
 * @since 1.0
 */
const splitString = (string, separator, spaceOption) => {
	let splitArray = null;
	if (spaceOption && !isEmpty(string)) {
		if (spaceOption === 'strip') {
			string = stripAllSpaces(string);
		}
		if (spaceOption === 'trim') {
			const list = string?.split(separator);
			for (let index = 0; index < list?.length; index++) {
				const item = list[index]?.trim();
				if (index === 0) {
					splitArray = [];
				}
				if (item) {
					splitArray.push(item);
				}
			}
		}
	}
	splitArray = splitArray ?? string?.split(separator);
	return splitArray ?? null;
};

const alignConvert = (alignment) => {
	let position;
	if (alignment) {
		switch (alignment.toLowerCase()) {
			case 'center':
			case 'middle':
				position = 'center';
				break;
			case 'right':
			case 'bottom':
			case 'end':
				position = 'end';
				break;
			default:
				break;
		}
	}
	return position;
};

const convertIcon = (text) => {
	let splitText = text?.split(' ');
	let name;
	let label;
	let position = 'Left';
	let isLeft = LEFT_ICON.test(text);
	let isRight = RIGHT_ICON.test(text);

	position = isLeft && isRight ? 'Both' : isLeft ? 'Left' : 'Right';

	splitText?.forEach((value) => {
		if (value.includes(':')) {
			name = value;
		} else {
			label = value;
		}
	});
	return { iconName: name, iconLabel: label, iconPosition: position };
};
const parseString = (string) => {
	const regex = new RegExp('([a-zA-Z]+:[a-zA-Z]+)', 'g');
	let splitArray = string?.split(regex).filter((item) => item.trim() !== '');
	let textArray = [];
	let stringDetails = {};
	splitArray?.forEach((item) => {
		item = item.trim();
		if (item.match(regex)) {
			let iconProp = 'rightIcon';
			if (textArray.length === 0) {
				iconProp = 'leftIcon';
			}
			stringDetails[iconProp] = item;
		} else {
			textArray.push(item);
		}
	});
	stringDetails.text = textArray.join(' ');
	return stringDetails;
};
const calculateValues = (value) => {
	const parts = {};
	[parts.original, parts.leftParen, parts.value, parts.type, parts.rightParen] = value.match(
		/(\()?([-\d.%]*)([a-zA-Z]*)(\))?/
	);
	let valueType = parts.type ? parts.type : 'px';
	return {
		value: +!parts.rightParen ? parseFloat(parts.value) + valueType : parts.original,
		inverse: !parts.rightParen ? parseFloat(parts.value) * -1 + valueType : '-' + parts.original
	};
};
class convertedProperty {
	constructor(propertyValue) {
		if (propertyValue) {
			let propertyValueList = splitString(propertyValue, ' ', 'trim').slice(0, 4);
			this.top = calculateValues(propertyValueList[0]);
			this.right = propertyValueList[1] !== undefined ? calculateValues(propertyValueList[1]) : this.top;
			this.bottom = propertyValueList[2] !== undefined ? calculateValues(propertyValueList[2]) : this.top;
			this.left = propertyValueList[3] !== undefined ? calculateValues(propertyValueList[3]) : this.right;
		}
	}
}
const isValidStyle = (value, property = 'color') => {
	const style = new Option().style;
	style[property] = value;
	return style[property] !== '';
};
const columnSizes = (columns = 1, base = 12) => {
	console.log('column sizes');
	columns = parseInt(columns, 10);
	columns = columns > 1 && columns < base ? columns : 1;
	return {
		size: base,
		medium: columns > 2 ? Math.ceil(base / Math.ceil(columns / 2)) : base / columns,
		large: base / columns
	};
};
const convertRegionInfo = (regionWidth) => {
	let size = 'small';
	if (regionWidth >= LARGE_SIZE) {
		size = 'large';
	} else if (regionWidth >= MEDIUM_SIZE) {
		size = 'medium';
	}
	return `${size}-region`;
};
const trackRegion = (component = this) => {
	window.addEventListener('resize', () => {
		component.regionSize = convertRegionInfo(component.template.firstChild.clientWidth);
	});
	component.regionSize = convertRegionInfo(component.template.firstChild.clientWidth);
};
const randomString = (amount = 5, includeDigits = false) => {
	let result = '';
	var charString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
	let digits = '0123456789';
	if (includeDigits) {
		charString.concat(digits);
	}
	for (let i = 0; i < amount; i++) {
		result += charString.charAt(Math.floor(Math.random() * charString.length));
	}
	return result;
};
const getDOMId = (element) => {
	if (element && typeof element === 'string') {
		return element;
	} else if (element) {
		return element.getAttribute('id');
	}
	return null;
};
export {
	showToast,
	getUrlParam,
	isInBuilder,
	formatText,
	filterItemsOnProp,
	setSessionStorage,
	getSessionStorage,
	removeSessionStorage,
	proxyLog,
	capitalize,
	isEmpty,
	stripAllSpaces,
	splitString,
	alignConvert,
	convertIcon,
	parseString,
	convertedProperty,
	isValidStyle,
	columnSizes,
	trackRegion,
	randomString,
	getDOMId
};
export { cssColor, convertOpacity } from './color';
export { parseIconString, iconCategories, iconsOfCategory, randomIconCategory, randomIcon } from './icon';
export { normalizeBoolean, normalizeString, normalizeArray, normalizeAriaAttribute } from './normalize';
