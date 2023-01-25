import { LightningElement, api } from 'lwc';

export default class DataTableUtility extends LightningElement {
	//PUBLIC PROPERTIES
	@api getData;
	@api getColumns;
	@api hideCheckboxCol;
	@api showRowNumCol;
	@api columnWidthsMode;
	@api resizeColumns;
	@api hideTableHeader;
}
