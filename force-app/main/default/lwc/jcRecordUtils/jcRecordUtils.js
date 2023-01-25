/* eslint-disable no-unsafe-optional-chaining */
import { LightningElement, wire } from 'lwc';
import { showToast, formatText } from 'c/jcUtils';
import { getFieldValue } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import getRecordInfo from '@salesforce/apex/JCRecordUtils.getRecordInfo';

const CURRENT_USER_KEY = 'CurrentUser';
const BEGIN_KEY = '{>';
const END_KEY = '}';
const FIELD_KEY = '[a-zA-Z0-9_]+';
const OBJECT_KEY = `(${FIELD_KEY}\\.)`;
const FIELD_REGEX = new RegExp(`${BEGIN_KEY}${OBJECT_KEY}+(${FIELD_KEY})${END_KEY}`, 'g');
const USER_REGEX = new RegExp(`${BEGIN_KEY}${CURRENT_USER_KEY}\\.${OBJECT_KEY}*(${FIELD_KEY})${END_KEY}`, 'g');
const USER_REPLACE_REGEX = new RegExp(`${CURRENT_USER_KEY}`, 'g');
const REPLACE_REGEX = new RegExp(`${BEGIN_KEY}${OBJECT_KEY}|${END_KEY}`, 'g');
const EXPRESSION_REGEX = new RegExp(`${BEGIN_KEY}|${END_KEY}`, 'g');
const UNDEFINED_PLACEHOLDER = '<span class="slds-text-color_error">{INVALID FIELD: {0}}</span>';
const NULL_PLACEHOLDER = '{null}';

export default class JcRecordUtils extends LightningElement {
	_currentRecord;
	_userId;
	_recordDataConverted = false;
	_userDataConverted = false;
	_recordFieldMap = new Map();
	_userFieldMap = new Map();
	_stringMap = new Map();

	stringsToConvert = new Map();

	get _recordFields() {
		// FIXME optional chaining needs attention
		return [...this._recordFieldMap?.values()];
	}
	get _userFields() {
		// FIXME optional chaining needs attention
		return [...this._userFieldMap?.values()];
	}
	get converted() {
		return this._recordDataConverted && this._userDataConverted;
	}
	get objectInfo() {
		return {
			fields: this._recordFields,
			filters: [
				{
					field: 'Id',
					value: this._currentRecord
				}
			]
		};
	}
	@wire(getRecord, {
		recordId: '$_userId',
		optionalFields: '$_userFields'
	})
	wireUserData({ data, error }) {
		if (data) {
			this.processData(data, this._userFieldMap, true);
			this._userDataConverted = true;
		} else if (error) {
			let message = 'Unknown error';
			if (Array.isArray(error.body)) {
				message = error.body.map((e) => e.message).join(', ');
			} else if (typeof error.body.message === 'string') {
				message = error.body.message;
			}
			showToast('error', message, 'Error loading user information');
			console.error('Error Processing JcRecordUtils.userData: ', message);
			this._userDataConverted = true;
		}
	}
	convertStrings = () => {
		this.stringsToConvert.forEach((string, key) => {
			string?.match(FIELD_REGEX)?.forEach((fieldReference) => {
				this._stringMap.set(key, string);
				if (fieldReference.match(USER_REGEX)) {
					this._userFieldMap.set(
						fieldReference,
						fieldReference.replace(USER_REPLACE_REGEX, 'User').replace(EXPRESSION_REGEX, '')
					);
				} else {
					this._recordFieldMap.set(fieldReference, fieldReference.replace(REPLACE_REGEX, ''));
				}
			});
		});
		if (this._stringMap.size > 0) {
			if (this._recordFieldMap.size > 0) {
				this._currentRecord = this.recordId;
				this.getRecordInfo();
			} else {
				this._recordDataConverted = true;
			}
			if (this._userFieldMap.size > 0) {
				this._userId = userId;
			} else {
				this._userDataConverted = true;
			}
		} else {
			this._recordDataConverted = true;
			this._userDataConverted = true;
		}
	};
	getRecordInfo = () => {
		let params = {
			recordId: this._currentRecord,
			objectInfo: this.objectInfo
		};
		getRecordInfo(params)
			.then((data) => {
				if (data.success) {
					this.processData(data.fields, this._recordFieldMap);
					this._recordDataConverted = true;
				} else {
					showToast('error', data.messages[0], 'Error Message', 'dismissable');
					console.error('Error Processing getRecordInfo: ', data.messages[0]);
				}
			})
			.catch((error) => {
				showToast('error', error, 'Error Message', 'dismissable');
				console.error('Error Processing getRecordInfo: ', error);
			});
	};
	processData = (returnedData, fieldMap, isWire) => {
		this._stringMap.forEach((stringValue, stringKey, stringMap) => {
			fieldMap.forEach((fieldValue, fieldKey) => {
				let currentFieldValue;
				let fieldDetails = {};
				if (isWire) {
					currentFieldValue = getFieldValue(returnedData, fieldValue);
					fieldDetails.isValid = true;
				} else {
					if (returnedData) {
						fieldDetails = returnedData[fieldValue];
						currentFieldValue = fieldDetails?.value;
					}
				}
				if (currentFieldValue !== undefined && fieldDetails.isValid) {
					stringValue = stringValue.replaceAll(
						fieldKey,
						currentFieldValue !== null && currentFieldValue !== '' ? currentFieldValue : NULL_PLACEHOLDER
					);
				} else {
					stringValue = stringValue.replaceAll(fieldKey, formatText(UNDEFINED_PLACEHOLDER, fieldValue));
				}
				stringMap.set(stringKey, stringValue);
			});
			this[stringKey] = stringValue;
		});
	};
}
