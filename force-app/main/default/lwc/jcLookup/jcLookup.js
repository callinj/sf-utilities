import { LightningElement, api } from 'lwc';
import { getDOMId, normalizeString, normalizeBoolean, normalizeAriaAttribute } from 'c/jcUtils';
import { handleKeyDownOnInput } from './keyboard';
import { VARIANT } from './inputUtils';
import { EventDispatcher } from './eventDispatcher';

const DEFAULT_CLASSES = 'jc-lookup';

export default class JCLookup extends LightningElement {
	constructor() {
		super();
		this._eventDispatcher = new EventDispatcher(this);
	}
	// Private properties
	// _dropdownHeight = 'standard';
	_dropdownVisible = false;
	_highlightedOptionElementId = null;
	_readonly = false;
	_hasDropdownOpened = false;
	_inputDescribedBy = [];
	_inputAriaControls;
	_customClasses = DEFAULT_CLASSES;
	_cssVariables = {};
	get _inputReadOnly() {
		return this._readonly || this.variant === VARIANT.STANDARD || this.hasInputPill;
	}
	get _shouldOpenDropDown() {
		return !this.dropdownDisabled && this._inputHasFocus && this._requestedDropdownOpen;
	}

	// Private reactive properties
	searchTerm = null;
	get dropdownDisabled() {
		return this.readOnly || this.disabled;
	}
	get inputElement() {
		return this.template.querySelector('input');
	}
	get inputId() {
		return getDOMId(this.template.querySelector('input'));
	}
	get ariaExpanded() {
		return this._dropdownVisible ? 'true' : 'false';
	}
	get ariaAutocomplete() {
		if (this.hasInputPill) {
			return null;
		}

		return this._inputReadOnly ? 'none' : 'list';
	}
	get hasInputPill() {
		return this.inputPill && Object.keys(this.inputPill).length > 0;
	}
	get computedAriaAutocomplete() {
		if (this.hasInputPill) {
			return null;
		}

		return this._inputReadOnly ? 'none' : 'list';
	}
	get computedPlaceholder() {
		return this.hasInputPill ? this.inputPill.label : this.placeholder;
	}
	get computedInputValue() {
		return this.hasInputPill ? this.inputPill.label : this.inputText;
	}
	get computedUniqueElementId() {
		return this.inputId;
	}
	get listboxElement() {
		if (!this._listBoxElementCache) {
			this._listBoxElementCache = this.template.querySelector('[role="listbox"]');
		}
		return this._listBoxElementCache;
	}
	get computedUniqueDropdownElementId() {
		return getDOMId(this.template.querySelector('[data-dropdown-element]'));
	}
	get inputAriaControlsId() {
		return getDOMId(this._inputAriaControls);
	}
	get computedInputControls() {
		const ariaValues = [this.computedUniqueDropdownElementId];

		if (this.inputControlsElement) {
			ariaValues.push(this.inputAriaControlsId);
		}

		return normalizeAriaAttribute(ariaValues);
	}
	get inputLabelledById() {
		return getDOMId(this._inputLabelledBy);
	}
	get computedAriaDescribedBy() {
		const ariaValues = [];
		this._inputDescribedBy.forEach((element) => {
			ariaValues.push(getDOMId(element));
		});
		return normalizeAriaAttribute(ariaValues);
	}
	get isDropdownEmpty() {
		return !this.showDropdownActivityIndicator && (!Array.isArray(this.items) || this.items.length === 0);
	}
	// Public properties
	@api name;
	@api inputPill;
	@api placeholder = 'Select an Item';
	@api inputText = '';
	@api get disabled() {
		return this._disabled;
	}

	set disabled(value) {
		this._disabled = normalizeBoolean(value);

		if (this._disabled && this._dropdownVisible) {
			this.closeDropdown();
		}
	}
	@api get readOnly() {
		return this._readonly;
	}

	set readOnly(value) {
		this._readonly = normalizeBoolean(value);
		if (this._readonly && this._dropdownVisible) {
			this.closeDropdown();
		}
	}
	@api get items() {
		return this._unprocessedItems;
	}

	set items(items = []) {
		this._unprocessedItems = items;

		if (this._connected) {
			if (this._hasDropdownOpened) {
				this.updateItems(items);

				if (this._dropdownVisible) {
					if (this.isDropdownEmpty) {
						this.closeDropdown();
					} else {
						this.highlightDefaultItem();
					}
				}
			}

			if (this._shouldOpenDropDown) {
				this.openDropdownIfNotEmpty();
			}
		}
	}
	@api get variant() {
		return this._variant || VARIANT.STANDARD;
	}

	set variant(value) {
		this._variant = normalizeString(value, {
			fallbackValue: VARIANT.STANDARD,
			validValues: [VARIANT.STANDARD, 'lookup']
		});
	}
	@api get inputControlsElement() {
		return this._inputAriaControls;
	}

	set inputControlsElement(element) {
		this._inputAriaControls = element;
		// TODO sync
		// this.synchronizeA11y();
	}
	@api get inputDescribedByElements() {
		return this._inputDescribedBy;
	}

	set inputDescribedByElements(elements) {
		if (Array.isArray(elements)) {
			this._inputDescribedBy = elements;
		} else {
			this._inputDescribedBy = [elements];
		}
		// TODO sync
		// this.synchronizeA11y();
	}
	@api get inputLabelledByElement() {
		return this._inputLabelledBy;
	}

	set inputLabelledByElement(element) {
		this._inputLabelledBy = element;
		// TODO sync
		// this.synchronizeA11y();
	}

	@api get customClasses() {
		return this._customClasses;
	}
	set customClasses(customClasses) {
		this._customClasses += customClasses ? ` ${customClasses}` : '';
	}
	// TODO dropdown height
	// @api get dropdownHeight() {
	// 	return this._dropdownHeight;
	// }

	// set dropdownHeight(height) {
	// 	this._dropdownHeight = normalizeString(height, {
	// 		fallbackValue: 'standard',
	// 		validValues: ['standard', 'small']
	// 	});
	// }
	// TODO add activity
	// @api get showDropdownActivityIndicator() {
	//     return this._showDropdownActivityIndicator;
	// }

	// set showDropdownActivityIndicator(value) {
	//     this._showDropdownActivityIndicator = normalizeBoolean(value);

	//     if (this._connected) {
	//         if (this._showDropdownActivityIndicator) {
	//             if (this._shouldOpenDropDown) {
	//                 this.openDropdownIfNotEmpty();
	//             }
	//         } else if (this._dropdownVisible && this.isDropdownEmpty) {
	//             this.closeDropdown();
	//         }
	//     }
	// }
	// Functions
	renderedCallback() {
		// TODO fix firstChild issue
		// eslint-disable-next-line @lwc/lwc/no-template-children
		const component = this.template.firstChild;
		for (const cssVariable in this._cssVariables) {
			if (Object.prototype.hasOwnProperty.call(this._cssVariables, cssVariable)) {
				component.style.setProperty(cssVariable, this._cssVariables[cssVariable]);
			}
		}
		this.dispatchEvent(
			new CustomEvent('ready', {
				detail: {
					id: this.inputId,
					name: this.name
				}
			})
		);
		// TODO sync aria labels
	}
	connectedCallback() {
		this.classList.add(...this.customClasses.split(' '));
		this._keyboardInterface = this.dropdownKeyboardInterface();
		this._connected = true;
	}

	disconnectedCallback() {
		this._connected = false;
		this._listBoxElementCache = undefined;
	}
	@api
	focus() {
		if (this._connected) {
			this.inputElement.focus();
		}
	}
	handleFocus = () => {
		console.log('input focused');
		this._inputHasFocus = true;
		this._eventDispatcher.dispatchFocus();
	};
	handleInput = () => {
		if (!this.hasInputPill) {
			this._eventDispatcher.dispatchTextInput(this.inputElement.value);
		}
	};
	handleInputClear = () => {
		this.searchTerm = null;
		this.inputElement.focus();
	};
	handleTextChange = () => {
		this._eventDispatcher.dispatchTextChange(this.inputElement.value);
	};
	handleInputSelect = (event) => {
		event.stopPropagation();
	};
	handleInputKeyDown = (event) => {
		if (this.dropdownDisabled) {
			return;
		}
		if (this.hasInputPill) {
			this.handlePillKeyDown(event);
		} else {
			handleKeyDownOnInput({
				event,
				currentIndex: this.getCurrentHighlightedOptionIndex(),
				dropdownInterface: this._keyboardInterface
			});
		}
	};
	handleBlur = () => {
		this._inputHasFocus = false;

		if (this._cancelBlur) {
			return;
		}
		this.closeDropdown();

		this._eventDispatcher.dispatchBlur();
	};
	closeDropdown = () => {
		if (!this._dropdownVisible) {
			return;
		}

		this.removeHighlight();
		this._dropdownVisible = false;
	};
	removeHighlight() {
		const option = this._highlightedOptionElement;
		if (option) {
			option.removeHighlight();
			this._highlightedOptionElement = null;
			this._highlightedOptionElementId = null;
			this._activeElementDomId = null;
		}
	}
	highlightDefaultItem() {
		this.removeHighlight();
		// eslint-disable-next-line @lwc/lwc/no-async-operation
		requestAnimationFrame(() => {
			this.highlightOptionAndScrollIntoView(this.findOptionElementByIndex(this._highlightedItemIndex));
		});
	}
	dropdownKeyboardInterface() {
		const that = this;
		return {
			getTotalOptions() {
				return that._selectableItems;
			},
			selectByIndex(index) {
				that.selectOptionAndCloseDropdown(that.findOptionElementByIndex(index));
			},
			highlightOptionWithIndex(index) {
				that.highlightOptionAndScrollIntoView(that.findOptionElementByIndex(index));
			},
			isInputReadOnly() {
				return that._inputReadOnly;
			},
			highlightOptionWithText(currentIndex, text) {
				for (let index = currentIndex + 1; index < that._items.length; index++) {
					const option = that._items[index];
					if (
						option.selectable &&
						option.text &&
						option.text.toLowerCase().indexOf(text.toLowerCase()) === 0
					) {
						that.highlightOptionAndScrollIntoView(that.findOptionElementByIndex(index));

						return;
					}
				}
				for (let index = 0; index < currentIndex; index++) {
					const option = that._items[index];
					if (
						option.selectable &&
						option.text &&
						option.text.toLowerCase().indexOf(text.toLowerCase()) === 0
					) {
						that.highlightOptionAndScrollIntoView(that.findOptionElementByIndex(index));

						return;
					}
				}
			},
			isDropdownVisible() {
				return that._dropdownVisible;
			},
			openDropdownIfNotEmpty() {
				that.openDropdownIfNotEmpty();
			},
			closeDropdown() {
				that.closeDropdown();
			}
		};
	}
	updateItems(items) {
		if (!items) {
			return;
		}

		// assert(Array.isArray(items), '"items" must be an array');

		this._selectableItems = 0;
		this._highlightedItemIndex = 0;

		this._items = items.map((item) => {
			if (item.items) {
				const groupCopy = { label: item.label };
				groupCopy.items = item.items.map((groupItem) => {
					return this.processItem(groupItem);
				});
				return groupCopy;
			}
			return this.processItem(item);
		});
	}
	processItem(item) {
		const itemCopy = {};

		itemCopy.type = item.type;
		itemCopy.iconName = item.iconName;
		itemCopy.iconSize = item.iconSize;
		itemCopy.iconAlternativeText = item.iconAlternativeText;
		itemCopy.rightIconName = item.rightIconName;
		itemCopy.rightIconSize = item.rightIconSize;
		itemCopy.rightIconAlternativeText = item.rightIconAlternativeText;
		itemCopy.text = item.text;
		itemCopy.subText = item.subText;
		itemCopy.value = item.value;

		itemCopy.checked = item.checked || false;

		itemCopy.selectable = ['option-card', 'option-inline'].indexOf(item.type) >= 0;

		if (itemCopy.selectable) {
			itemCopy.index = this._selectableItems;
			itemCopy.id = this.itemId(itemCopy.index);

			this._selectableItems += 1;

			if (item.highlight) {
				this._highlightedItemIndex = itemCopy.index;
			}
		}
		return itemCopy;
	}
	highlightOptionAndScrollIntoView(optionElement) {
		if (this._selectableItems.length === 0 || !optionElement) {
			return;
		}
		this.highlightOption(optionElement);
		scrollIntoViewIfNeeded(optionElement, this.listboxElement);
	}
	findOptionElementByIndex(index) {
		return this.template.querySelector(`[data-item-id="${this.itemId(index)}"]`);
	}
	handleListboxScroll(event) {
		event.stopPropagation();

		const listbox = event.target;
		const height = listbox.getBoundingClientRect().height;
		const maxScroll = listbox.scrollHeight - height;

		const buffer = 20;
		const bottomReached = listbox.scrollTop + buffer >= maxScroll;
		if (bottomReached) {
			this._eventDispatcher.dispatchEndReached();
		}
	}
	openDropdownIfNotEmpty = () => {
		if (this._dropdownVisible) {
			return;
		}

		const noOptions = !Array.isArray(this.items) || this.items.length === 0;

		if (noOptions && !this._requestedDropdownOpen) {
			this._events.dispatchDropdownOpenRequest();
		}

		if (this.isDropdownEmpty) {
			this._requestedDropdownOpen = true;
			return;
		}

		if (!this._hasDropdownOpened) {
			if (this._unprocessedItems) {
				this.updateItems(this._unprocessedItems);
			}
			this._hasDropdownOpened = true;
		}

		this._requestedDropdownOpen = false;

		this._dropdownVisible = true;

		this.highlightDefaultItem();

		this._eventDispatcher.dispatchDropdownOpen();
	};
}
// TODO move to util
function scrollIntoViewIfNeeded(element, scrollingParent) {
	const parentRect = scrollingParent.getBoundingClientRect();
	const findMeRect = element.getBoundingClientRect();
	if (findMeRect.top < parentRect.top) {
		if (element.offsetTop + findMeRect.height < parentRect.height) {
			scrollingParent.scrollTop = 0;
		} else {
			scrollingParent.scrollTop = element.offsetTop;
		}
	} else if (findMeRect.bottom > parentRect.bottom) {
		scrollingParent.scrollTop += findMeRect.bottom - parentRect.bottom;
	}
}
