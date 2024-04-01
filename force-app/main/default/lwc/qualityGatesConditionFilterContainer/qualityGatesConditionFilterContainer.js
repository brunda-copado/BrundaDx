import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import * as utils from 'c/copadocoreUtils';
import { label, propertyOptions, operatorOptions, logicOperator } from './constants';

import FILTER_CRITERIA from '@salesforce/schema/Quality_Gate_Rule_Condition__c.Filter_Criteria__c';

const INPUT_NUMBER_LENGTH = 100;
const FIELDS = [FILTER_CRITERIA];

export default class QualityGatesConditionFilterContainer extends LightningElement {
    @api recordId;

    data;
    filterLogic = '';
    filterLogicChain = '';
    label = label;
    propertyOptions = propertyOptions;
    operatorOptions = operatorOptions;
    logicOperator = logicOperator;
    inputLength = INPUT_NUMBER_LENGTH;
    editableMode = false;
    isLoading = true;

    _conditions;
    _conditionsBackup;
    _filterBackup = '';

    get formattedDataList() {
        return this._conditions;
    }

    get isConditionListEmpty() {
        return this._conditions.length === 0;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            showToastError(this, { message: error.body.message });
            this._conditionsBackup = [];
        } else if (data) {
            this.data = getFieldValue(data, FILTER_CRITERIA);
            this._conditions = this._formatData();
            this._conditionsBackup = utils.cloneData(this._conditions);
            this.isLoading = false;
        }
    }

    validateData() {
        if (utils.autoFormValidation(this.template, this)) {
            if (this._validateFilterLogic()) {
                this.filterLogicChain = this._prepareSendData();
                this._save();
            }
        }
    }

    filterLogicChangeHandler(event) {
        this.filterLogic = event.target.value;
    }

    propertyFieldChangeHandler(event) {
        const conditionId = event.target.dataset.conditionid;
        const index = this._conditions.findIndex((item) => item.id === conditionId);

        this._conditions[index].property = event.target.value;
    }

    operatorFieldChangeHandler(event) {
        const conditionId = event.target.dataset.conditionid;
        const index = this._conditions.findIndex((item) => item.id === conditionId);

        this._conditions[index].operator = event.target.value;
    }

    valueChangeHandler(event) {
        const conditionId = event.target.dataset.conditionid;
        const index = this._conditions.findIndex((item) => item.id === conditionId);

        this._conditions[index].value = event.target.value;
    }

    editConditions() {
        if (this._conditions.length === 0) {
            this.addCondition();
        }

        this.editableMode = true;
    }

    addCondition() {
        let newElement = {
            id: utils.uniqueKey('condition'),
            conditionNumber: this._conditions.length + 1,
            property: '',
            operator: '',
            value: ''
        };

        this.editableMode = true;
        this._conditions = [...this._conditions, newElement];
        this.filterLogic = this._conditions.length === 1 ? `${this._conditions.length}` : `${this.filterLogic} AND ${this._conditions.length}`;
    }

    deleteCondition(event) {
        const conditionId = event.target.dataset.conditionid;
        this._conditions = this._conditions.filter((o) => o.id !== conditionId);
        this._reorder();
        this._resetFilterLogic();
    }

    handleEditCancel() {
        this._conditions = JSON.parse(JSON.stringify(this._conditionsBackup));
        this.filterLogic = this._filterBackup;
        this.editableMode = false;
    }

    // PRIVATE

    _reorder() {
        this._conditions.forEach((item, index) => {
            item.conditionNumber = index + 1;
        });
    }

    _setFilterLogic() {
        const logicElements = this.data.split(/(&&|[|]{2})/);
        let logic = '';
        let conditionNumber = 1;

        logicElements.forEach((element) => {
            if (element === '&&') {
                logic = `${logic} AND `;
            } else if (element === '||') {
                logic = `${logic} OR `;
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

        this.filterLogic = logic;
        this._filterBackup = logic;
    }

    _formatData() {
        let formattedData = [];

        if (this.data === null) {
            this.filterLogic = '';
            this._filterBackup = '';
        } else {
            let conditions = this.data
                .split(/(&&|[|]{2})/)
                .filter((item) => item !== '&&' && item !== '||')
                .map((item) => item.trim());
            this._setFilterLogic();

            conditions.forEach((item, index) => {
                let elements = item.split(/[(\).]+(?![^(]*\)})/);
                elements = elements.filter((elem) => {
                    return elem != null && elem !== '';
                });

                let data = {
                    id: utils.uniqueKey('condition'),
                    conditionNumber: index + 1,
                    property: elements[1],
                    operator: elements[2].split('(')[0],
                    value: ''
                };

                const valueStr = elements[2].split('(')[1].replaceAll('"', "'");
                const auxStr = valueStr.match("'(.*)'");
                data.value = auxStr[1];

                formattedData.push(data);
            });
        }
        return formattedData;
    }

    async _save() {
        this.isLoading = true;
        const object = {
            fields: {
                Id: this.recordId,
                [FILTER_CRITERIA.fieldApiName]: this.filterLogicChain
            }
        };

        try {
            await updateRecord(object);
            showToastSuccess(this, { message: this.label.SAVE_SUCCESS_MESSAGE });
        } catch (error) {
            let validationErrorMessage = this._isTriggerValidationError(error);
            let errorMessage = '';
            if (validationErrorMessage) {
                errorMessage = validationErrorMessage;
            } else{
                errorMessage = error.body.message;
            }
            showToastError(this, { message: errorMessage});
        }

        this.isLoading = false;
        this.editableMode = false;
    }

    _isTriggerValidationError(error){
        let validationErrorMessage;
        if (error.body.output.errors && error.body.output.errors.length && error.body.output.errors[0].errorCode === 'FIELD_CUSTOM_VALIDATION_EXCEPTION') {
            validationErrorMessage = error.body.output.errors[0].message;
        }
        return validationErrorMessage;
    }

    _isInteger(val) {
        return /^[-]?\d+$/.test(val);
    }

    _prepareSendData() {
        const template = '{$Changes.PROPERTY.OPERATOR("VALUE")}';
        const filterLogicElems = this.filterLogic.split(/\s/);
        let filterCriteriaValue = '';
        let condition;

        if (this._conditions.length === 0) {
            filterCriteriaValue = '';
        } else if (this._conditions.length === 1) {
            this.filterLogic = '';
            condition = this._conditions[0];
            filterCriteriaValue = template
                .replace(/PROPERTY/, condition.property)
                .replace(/OPERATOR/, condition.operator)
                .replace(/VALUE/, condition.value);
        } else {
            filterLogicElems.forEach((elem) => {
                let auxElem;
                if (this._isInteger(elem)) {
                    condition = this._conditions.find((o) => o.conditionNumber === parseInt(elem, 10));
                    filterCriteriaValue = `${filterCriteriaValue}${template
                        .replace(/PROPERTY/, condition.property)
                        .replace(/OPERATOR/, condition.operator)
                        .replace(/VALUE/, condition.value)} `;
                } else if (elem === '(') {
                    filterCriteriaValue = `${filterCriteriaValue} ( `;
                } else if (elem === ')') {
                    filterCriteriaValue = `${filterCriteriaValue} ) `;
                } else if (!this._isInteger(elem) && elem.includes('(')) {
                    const bracketsNumber = elem.split('').filter((x) => x === '(').length;
                    let brackets = '';
                    auxElem = elem.replace(/\(/g, '');
                    condition = this._conditions.find((o) => o.conditionNumber === parseInt(auxElem, 10));

                    for (let i = 0; i < bracketsNumber; i++) {
                        brackets += '(';
                    }
                    filterCriteriaValue = `${filterCriteriaValue}${brackets} ${template
                        .replace(/PROPERTY/, condition.property)
                        .replace(/OPERATOR/, condition.operator)
                        .replace(/VALUE/, condition.value)} `;
                } else if (!this._isInteger(elem) && elem.includes(')')) {
                    const bracketsNumber = elem.split('').filter((x) => x === ')').length;
                    let brackets = '';
                    auxElem = elem.replace(/\)/g, '');
                    condition = this._conditions.find((o) => o.conditionNumber === parseInt(auxElem, 10));

                    for (let i = 0; i < bracketsNumber; i++) {
                        brackets += ')';
                    }

                    filterCriteriaValue = `${filterCriteriaValue}${template
                        .replace(/PROPERTY/, condition.property)
                        .replace(/OPERATOR/, condition.operator)
                        .replace(/VALUE/, condition.value)} ${brackets} `;
                } else if (elem === this.logicOperator.AND) {
                    filterCriteriaValue = `${filterCriteriaValue}&& `;
                } else if (elem === this.logicOperator.OR) {
                    filterCriteriaValue = `${filterCriteriaValue}|| `;
                }
            });
        }

        return filterCriteriaValue;
    }

    _checkElemsInExpression(logicExpElemsSeparated) {
        const conditionNumberList = this._conditions.map((condition) => condition.conditionNumber);
        const elementsbackup = new Set(conditionNumberList);
        let elements = new Set(conditionNumberList);
        let elementsFound = new Set();
        let elemRepeatedError = false;
        let elemExtraError = false;

        logicExpElemsSeparated.forEach((elem) => {
            if (this._isInteger(elem)) {
                const conditionNumber = parseInt(elem, 10);

                if (!elements.has(conditionNumber) && elementsFound.has(conditionNumber)) {
                    elemRepeatedError = true;
                } else if (!elements.has(conditionNumber)) {
                    elemExtraError = true;
                } else if (elements.has(conditionNumber)) {
                    elements.delete(conditionNumber);
                    elementsFound.add(conditionNumber);
                }
            }
        });

        if (elemRepeatedError) {
            showToastError(this, { message: this.label.REPEATED_CONDITIONS_ERROR_MESSAGE });
            return false;
        }

        if (elemExtraError) {
            showToastError(this, { message: this.label.EXTRA_CONDITIONS_ERROR_MESSAGE });
            return false;
        }

        if (elementsbackup.size !== elementsFound.size) {
            showToastError(this, { message: this.label.MISSED_CONDITIONS_ERROR_MESSAGE });
            return false;
        }

        return true;
    }

    _validate(expression) {
        const pattern = /\(\d\)|\d (?:AND|OR) \d|\d/g;

        while (true) {
            const replaced = expression.replace(pattern, '1');

            // if the expression has been reduced to "1", it's valid
            if (replaced === '1') return true;

            // if the pattern didn't match, it's invalid
            if (replaced === expression) return false;

            // otherwise, continue replacing
            expression = replaced;
        }
    }

    _validateFilterLogic() {
        let logicExpElemsSeparated = [];
        let isValid = false;

        if (this.filterLogic === '' && this._conditions.lenght > 0) {
            this._resetFilterLogic();
        }

        let logicExp = this.filterLogic.toUpperCase().replace(/\s+/g, ' ').trim();
        const logicExpElems = logicExp.split(/\s/);

        logicExpElems.forEach((elem) => {
            if (elem.includes('(')) {
                const bracketsNumber = elem.split('').filter((x) => x === '(').length;
                if (bracketsNumber === 1) {
                    logicExpElemsSeparated.push('(');
                    logicExpElemsSeparated.push(elem.replace('(', ''));
                } else {
                    for (let i = 0; i < bracketsNumber; i++) {
                        logicExpElemsSeparated.push('(');
                    }
                    logicExpElemsSeparated.push(elem.replace(/\(/g, ''));
                }
            } else if (elem.includes(')')) {
                const bracketsNumber = elem.split('').filter((x) => x === ')').length;
                if (bracketsNumber === 1) {
                    logicExpElemsSeparated.push(elem.replace(')', ''));
                    logicExpElemsSeparated.push(')');
                } else {
                    logicExpElemsSeparated.push(elem.replace(/\)/g, ''));
                    for (let i = 0; i < bracketsNumber; i++) {
                        logicExpElemsSeparated.push(')');
                    }
                }
            } else {
                logicExpElemsSeparated.push(elem);
            }
        });

        if (this._checkElemsInExpression(logicExpElemsSeparated)) {
            isValid = true;
        } else {
            return false;
        }

        logicExpElemsSeparated = logicExpElemsSeparated.join(' ');

        if (this.filterLogic === '' || this._validate(this.filterLogic)) {
            isValid = true;
        } else {
            showToastError(this, { message: this.label.WRONG_SYNTAX_ERROR_MESSAGE });
            return false;
        }

        return isValid;
    }

    _resetFilterLogic() {
        const length = this._conditions.length;
        this.filterLogic = '';
        this._conditions.forEach((item, index) => {
            this.filterLogic += index !== length - 1 ? `${item.conditionNumber} AND ` : `${item.conditionNumber}`;
        });
    }
}