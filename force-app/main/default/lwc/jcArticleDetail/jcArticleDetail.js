import { LightningElement, api, wire } from 'lwc';
import { showToast, splitString } from 'c/jcUtils';
import getRecordInfo from '@salesforce/apex/JCRecordUtils.getRecordInfo';
import getAssignedTopics from '@salesforce/apex/JCTopicController.getAssignedTopics';
import COMMUNITY_ID from '@salesforce/community/Id';

const DEFAULT_CLASS = 'brandedArticleDetail';
const HEADING_TYPE = 'h1';
const SUBHEADING_TYPE = 'h3';

export default class JcArticleDetail extends LightningElement {
	// Private Properties
	_customClass;
	_showAuthor = false;
	_showDate = false;
	_showTitle = false;
	_showViews = false;
	_showSummary = false;
	_showTopics = false;
	_customFields;
	_subheadingType = SUBHEADING_TYPE;

	// Private Reactive Properties
	showFieldLabels = true;
	assignedTopics;
	additionalFields = [];
	fields = [];
	article;
	loaded = false;

	get displayAuthor() {
		return this.author && this.showAuthor;
	}
	get displayDate() {
		return this.date && this.showDate;
	}
	get displayTitle() {
		return this.title && this.showTitle;
	}
	get displayViews() {
		return this.views && this.showViews;
	}
	get displaySummary() {
		return this.summary && this.showSummary;
	}
	get displayTopics() {
		return this.assignedTopics?.length > 0;
	}
	get displayCustom() {
		return this.additionalFields?.length > 0;
	}
	get author() {
		return this.article['Owner.Name']?.value;
	}
	get date() {
		return this.article?.FirstPublishedDate?.value;
	}
	get title() {
		return this.article?.Title?.value;
	}
	get views() {
		return this.article?.ArticleTotalViewCount?.value;
	}
	get summary() {
		return this.article?.Summary?.value;
	}
	get viewsLabel() {
		return this.views === 1 ? 'View' : 'Views';
	}
	get objectInfo() {
		return {
			fields: [...new Set(this.fields)],
			filters: [
				{
					field: 'Id',
					value: this.recordId
				}
			]
		};
	}
	get topicOptions() {
		return {
			objectName: 'TopicAssignment',
			filters: [
				{
					field: 'EntityId',
					value: this.recordId,
					condition: 'AND',
					operator: '='
				},
				{
					field: 'NetworkId',
					value: COMMUNITY_ID,
					condition: 'AND',
					operator: '='
				}
			]
		};
	}

	// Public Properties
	@api recordId;
	@api headingType = HEADING_TYPE;

	@api get showAuthor() {
		return this._showAuthor;
	}
	set showAuthor(showAuthor) {
		this._showAuthor = showAuthor;
		if (showAuthor) {
			this.fields.push('Owner.Name');
		}
	}
	@api get showDate() {
		return this._showDate;
	}
	set showDate(showDate) {
		this._showDate = showDate;
		if (showDate) {
			this.fields.push('FirstPublishedDate');
		}
	}
	@api get showTitle() {
		return this._showTitle;
	}
	set showTitle(showTitle) {
		this._showTitle = showTitle;
		if (showTitle) {
			this.fields.push('Title');
		}
	}
	@api get showViews() {
		return this._showViews;
	}
	set showViews(showViews) {
		this._showViews = showViews;
		if (showViews) {
			this.fields.push('ArticleTotalViewCount');
		}
	}
	@api get showSummary() {
		return this._showSummary;
	}
	set showSummary(showSummary) {
		this._showSummary = showSummary;
		if (showSummary) {
			this.fields.push('Summary');
		}
	}
	@api get showTopics() {
		return this._showTopics;
	}
	set showTopics(showTopics) {
		this._showTopics = showTopics;
		if (showTopics) {
			this.getTopics();
		}
	}
	@api get subheadingType() {
		return this._subheadingType;
	}
	set subheadingType(subheadingType) {
		this._subheadingType = subheadingType;
		if (subheadingType === 'None') {
			this._subheadingType = SUBHEADING_TYPE;
			this.showFieldLabels = false;
		}
	}
	@api get customFields() {
		return this._customFields;
	}
	set customFields(customFields) {
		if (customFields.length > 0) {
			this._customFields = splitString(customFields, ',', 'trim');
			this.fields.push(...this._customFields);
		}
	}
	@api get customClass() {
		return this._customClass;
	}
	set customClass(customClass) {
		this._customClass = splitString(customClass, ' ', 'trim');
		this.classList.add(...this.customClass);
	}

	@wire(getRecordInfo, { objectInfo: '$objectInfo', recordId: '$recordId' })
	articleDetail({ error, data }) {
		if (data) {
			if (data.success) {
				this.article = data.fields;
				let customFields = this.filterFields(data.fields, this.customFields);
				for (const [, customField] of Object.entries(customFields)) {
					this.additionalFields.push({ label: customField.label, value: customField.value });
				}
			} else {
				showToast('error', 'Check console log for details', 'Error Message', 'dismissable');
				data.messages.forEach((errorMessage) => {
					console.error('Error Processing getRecordInfo: ', errorMessage);
				});
			}
			this.loaded = true;
		} else if (error) {
			showToast('error', error.body.message, 'Error Message', 'dismissable');
			console.error('Error Processing getRecordInfo: ', error);
		}
	}

	connectedCallback() {
		this.classList.add(DEFAULT_CLASS);
	}

	filterFields(data, array) {
		return Object.keys(data)
			.filter((key) => array?.includes(key))
			.reduce((obj, key) => {
				obj[key] = data[key];
				return obj;
			}, {});
	}

	getTopics() {
		getAssignedTopics({ queryFilters: this.topicOptions })
			.then((result) => {
				this.assignedTopics = result[this.recordId];
			})
			.catch((error) => {
				console.error('Error Processing getAssignedTopics: ', error);
			});
	}
}
