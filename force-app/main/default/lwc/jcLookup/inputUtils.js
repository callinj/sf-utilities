import { normalizeString } from 'c/jcUtils';
const VARIANT = {
	STANDARD: 'standard',
	LABEL_HIDDEN: 'label-hidden',
	LABEL_STACKED: 'label-stacked',
	LABEL_INLINE: 'label-inline'
};

const normalizeVariant = (value) => {
	return normalizeString(value, {
		fallbackValue: VARIANT.STANDARD,
		validValues: [VARIANT.STANDARD, VARIANT.LABEL_HIDDEN, VARIANT.LABEL_STACKED, VARIANT.LABEL_INLINE]
	});
};
export { VARIANT, normalizeVariant };
