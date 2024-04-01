import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import DATATABLE_STATIC_RESOURCES from '@salesforce/resourceUrl/CustomDatatable';

import { label, constants } from './constants';

export default class FilterColumns extends LightningElement {
    @api filterConfig;
    @api selectedOption = constants.INCLUDES;

    label = label;

    fieldLabelVariant = constants.LABEL_STACKED;
    fieldName;
    type;
    rangeType;
    options;
    fieldLabel;
    fieldType;

    searchValue = '';
    minValue = '';
    maxValue = '';
    isTextInput = false;
    isListInput = false;
    isRangeInput = false;
    isArrayInput = false;
    filterArrayInput = '';

    get minValueLabel() {
        return this.fieldType === constants.TYPE_DATE ? label.FROM : label.MIN;
    }

    get maxValueLabel() {
        return this.fieldType === constants.TYPE_DATE ? label.TO : label.MAX;
    }

    connectedCallback() {
        this._loadCSSResources();
        if (this.filterConfig) {
            this.fieldName = this.filterConfig.columnname;
            this.options = this.filterConfig.options;
            this.fieldLabel = this.filterConfig.label;
            this.fieldType = this.filterConfig.type ? this.filterConfig.type.toLowerCase() : constants.TYPE_TEXT;
            this.filtertype = this.filterConfig.filtertype ? this.filterConfig.filtertype.toLowerCase() : constants.TYPE_TEXT;
            this.type = this.filterConfig.type ? this.filterConfig.type.toLowerCase() : constants.TYPE_TEXT;

            this._checkFilterTypeIsInput();
            this._datatableToInputTypeConversion();
            this._setFieldTypeRenderer();
            this._setSelectedOption();
        }
    }

    @api
    validate() {
        const filterInput = this.template.querySelector("[data-field='filterInput']");
        const filterInputText = this.template.querySelector("[data-field='filterInputText']");
        const filterInputList = this.template.querySelector("[data-field='filterInputList']");
        const filterRangeMin = this.template.querySelector("[data-field='filterRangeMin']");
        const filterRangeMax = this.template.querySelector("[data-field='filterRangeMax']");
        const filterArrayInput = this.filterArrayInput;

        if (filterInput) {
            this._dispatchValidate(this._getFilterInputObject(filterInput));
        } else if (filterInputText) {
            this._dispatchValidate(this._getFilterInputObject(filterInputText));
        } else if (filterInputList) {
            this._dispatchValidate(this._getFilterInputObject(filterInputList));
        } else if (filterRangeMin || filterRangeMax) {
            this._dispatchValidate(this._getFilterRangeObject(filterRangeMin, filterRangeMax));
        } else if (filterArrayInput) {
            this._dispatchValidate(this._getFilterArrayObject(filterArrayInput));
        } else {
            this._dispatchValidate(this._getFilterInputObject(''));
        }
    }

    // TEMPLATE

    handleValueChange(event) {
        this.filterArrayInput = event.detail;
    }

    // PRIVATE

    async _loadCSSResources() {
        await loadStyle(this, DATATABLE_STATIC_RESOURCES + '/css/customDatatableContainer.css');
    }

    _checkFilterTypeIsInput() {
        this.type = this.filtertype === constants.TYPE_INPUT ? this.type : this.filtertype;
    }

    _datatableToInputTypeConversion() {
        if (constants.TYPE_CONVERSION.has(this.type)) {
            this.type = constants.TYPE_CONVERSION.get(this.type);
        }
    }

    _setFieldTypeRenderer() {
        if (
            constants.AVAILABLE_FILTER_TYPE.indexOf(this.filterConfig.filtertype) === -1 ||
            this.filterConfig.filtertype === constants.TYPE_TEXT ||
            this.type === constants.TYPE_TEXT
        ) {
            this.isTextInput = true;
        } else {
            if (this.type && this.type === constants.TYPE_LIST) {
                this.isListInput = true;
            } else if (this.type && this.type === constants.TYPE_RANGE) {
                this.isRangeInput = true;
                this.rangeType = this.filterConfig.type;
            } else if (this.type && this.type === constants.TYPE_ARRAY) {
                this.isArrayInput = true;
            }
        }
    }

    _setSelectedOption() {
        if (
            this.filterConfig.filterOperation &&
            (this.filterConfig.filterOperation.toLowerCase() === constants.EQUALS ||
                this.filterConfig.filterOperation.toLowerCase() === constants.INCLUDES)
        ) {
            this.selectedOption = this.filterConfig.filterOperation.toLowerCase();
        } else if (!this.selectedOption || this.selectedOption !== constants.EQUALS) {
            this.selectedOption = constants.INCLUDES;
        } else {
            this.selectedOption = constants.EQUALS;
        }
    }

    _dispatchValidate(detail) {
        this.dispatchEvent(new CustomEvent(constants.VALIDATE_EVENT, { detail: detail }));
    }

    _getFilterInputObject(filterInput) {
        return {
            fieldName: this.fieldName,
            selectedOption: this.selectedOption,
            searchTerm: this.type === constants.TYPE_CHECKBOX ? filterInput.checked : filterInput.value
        };
    }

    _getFilterRangeObject(filterRangeMin, filterRangeMax) {
        return {
            fieldName: this.fieldName,
            selectedOption: this.selectedOption,
            filterRangeMin: filterRangeMin.value,
            filterRangeMax: filterRangeMax.value
        };
    }

    _getFilterArrayObject(filterInputs) {
        return {
            fieldName: this.fieldName,
            selectedOption: this.selectedOption,
            searchTerm: filterInputs
        };
    }
}