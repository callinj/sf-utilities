import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { showToast } from 'c/jcUtils';

const DEFAULT_CLASSES = 'jc-talent-decision-release-action';

// TODO | Change component to jcFlowLauncher
// TODO | Will have properties for passing flow apiName, etc
export default class JcTalentDecisionReleaseAction extends NavigationMixin(LightningElement) {
	// Private properties
	_customClasses = DEFAULT_CLASSES;
	_cssVariables = {};

	// Private reactive properties
	showModal = false;

	get isReleaseAction() {
		return this.actionType === 'Release';
	}
	get inputVariables() {
		return [
			{
				name: 'Is_Release',
				type: 'Boolean',
				value: this.isReleaseAction
			}
		];
	}

	// Public properties
	@api formTitle;
	@api actionVariant;
	@api actionLabel;
	@api actionLeftIcon;
	@api actionRightIcon;
	@api actionAlign;
	@api actionFullWidth;
	@api actionOverSized;
	@api actionUnderline;
	@api actionBorderRadius;
	@api actionBorderThickness;
	@api actionCustomColor;
	@api actionType = 'Release';
	@api successMessage;

	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(value) {
		this._customClasses += value ? ` ${value}` : '';
	}
	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
	}
	renderedCallback() {
		// FIXME Accessing firstChild on this.template is unsafe
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
	}
	actionClick = () => {
		this.showModal = true;
	};
	closeModal = () => {
		this.showModal = false;
	};
	handleStatusChange = (event) => {
		if (event.detail.status === 'FINISHED' && event.detail?.errors === null) {
			showToast(
				'info',
				'Updating talent decisions. You will receive an email and notification when records have successfully updated.',
				'In Progress',
				'dismissable'
			);
			this.closeModal();
		}
	};
}
