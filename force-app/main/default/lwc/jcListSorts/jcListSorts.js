import { LightningElement, api, track } from 'lwc';
import { splitString } from 'c/jcUtils';

const TEXT_COLOR = getComputedStyle(document.body).getPropertyValue('--lwc-colorTextDefault');

export default class JcListSorts extends LightningElement {
	// Private Properties
	_selectedOption;
	_options = new Map();

	_sortOptions = {
		map: new Map(),
		get list() {
			return this.map.size > 0 ? Array.from(this.map.values()) : [];
		}
	};

	// Private Reactive Properties
	fontColor = TEXT_COLOR;

	// Public Properties
	@track optionList;

	@api get options() {
		return Array.from(this._sortOptions.map.values());
	}
	set options(options) {
		options = splitString(Array.isArray(options) ? options.join(',') : options, ',', 'trim');

		options.forEach((option) => {
			let optionValue = option.toLowerCase().replace(/\s+/g, '');
			let sortOption = {
				label: option,
				value: optionValue,
				selected: this.selectedOption === optionValue
			};

			this._sortOptions.map.set(optionValue, sortOption);
		});
		this.optionList = this._sortOptions.list;
	}
	@api get selectedOption() {
		return this._selectedOption;
	}
	set selectedOption(selectedOption) {
		this._selectedOption = selectedOption
			? selectedOption.toLowerCase().replace(/\s+/g, '')
			: this.options[0].value;
		// this._sortOptions.map.get(this.selectedOption).bold = true;
	}

	handleSortOption = (event) => {
		let newSelection = event.currentTarget.dataset.name;

		this._sortOptions.map.get(this._selectedOption).selected = false;
		this._sortOptions.map.get(newSelection).selected = true;

		this._selectedOption = newSelection;
		this.optionList = this._sortOptions.list;

		this.dispatchEvent(
			new CustomEvent('update', {
				detail: this.selectedOption
			})
		);
	};
}
