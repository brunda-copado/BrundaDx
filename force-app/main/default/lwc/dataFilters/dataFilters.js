import { LightningElement, api, track } from 'lwc';
import retrieveFields from '@salesforce/apex/DataFiltersCtrl.retrieveFields';
import parseFields from '@salesforce/apex/DataFiltersCtrl.parseFields';
import { showToastError } from 'c/copadocoreToastNotification';
import { loadStyle } from 'lightning/platformResourceLoader';
import { reduceErrors, flushPromises } from 'c/copadocoreUtils';
import { label, resource, dateOptions, datePeriods, booleanOptions, customFilterOption } from './constants';
import {
    createFilter,
    reorder,
    getFilter,
    getField,
    getInputType,
    getInputFormatter,
    getDefaultValue,
    isDatepicker,
    isBoolean,
    getShowValue,
    isRangeDate,
    isCustomDate,
    convertToDataFilters,
    convertDataFilters
} from './utils';

export default class DataFilters extends LightningElement {
    label = label;
    resource = resource;

    @api filterContext;
    @api
    get fieldsDescribe() {
        return this._fieldsDescribe;
    }
    set fieldsDescribe(value) {
        this._fieldsDescribe = value;
        if (this._fieldsDescribe) {
            this._getFieldsFromDescribe();
        }
    }
    _fieldsDescribe;

    @api
    get orgCredentialId() {
        return this._orgCredentialId;
    }
    set orgCredentialId(value) {
        this._orgCredentialId = value;
        if (this._orgCredentialId && this._objectName) {
            this._getFieldsFromOrg();
        }
    }
    _orgCredentialId; //private property for org credential

    @api
    get objectName() {
        return this._objectName;
    }
    set objectName(value) {
        this._objectName = value;
        if (this._orgCredentialId && this._objectName) {
            this._getFieldsFromOrg();
        }
    }
    _objectName;

    @api
    get filters() {
        return convertToDataFilters(this._filters);
    }
    set filters(value) {
        this._filters = convertDataFilters(this._fields, value);
    }
    @track _filters = [];

    @api
    get defaultFilters() {
        return this._defaultFilters;
    }
    set defaultFilters(value) {
        this._defaultFilters = value;
    }
    _defaultFilters = [];

    @api
    get filterLogic() {
        return this._filterLogic;
    }
    set filterLogic(value) {
        this._filterLogic = value;
    }
    _filterLogic;

    @api
    get defaultFilterLogic() {
        return this._defaultFilterLogic;
    }
    set defaultFilterLogic(value) {
        this._defaultFilterLogic = value;
    }
    _defaultFilterLogic;

    @api readOnlyMode = false;

    // information about the field (type, name, operators, etc.)
    _fields = [];

    // inputs
    fieldOptions;
    dateOptions = dateOptions;
    datePeriods = datePeriods;
    booleanOptions = booleanOptions;

    isLoading = false;

    get inputsNotEditable() {
        return this.readOnlyMode || this.missingInputs;
    }

    get missingInputs() {
        return !this._fields || this._fields.length === 0;
    }

    get customFilterPlaceholder() {
        return this.objectName ? this.objectName + ".Name='ABC'" : '';
    }

    get invalidFilters() {
        return this._filters.some((filter) => filter.isValid === false);
    }

    get invalidFilterMessage() {
        return this.filterContext === 'dataTemplate' ? this.label.DATA_TEMPLATE_FILTER_WARNING : this.label.DATA_TEMPLATE_INVALID_FILTERS;
    }

    connectedCallback() {
        loadStyle(this, resource.DATA_FILTERS_RESOURCES + '/style.css');
    }

    handleChangeField(event) {
        const fieldName = event.detail.value;
        const filterId = event.target.dataset.id;
        let filter = getFilter(this._filters, filterId);
        this.configureFilter(filter, fieldName);
    }

    async configureFilter(filter, fieldName) {
        filter.fieldName = fieldName;
        filter.dateOption = '';
        filter.isCustom = fieldName === customFilterOption.value;
        if (filter.isCustom) {
            filter.fieldType = 'STRING';
            filter.operators = [];
            filter.operatorsCode = '';
            filter.showValue = false;
        } else {
            const field = getField(this._fields, fieldName);
            filter.fieldType = field.type;
            filter.fieldLabel = field.label;
            filter.operators = field.operators.map(({ label, code }) => ({ label: label, value: code }));
            filter.operatorCode = filter.operators[0].value;
            filter.showValue = getShowValue(filter.fieldType);
        }
        filter.isDatepicker = isDatepicker(filter.fieldType);
        filter.isBoolean = isBoolean(filter.fieldType);
        filter.inputType = getInputType(filter.fieldType);
        // make sure input component is re-rendered (because the input type has changed), otherwise when we set the value, the input is not available yet
        await flushPromises();
        filter.inputFormatter = getInputFormatter(filter.fieldType);
        filter.inputValue = getDefaultValue(filter.fieldType);
        filter.value = getDefaultValue(filter.fieldType);
        filter.isValid = true;
        return filter;
    }

    handleChangeCustomFilter(event) {
        const filterId = event.target.dataset.id;
        const value = event.target.value;
        let filter = getFilter(this._filters, filterId);

        filter.inputValue = value;
        filter.value = value;
    }

    handleChangeOperator(event) {
        const operatorCode = event.detail.value;
        const filterId = event.target.dataset.id;

        let filter = getFilter(this._filters, filterId);
        filter.operatorCode = operatorCode;
    }

    async handleChangeDateOption(event) {
        const filterId = event.target.dataset.id;
        const dateOption = event.detail.value;

        let filter = getFilter(this._filters, filterId);

        filter.dateOption = dateOption;
        filter.inputType = isCustomDate(dateOption) ? getInputType(filter.fieldType) : 'number';
        filter.showValue = isRangeDate(dateOption) || isCustomDate(dateOption);
        // make sure input component is re-rendered (because the input type has changed), otherwise when we set the value, the input is not available yet
        await flushPromises();
        filter.inputValue = filter.inputType === 'number' ? '0' : getDefaultValue(filter.fieldType);
        filter.value = isCustomDate(dateOption) ? getDefaultValue(filter.fieldType) : dateOption.replace(':n', ':0');
    }

    handleChangeBooleanOption(event) {
        const filterId = event.target.dataset.id;
        const booleanOption = event.detail.value;

        let filter = getFilter(this._filters, filterId);
        filter.inputValue = booleanOption;
        filter.value = booleanOption;
    }

    handleChangeValue(event) {
        const filterId = event.target.dataset.id;
        let filter = getFilter(this._filters, filterId);
        const value = filter.inputType === 'number' && !event.target.value ? '0' : event.target.value;
        filter.inputValue = value;
        filter.value = isRangeDate(filter.dateOption) ? filter.dateOption.replace(':n', `:${value}`) : value;
    }

    handleChangeFilterLogic(event) {
        const filterLogic = event.target.value;
        this._filterLogic = filterLogic;
    }

    handleClickAddFilter() {
        const numItems = this._filters.length;

        const newElement = createFilter(numItems + 1);

        this._filters = [...this._filters, newElement];

        this._filterLogic = numItems > 0 ? this._filterLogic + ` AND ${newElement.order}` : `${newElement.order}`;
    }

    handleClickResetFilters() {
        this.resetFilters();
    }

    handleClickDeleteFilter(event) {
        const filterId = event.target.dataset.id;
        this._filters = this._filters.filter((filter) => filter.id !== filterId);
        if (this._filters.length === 0) {
            this._filters = [];
            this._filterLogic = '';
        }
        reorder(this._filters);
    }

    async _getFieldsFromOrg() {
        this.isLoading = true;
        try {
            this._fields = await retrieveFields({ orgCredentialId: this.orgCredentialId, objectName: this.objectName });
            this._createFieldOptions();
            this.resetFilters();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
        this.isLoading = false;
    }

    async _getFieldsFromDescribe() {
        this.isLoading = true;
        try {
            this._fields = await parseFields({ fieldsDescribe: this.fieldsDescribe });
            this._createFieldOptions();
            this.resetFilters();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
        this.isLoading = false;
    }

    _createFieldOptions() {
        const objectFieldOptions = this._fields.map(({ label, name }) => ({ label: label + ' (' + name + ')', value: name }));
        this.fieldOptions = [customFilterOption, ...objectFieldOptions];
    }

    @api
    resetFilters() {
        this._filters = convertDataFilters(this._fields, this._defaultFilters);
        this._filterLogic = this._defaultFilterLogic;
        if (this._filters.length === 0) {
            this._filterLogic = '';
        }
    }
}