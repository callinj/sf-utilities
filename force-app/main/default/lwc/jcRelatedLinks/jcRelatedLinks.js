import { LightningElement, api, wire } from 'lwc';
import { isEmpty, showToast } from 'c/jcUtils';
import getRelatedLinks from '@salesforce/apex/JCRelatedLinksController.getRelatedLinks';

const DEFAULT_CLASS = 'jcRelatedLinks';
const DEFAULT_TITLE = 'Resources';
const ZERO_STATE_MESSAGE = 'No Related Links Found';

export default class JcRelatedLinks extends LightningElement {
	// Private Properties
	_zeroStateMessage = ZERO_STATE_MESSAGE;
	_title = DEFAULT_TITLE;
	_customClass = DEFAULT_CLASS;

	// Private Reactive Properties
	relatedLinks = [];
	loaded = false;

	get viewAllLink() {
		return `/relatedlist/${this.recordId}/Related_Links__r`;
	}
	get showViewAll() {
		return this.relatedLinks.length > 5;
	}
	get showRelatedLinks() {
		return this.relatedLinks.length > 0;
	}
	get relatedLinksOptions() {
		let relatedLinksOptions = {
			objectName: 'Related_Links__c',
			fields: ['Id', 'Name', 'Link_Url__c'],
			queryLimit: 5,
			filters: [{ field: 'Knowledge__c', value: this.recordId, condition: 'AND', operator: '=' }]
		};
		return relatedLinksOptions;
	}

	// Public Properties
	@api recordId;

	@api get title() {
		return this._title;
	}
	set title(title) {
		this._title = title ? title : DEFAULT_TITLE;
	}
	@api get zeroStateMessage() {
		return this._zeroStateMessage;
	}
	set zeroStateMessage(zeroStateMessage) {
		this._zeroStateMessage = zeroStateMessage ? zeroStateMessage : ZERO_STATE_MESSAGE;
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass += !isEmpty(customClass) ? ` ${customClass}` : '';
	}

	@wire(getRelatedLinks, { searchOptions: '$relatedLinksOptions' })
	wireGetRelatedLinks({ error, data }) {
		if (data) {
			if (data.success) {
				this.relatedLinks = data.results;
				this.relatedLinksLength = data.totalResults;
			} else {
				data.messages.forEach((message) => {
					showToast('error', '', message, 'dismissable');
					console.error('Error Processing getArticles: ', message);
				});
			}
			this.loaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getRelatedLinks: ', error);
		}
	}

	connectedCallback() {
		this.classList.add(...this.customClass.split(' '));
	}
}
