import { LightningElement, api } from 'lwc';

export default class JcDatatable extends LightningElement {
	// Private Properties

	// Private Reactive Properties
	get hideCheckboxes() {
		return !this.showCheckboxes;
	}
	get disableColumnResizing() {
		return !this.enableColumnResizing;
	}
	get hideTableHeader() {
		return !this.showTableHeader;
	}

	// Public Properties
	@api records;
	@api columns;
	@api columnWidthsMode;
	@api showCheckboxes = false;
	@api showRowNumbers = false;
	@api enableColumnResizing = false;
	@api showTableHeader = false;
	@api isLoading = false;
}
