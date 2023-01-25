import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyFeedbackStats from '@salesforce/apex/JCFeedbackController.getMyFeedbackStats';
import { splitString } from 'c/jcUtils';
export default class JcFeedbackStats extends LightningElement {
	// Private Properties
	_customClass;
	_feedbackType;

	data;

	get receivedStatsNumber() {
		return this.feedbackStats?.data?.stats.received;
	}

	get givenStatsNumber() {
		return this.feedbackStats?.data?.stats.given;
	}

	// Public Properties
	@api feedbackType;
	@api headerText;
	@api descriptionText;
	@api receivedText;
	@api givenText;

	@api get customClass() {
		return this._customClass;
	}

	set customClass(value) {
		if (value) {
			this._customClass = splitString(value, ' ', 'trim');
			this.classList.add(...this._customClass);
		}
	}

	@wire(getMyFeedbackStats, { type: '$feedbackType' })
	feedbackStats;

	renderedCallback() {
		refreshApex(this.feedbackStats);
	}
}
