import { LightningElement, api, track } from 'lwc';
import {
    label,
    NO_UPDATE_OPTION,
    INPUT_TYPE_BY_FIELD_TYPE,
    REPLACE_PROPERTY_BY_FIELD_TYPE,
    DEFAULT_VALUE_BY_FIELD_TYPE,
    INPUT_FORMATTER_BY_FIELD_TYPE,
    BOOLEAN_OPTIONS
} from './constants';

export default class DataTemplateContentUpdate extends LightningElement {
    label = label;

    @api fieldName;
    @api fieldType;
    @api contentValueUpdateValues;
    @api fieldContentUpdate;
    @api replaceValue;
    @api replaceValueNumber;
    @api replaceValueDate;
    @api replaceValueDatetime;
    @api readOnlyMode;

    @api recordId; // dataTemplate RecordId;

    @track options = [];
    // only one value for input, assign to corresponding property when setting the value
    inputValue;
    booleanOptions = BOOLEAN_OPTIONS;

    get contentUpdateOptionLabel() {
        const selectedOption = this.options.find((option) => option.value === this.fieldContentUpdate);
        return selectedOption ? selectedOption.label : '';
    }

    get replaceLabel() {
        if (this.isBoolean) {
            const selectedOption = this.booleanOptions.find((option) => option.value === this.replaceValue);
            return selectedOption ? selectedOption.label : '';
        } else {
            return this.inputValue;
        }
    }

    get isRecordMatchingFormula() {
        return this.fieldContentUpdate && this.fieldContentUpdate === 'recordMatching';
    }

    get isReplace() {
        return this.fieldContentUpdate && this.fieldContentUpdate === 'replace';
    }

    get replaceInputType() {
        if (this.fieldType in INPUT_TYPE_BY_FIELD_TYPE) {
            return INPUT_TYPE_BY_FIELD_TYPE[this.fieldType];
        }
        return 'text';
    }

    get replaceFormatter() {
        if (this.fieldType in INPUT_FORMATTER_BY_FIELD_TYPE) {
            return INPUT_FORMATTER_BY_FIELD_TYPE[this.fieldType];
        }
        return '';
    }

    get isBoolean() {
        return this.fieldType === 'boolean';
    }

    connectedCallback() {
        this._configureOptions();
        this._setDefaultOption();
        this._setInputValue();
    }

    handleChangeOption(event) {
        this.fieldContentUpdate = event.detail.value;
        this.dispatchEvent(
            new CustomEvent('setfieldcontentupdate', {
                bubbles: true,
                composed: true,
                detail: { fieldName: this.fieldName, fieldContentUpdate: event.detail.value }
            })
        );
        this._setDefaultValue();
        this._setReplaceValue();
    }

    handleChangeReplaceValue(event) {
        this.inputValue = event.detail.value;
        this._setReplaceValue();
    }

    handleClickRecordMatchingFormula(event) {
        // To-Do: to be implemented in another US, show modal with record matching formula configuration
        this.template.querySelector('c-data-template-record-matching-formula').showRecordMatchingFormula();
    }

    _configureOptions() {
        this.options.push(NO_UPDATE_OPTION);
        if (this.contentValueUpdateValues) {
            Object.entries(this.contentValueUpdateValues).forEach(([key, value]) => this.options.push({ label: key, value: value }));
        }
    }

    _setDefaultOption() {
        if (!this.fieldContentUpdate) {
            this.fieldContentUpdate = 'none';
        }
    }

    _setInputValue() {
        this.inputValue = this.replaceValue || this.replaceValueNumber || this.replaceValueDate || this.replaceValueDatetime;
    }

    _getReplaceDetails() {
        let result = {};
        if (this.fieldType in REPLACE_PROPERTY_BY_FIELD_TYPE) {
            const property = REPLACE_PROPERTY_BY_FIELD_TYPE[this.fieldType];
            result[property] = this.inputValue;
        }
        return result;
    }

    _setDefaultValue() {
        if (this.fieldType in DEFAULT_VALUE_BY_FIELD_TYPE) {
            this.inputValue = DEFAULT_VALUE_BY_FIELD_TYPE[this.fieldType];
        }
    }

    _setReplaceValue() {
        const replaceDetails = this._getReplaceDetails();
        this.dispatchEvent(
            new CustomEvent('setreplacevalue', {
                bubbles: true,
                composed: true,
                detail: { ...replaceDetails, fieldName: this.fieldName }
            })
        );
    }
}