import { LightningElement, api } from 'lwc';

import OPTIONS_SELECTED from '@salesforce/label/c.FilterOptionsSelected';
import ALL from '@salesforce/label/c.ALL';
import SEARCH from '@salesforce/label/c.Search';
import { formatLabel } from 'c/copadocoreUtils';

export default class MultiSelectPicklistLwc extends LightningElement {
    labels = {
        SEARCH
    };

    @api label;

    @api
    get disabled() {
        return this._disabled;
    }
    set disabled(value) {
        this._disabled = value;
        this._handleDisabled();
    }
    _disabled = false;

    @api
    get options() {
        return this._options;
    }
    set options(value) {
        if (value && value.length > 0) {
            this._options = value;
            this.filteredOptions = JSON.parse(JSON.stringify(this._options));
            this.inputValue = this.options[0].label;
        }
    }
    _options = [];

    filteredOptions = [];

    inputValue = ALL;

    searchValue = '';
    _selectedValues = [];

    hasRendered = false;
    comboboxIsRendered = false;
    dropDownInFocus = false;

    get isSearchable() {
        return this._options.length > 6;
    }

    @api
    clear() {
        this.handleAllOption();
    }

    renderedCallback() {
        if (!this.hasRendered) {
            this._handleDisabled();
            this.hasRendered = true;
        }
    }

    handleClick() {
        const sldsCombobox = this.template.querySelector('.slds-combobox');
        if (sldsCombobox) {
            sldsCombobox.classList.toggle('slds-is-open');
            if (!this.comboboxIsRendered) {
                this._selectAllOption();
                this.comboboxIsRendered = true;
            }
        }
    }

    search(event) {
        this.searchValue = event.target.value.toLowerCase();
        this.filteredOptions = this._options.filter((option) => option.label.toLowerCase().includes(this.searchValue.trim()) === true);

        if (this.searchValue === '') {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this._selectedValues.forEach((value) => {
                    const optionElem = this.template.querySelector(`[data-id="${value.value}"]`).firstChild;
                    optionElem.classList.add('slds-is-selected');
                });
            }, 0);
        }
    }

    handleSelection(event) {
        const value = event.currentTarget.dataset.value;
        if (value === '') {
            this.handleAllOption();
        } else {
            this.handleOption(event, value);
        }
        const input = this.template.querySelector('input');
        if (input) {
            input.focus();
        }
        this.sendValues();
    }

    sendValues() {
        const values = this._selectedValues.map((option) => option.value);
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: values
            })
        );
    }

    handleAllOption() {
        this._selectedValues = [];
        this.inputValue = this._options[0].label;

        this._unselectOptions();
        this._selectAllOption();

        this._closeDropbox();
    }

    handleOption(event, value) {
        const listBoxOption = event.currentTarget.firstChild;

        if (this._optionIsSelected(listBoxOption)) {
            this._selectedValues = this._selectedValues.filter((option) => option.value !== value);
        } else {
            this._unselectAllOption();
            const option = this.options.find((option) => option.value === value);
            this._addValue(option);
        }

        this.inputValue =
            this._selectedValues.length > 1
                ? formatLabel(OPTIONS_SELECTED, [this._selectedValues.length])
                : this._selectedValues.length === 1
                ? this._selectedValues[0].label
                : this.options[0].label;

        listBoxOption.classList.toggle('slds-is-selected');
    }

    handleBlur() {
        if (!this.dropDownInFocus) {
            this._closeDropbox();
        }
    }

    handleMouseLeave() {
        this.dropDownInFocus = false;
    }

    handleMouseEnter() {
        this.dropDownInFocus = true;
    }

    _handleDisabled() {
        const input = this.template.querySelector('input');
        if (input) {
            input.disabled = this.disabled;
        }
    }

    _closeDropbox() {
        const sldsCombobox = this.template.querySelector('.slds-combobox');
        if (sldsCombobox) {
            sldsCombobox.classList.remove('slds-is-open');
        }
    }

    _unselectOptions() {
        const listBoxOptions = this.template.querySelectorAll('.slds-is-selected');
        for (const option of listBoxOptions) {
            option.classList.remove('slds-is-selected');
        }
    }

    _selectAllOption() {
        const allOption = this.template.querySelector('[data-id=""]');
        if (allOption) {
            allOption.firstChild.classList.add('slds-is-selected');
        }
    }

    _unselectAllOption() {
        const allOption = this.template.querySelector('[data-id=""]');
        if (allOption) {
            allOption.firstChild.classList.remove('slds-is-selected');
        }
    }

    _optionIsSelected(option) {
        return option.classList.contains('slds-is-selected');
    }

    _addValue(option) {
        const value = option.value;
        const found = this._selectedValues.some((el) => el.value === value);
        if (!found) {
            this._selectedValues.push({ label: option.label, value: option.value });
        }
    }
}