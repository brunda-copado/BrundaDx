import { LightningElement, api, track, wire } from 'lwc';

import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { uniqueKey, handleAsyncError, autoFormValidation, flushPromises, reduceErrors } from 'c/copadocoreUtils';
import lookupSearch from '@salesforce/apex/CustomLookupComponentHelper.search';

import {
    label,
    schema,
    fields,
    conditionLogicOptions,
    mainObjectOptionsByAction,
    AND,
    OR,
    CUSTOM,
    REFERENCE,
    conditionLookUpOperators
} from './constants';
import {
    getSymbolForConditionLogic,
    getWhereCondition,
    reorder,
    getOperatorOptionsByFieldType,
    getInputTypeByFieldType,
    getInputVariantByFieldType,
    getInputClassByFieldType,
    getInputLayoutClassByFieldType,
    getDefaultValueByFieldType
} from './utils';

import checkSyntax from '@salesforce/apex/AutomationRuleFilterCriteriaCtrl.checkSyntax';

export default class AutomationRuleFilterCriteria extends LightningElement {
    @api recordId;

    label = label;

    readOnly = true;
    isLoading = true;
    isAccessible = false;

    mainObjectOptions = [];
    mainObject;
    conditionLogicOptions = conditionLogicOptions;
    conditionLogic = this.conditionLogicOptions[0].value;
    conditionLookUpOperators = conditionLookUpOperators;
    objectFields = [];

    @track conditions = [];
    customFilterCriteria;

    modalBody;

    _userHasPermission = false;
    @track _automationRule = {};
    _wiredAutomationRule;
    _objectInfo;

    get showIllustration() {
        return this.nothingConfigured && !this.isEditMode;
    }

    get showCurrentConfiguration() {
        return !this.showIllustration && !this.isEditMode;
    }

    get showEditButton() {
        return this.showCurrentConfiguration && !this.nothingConfigured && this._userHasPermission && !this.active;
    }

    get showConfigureCriteriaButton() {
        return this.showIllustration && this.nothingConfigured && this._userHasPermission && !this.active;
    }

    get nothingConfigured() {
        return !this.currentFilterCriteria;
    }

    get isEditMode() {
        return !this.readOnly;
    }

    get active() {
        return this._automationRule[schema.AUTOMATION_RULE_ACTIVE.fieldApiName];
    }

    get currentFilterCriteria() {
        return this._automationRule[schema.AUTOMATION_RULE_FILTER_CRITERIA.fieldApiName];
    }

    get sourceAction() {
        return this._automationRule[schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName];
    }

    get currentConditions() {
        return this._getConditionsFromInternalCriteria(JSON.parse(this.currentFilterCriteria).internalCriteria);
    }

    get isStandardCondition() {
        return !this.isCustomCondition;
    }

    get isCustomCondition() {
        return this.conditionLogic === 'CUSTOM';
    }

    get conditionLogicLabel() {
        return this.conditionLogicOptions.find((condition) => condition.value === this.conditionLogic)?.label;
    }

    get mainObjectLabel() {
        return this.mainObjectOptions.find((object) => object.value === this.mainObject)?.label;
    }

    get fieldComboboxLabel() {
        return label.FIELD_LABEL + ' (' + label.FIELD_API_NAME + ')';
    }

    get customConditionEmpty() {
        return !this.customFilterCriteria;
    }

    get automationRuleIsConfigured() {
        return (
            this._automationRule[schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName] &&
            this._automationRule[schema.AUTOMATION_RULE_AUTOMATION_CONNECTOR.fieldApiName]
        );
    }

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    getAutomationRule(result) {
        this._wiredAutomationRule = result;
        const { data, error } = result;
        if (data) {
            fields.forEach((field) => {
                this._automationRule[field.fieldApiName] = getFieldValue(data, field);
            });
            this._setMainObjectOptions();
            this._setCurrentValues();
            this.isLoading = false;
        } else if (error) {
            this.isAccessible = false;
            this._userHasPermission = false;
            this.isLoading = false;
        }
    }

    @wire(getObjectInfo, { objectApiName: schema.AUTOMATION_RULE_OBJECT.objectApiName })
    getAutomationRuleObjectInfo({ error, data }) {
        if (data) {
            this.isAccessible = data.queryable;
            this._userHasPermission = data.createable && !!data.fields[schema.AUTOMATION_RULE_FILTER_CRITERIA.fieldApiName]?.updateable;
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    @wire(getObjectInfo, { objectApiName: '$mainObject' })
    getMainObjectInfo({ error, data }) {
        if (data) {
            this._objectInfo = data;
            const sortedFields = new Map(Object.entries(data.fields).sort((a, b) => String(a[1].label).localeCompare(b[1].label)));
            for (const [key, value] of sortedFields) {
                this.objectFields.push({ label: value.label + ' (' + value.apiName + ')', value: value.apiName });
            }
            this._setCurrentValues();
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async handleEdit() {
        this.readOnly = false;
        await flushPromises();
        this._markCheckboxInputs();
        this._markLookUpInputs();
    }

    handleConfigureCriteria() {
        if (!this.automationRuleIsConfigured) {
            this.modalBody = label.CONFIGURE_CRITERIA_ERROR_BODY;
            this.template.querySelector('c-copadocore-modal').show();
            return;
        }
        if (this.mainObjectOptions.length === 0) {
            this.modalBody = label.CONFIGURE_CRITERIA_ERROR_MAIN_OBJECT_MATCH;
            this.template.querySelector('c-copadocore-modal').show();
            return;
        }
        this.handleEdit();
        this._setDefaultValues();
        this.handleAddCondition();
    }

    handleCloseModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    handleClear() {
        this._setDefaultValues();
    }

    handleChangeMainObject(event) {
        this.mainObject = event.target.value;
        this.handleClear();
    }

    handleChangeConditionLogic(event) {
        this.conditionLogic = event.target.value;
    }

    async handleCheckSyntax() {
        this.isLoading = true;
        try {
            const syntaxValidation = await this._syntaxValidation();
            if (syntaxValidation) {
                showToastSuccess(this, { message: label.CHECK_SYNTAX_SUCCESS_MESSAGE });
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
        this.isLoading = false;
    }

    handleAddCondition() {
        const newElement = {
            id: uniqueKey('condition'),
            conditionNumber: this.conditions.length + 1,
            field: '',
            fieldLabel: '',
            operator: '',
            operatorOptions: [],
            operatorLabel: '',
            inputClass: 'slds-m-bottom_xx-small',
            inputLayoutClass: 'slds-p-left_medium',
            value: null,
            isLookUp: false,
            lookUpRecordTitle: '',
            lookUpRecordUrl: '',
            lookUpObjectApiName: null,
            lookUpObjectLabel: ''
        };
        this.conditions.push(newElement);
    }

    handleDeleteCondition(event) {
        const conditionId = event.target.dataset.conditionid;
        this.conditions = this.conditions.filter((o) => o.id !== conditionId);
        reorder(this.conditions);
    }

    handleChangeField(event) {
        const index = this._findConditionIndex(event);
        this._setFieldInCondition(this.conditions[index], event.target.value);
    }

    handleChangeOperator(event) {
        const index = this._findConditionIndex(event);
        this._setOperatorInCondition(this.conditions[index], event.target.value);
    }

    handleChangeValue(event) {
        const index = this._findConditionIndex(event);
        switch (this.conditions[index].inputType) {
            case 'checkbox':
                this.conditions[index].value = event.target.checked;
                break;
            case 'number':
                this.conditions[index].value = !!event.target.value ? event.target.value : null;
                break;
            case 'reference':
                if (this._isLookUpOperatorInCondition(this.conditions[index])) {
                    this._setLookUpInConditionOnChange(this.conditions[index], event);
                } else {
                    this.conditions[index].value = event.target.value;
                }
                break;
            default:
                this.conditions[index].value = event.target.value;
                break;
        }
    }

    handleChangeCustomCriteria(event) {
        this.customFilterCriteria = event.target.value;
        const customConditionInput = this.template.querySelector('[data-id="customCondition"]');
        customConditionInput.setCustomValidity('');
    }

    handleCancel() {
        this._setCurrentValues();
        this.readOnly = true;
    }

    async handleSave() {
        this.isLoading = true;

        const formValidation = autoFormValidation(this.template, this);
        const syntaxValidation = await this._syntaxValidation();

        if (!formValidation || !syntaxValidation) {
            this.isLoading = false;
            return;
        }

        try {
            const object = {
                fields: {
                    Id: this.recordId,
                    [schema.AUTOMATION_RULE_FILTER_CRITERIA.fieldApiName]: this._generateFilterCriteriaString()
                }
            };
            await updateRecord(object);
            refreshApex(this._wiredAutomationRule);
            showToastSuccess(this, { message: this.label.CRITERIA_SUCCESSFULLY_CREATED });
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }

        this.isLoading = false;
        this.readOnly = true;
    }

    async handleLookupSearch(event) {
        const index = this._findConditionIndex(event);
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._lookupSearch, {
            title: label.Error_Searching_Records
        });

        const queryConfig = {
            searchField: `Name`,
            objectName: this.conditions[index].lookUpObjectApiName,
            searchKey: event.detail.searchTerm,
            filterFormattingParameters: [event.detail.searchTerm]
        };

        const result = await safeSearch(this, {
            queryConfig,
            objectLabel: this.conditions[index].lookUpObjectLabel
        });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }

    // PRIVATE

    async _syntaxValidation() {
        const customConditionInput = this.template.querySelector('[data-id="customCondition"]');
        const value = customConditionInput?.value;
        if (!value) {
            return true;
        }
        const response = await checkSyntax({ objectName: this.mainObject, whereCondition: value });
        if (!response.isValid) {
            customConditionInput.setCustomValidity(label.CHECK_SYNTAX_ERROR_MESSAGE + response.message);
        } else {
            customConditionInput.setCustomValidity('');
        }
        customConditionInput.reportValidity();
        return response.isValid;
    }

    _generateFilterCriteriaString() {
        let result = null;

        if (this.isCustomCondition && this.customFilterCriteria) {
            result = JSON.stringify({
                mainObject: this.mainObject,
                isCustom: true,
                internalCriteria: undefined,
                whereCondition: this.customFilterCriteria
            });
        } else if (this.conditions.length > 0) {
            const template = '{$OBJECT.FIELD.OPERATOR("VALUE")}';
            let internalCriteria = '';

            for (const [index, condition] of this.conditions.entries()) {
                let internalCriteriaTemp = `${template
                    .replace(/OBJECT/, this.mainObject)
                    .replace(/FIELD/, condition.field)
                    .replace(/OPERATOR/, condition.operator)
                    .replace(/VALUE/, condition.value)}`;

                if (this._isReferenceFieldType(condition) && this._isLookUpOperatorInCondition(condition)) {
                    internalCriteriaTemp = this._getReferenceCriteria(template, condition, internalCriteriaTemp);
                }

                internalCriteria += internalCriteriaTemp;
                if (index !== this.conditions.length - 1) {
                    internalCriteria += ' ' + getSymbolForConditionLogic(this.conditionLogic) + ' ';
                }
            }
            result = JSON.stringify({
                mainObject: this.mainObject,
                isCustom: false,
                internalCriteria: internalCriteria,
                whereCondition: this._convertToWhereCondition(internalCriteria)
            });
        }

        return result;
    }

    async _getConditionsFromInternalCriteria(internalCriteria) {
        let result = [];

        if (internalCriteria) {
            let conditions = internalCriteria
                .split(/(&&|[|]{2})/)
                .filter((item) => item !== '&&' && item !== '||')
                .map((item) => item.trim());

            let index = 0;
            for (const item of conditions) {
                let elements = item.split(/[(\).]+(?![^(]*\)})/);
                elements = elements.filter((elem) => {
                    return elem != null && elem !== '';
                });

                let data = {
                    id: uniqueKey('condition'),
                    conditionNumber: index + 1,
                    field: elements[1],
                    value: null,
                    valueClass: ''
                };

                await this._setFieldInCondition(data, elements[1]);

                let valueStr = '';
                if (elements[2].indexOf('(') > -1) {
                    this._setOperatorInCondition(data, elements[2].split('(')[0]);
                    valueStr = elements[2].split('(')[1].replaceAll('"', "'");
                } else {
                    this._setOperatorInCondition(data, elements[2]);
                    valueStr = elements[3].replaceAll('"', "'");
                    data.lookUpRecordTitle = elements[7].split('(')[1].replaceAll('"', '');
                    data.lookUpRecordUrl = '/' + valueStr.match("'(.*)'")[1];
                }
                const auxStr = valueStr.match("'(.*)'");
                data.value = auxStr[1];
                data.valueClass = data.value.indexOf('null') > -1 ? 'hide-null-value' : '';

                result.push(data);
                index++;
            }
        }
        return result;
    }

    _getConditionLogicFromInternalCriteria(internalCriteria) {
        let result = this.conditionLogicOptions[0].value;

        if (internalCriteria) {
            const logicElements = internalCriteria.split(/(&&|[|]{2})/);
            let logic = '';
            let conditionNumber = 1;

            logicElements.forEach((element) => {
                if (element === '&&') {
                    logic = `${logic} ${AND} `;
                } else if (element === '||') {
                    logic = `${logic} ${OR} `;
                } else {
                    if (element.includes('( {$') || element.includes('({$')) {
                        const brackets = element.substring(0, element.indexOf('{')).replace(/\s/g, '');
                        logic = `${logic}${brackets}${conditionNumber}`;
                    } else if (element.includes(')} )') || element.includes(')})')) {
                        const brackets = element.substring(element.indexOf('}') + 1, element.lenght).replace(/\s/g, '');
                        logic = `${logic}${conditionNumber}${brackets}`;
                    } else {
                        logic = `${logic}${conditionNumber}`;
                    }
                    conditionNumber++;
                }
            });
            if (logic.indexOf(AND) !== -1) {
                result = AND;
            } else if (logic.indexOf(OR) !== -1) {
                result = OR;
            }
        } else {
            result = CUSTOM;
        }

        return result;
    }

    _convertToWhereCondition(internalCriteria) {
        let result = '';

        if (internalCriteria) {
            const logicElements = internalCriteria.split(/(&&|[|]{2})/);
            let logic = '';

            logicElements.forEach((element) => {
                if (element.length > 0) {
                    if (element === '&&') {
                        logic = `${logic} ${AND} `;
                    } else if (element === '||') {
                        logic = `${logic} ${OR} `;
                    } else {
                        let elements = element.split(/[(\).]+(?![^(]*\)})/);
                        elements = elements.filter((elem) => {
                            return elem != null && elem !== '';
                        });

                        const field = elements[1];
                        let operator = '';
                        let value = '';
                        if (elements[2].indexOf('(') > -1) {
                            operator = elements[2].split('(')[0];
                            value = elements[2].split('(')[1].replaceAll('"', "'").match("'(.*)'")[1];
                        } else {
                            operator = elements[2];
                            value = elements[3].replaceAll('"', "'").match("'(.*)'")[1];
                        }

                        const condition = getWhereCondition(field, operator, value, this._objectInfo.fields[field].dataType);

                        logic = `${logic}${condition}`;
                    }
                }
            });

            result = logic;
        }

        return result;
    }

    _findConditionIndex(event) {
        return this.conditions.findIndex((item) => item.id === event.target.dataset.conditionid);
    }

    async _setCurrentValues() {
        if (this.currentFilterCriteria && this._objectInfo) {
            const filterCriteria = JSON.parse(this.currentFilterCriteria);
            const internalCriteria = filterCriteria.internalCriteria;
            this.conditionLogic = this._getConditionLogicFromInternalCriteria(internalCriteria);
            this.conditions = await this._getConditionsFromInternalCriteria(internalCriteria);
            this.customFilterCriteria = this.isCustomCondition ? filterCriteria.whereCondition : null;
        }
    }

    _setDefaultValues() {
        this.conditionLogic = this.conditionLogicOptions[0].value;
        this.conditions = [];
        this.customFilterCriteria = null;
    }

    _getFieldLabel(fieldApiName) {
        const option = this.objectFields.find((field) => field.value === fieldApiName);
        return option ? option.label : fieldApiName;
    }

    _getOperatorLabel(condition, operatorValue) {
        const option = condition.operatorOptions.find((operator) => operator.value === operatorValue);
        return option ? option.label : operatorValue;
    }

    _setMainObjectOptions() {
        this.mainObjectOptions = [];
        if (this.sourceAction) {
            const actionOptions = mainObjectOptionsByAction[this.sourceAction];
            if (actionOptions) {
                this.mainObjectOptions = this.mainObjectOptions.concat(actionOptions);
                this.mainObject = this.mainObjectOptions[0].value;
            }
        }
    }

    _markCheckboxInputs() {
        this.conditions.forEach((condition) => {
            if (condition.inputType === 'checkbox' && condition.value === 'true') {
                const checkboxInput = this.template.querySelector('lightning-input[data-conditionId="' + condition.id + '"]');
                if (checkboxInput) {
                    checkboxInput.checked = true;
                }
            }
        });
    }

    _markLookUpInputs() {
        this.conditions.forEach((condition) => {
            if (
                this._isReferenceFieldType(condition) &&
                this._isLookUpOperatorInCondition(condition) &&
                condition.value &&
                condition.value.indexOf('null') === -1
            ) {
                const lookupInput = this.template.querySelector(`c-lookup[data-conditionId="${condition.id}"]`);
                if (lookupInput) {
                    lookupInput.selection = [
                        {
                            Id: condition.value,
                            sObjectType: this._objectInfo.fields[condition.field].referenceToInfos[0]['apiName'],
                            icon: 'standard:choice',
                            title: condition.lookUpRecordTitle
                        }
                    ];
                }
            }
        });
    }

    async _setFieldInCondition(condition, field) {
        condition.field = field;
        condition.fieldLabel = this._getFieldLabel(field);
        condition.operatorOptions = getOperatorOptionsByFieldType(this._objectInfo.fields[field].dataType);
        condition.operator = condition.operatorOptions[0].value;
        condition.inputType = getInputTypeByFieldType(this._objectInfo.fields[field].dataType);
        condition.inputVariant = getInputVariantByFieldType(this._objectInfo.fields[field].dataType);
        condition.inputClass = getInputClassByFieldType(this._objectInfo.fields[field].dataType);
        condition.inputLayoutClass = getInputLayoutClassByFieldType(condition.inputType);
        if (this._isReferenceFieldType(condition)) {
            this._setLookUpConfigs(condition);
        }
        // make sure input component is re-rendered (because the input type has changed), otherwise when we set the value, the input is not available yet
        await flushPromises();
        condition.value = getDefaultValueByFieldType(this._objectInfo.fields[field].dataType);
    }

    _setOperatorInCondition(condition, operatorValue) {
        condition.operator = operatorValue;
        condition.operatorLabel = this._getOperatorLabel(condition, operatorValue);
        if (this._isReferenceFieldType(condition)) {
            condition.value = null;
            condition.isLookUp = this._isLookUpOperatorInCondition(condition);
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _lookupSearch(self, queryConfig) {
        return lookupSearch(queryConfig);
    }

    _isReferenceFieldType(condition) {
        return condition.inputType === 'reference';
    }

    _isLookUpOperatorInCondition(condition) {
        const result = this.conditionLookUpOperators.find((operator) => operator.value === condition.operator);
        return result;
    }

    _setLookUpConfigs(condition) {
        condition.isLookUp = true;
        condition.lookUpObjectApiName = this._objectInfo.fields[condition.field].referenceToInfos[0]['apiName'];
        condition.lookUpObjectLabel = this._objectInfo.fields[condition.field].label;
    }

    _setLookUpInConditionOnChange(condition, event) {
        const selectedValueInformation = event.target.getSelection().length ? event.target.getSelection()[0] : '';
        if (selectedValueInformation) {
            condition.value = selectedValueInformation.id;
            condition.lookUpRecordTitle = selectedValueInformation.title;
            condition.lookUpRecordUrl = '/' + selectedValueInformation.id;
        } else {
            condition.value = null;
            condition.lookUpRecordTitle = '';
            condition.lookUpRecordUrl = '';
        }
    }

    _getReferenceCriteria(template, condition, criteria) {
        criteria = criteria.substring(0, criteria.length - 1);
        let lookUpTitleCriteria = `${template
            .replace(/OBJECT/, this.mainObject)
            .replace(/FIELD/, condition.field.replace('__c', '__r.Name'))
            .replace(/OPERATOR/, condition.operator)
            .replace(/VALUE/, condition.lookUpRecordTitle)}`;
        lookUpTitleCriteria = lookUpTitleCriteria.substring(1, lookUpTitleCriteria.length);
        criteria += ' ' + REFERENCE + ' ' + lookUpTitleCriteria;
        return criteria;
    }
}