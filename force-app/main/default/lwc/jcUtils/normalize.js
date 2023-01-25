const normalizeString = (value, config = {}) => {
	const { fallbackValue = '', validValues, toLowerCase = true } = config;
	let normalized = (typeof value === 'string' && value.trim()) || '';
	normalized = toLowerCase ? normalized.toLowerCase() : normalized;
	if (validValues && validValues.indexOf(normalized) === -1) {
		normalized = fallbackValue;
	}
	return normalized;
};
const normalizeBoolean = (value) => {
	return typeof value === 'string' || !!value;
};
const normalizeArray = (value) => {
	if (Array.isArray(value)) {
		return value;
	}
	return [];
};
const normalizeAriaAttribute = (value) => {
	let arias = Array.isArray(value) ? value : [value];
	arias = arias
		.map((ariaValue) => {
			if (typeof ariaValue === 'string') {
				return ariaValue.replace(/\s+/g, ' ').trim();
			}
			return '';
		})
		.filter((ariaValue) => !!ariaValue);

	return arias.length > 0 ? arias.join(' ') : null;
};
export { normalizeString, normalizeBoolean, normalizeArray, normalizeAriaAttribute };
