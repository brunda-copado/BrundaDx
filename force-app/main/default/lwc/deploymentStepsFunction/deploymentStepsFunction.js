import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { showToastError } from 'c/copadocoreToastNotification';
import { autoFormValidation, uniqueKey, handleAsyncError } from 'c/copadocoreUtils';

import search from '@salesforce/apex/CustomLookupComponentHelper.search';
import getFunctionsByApiName from '@salesforce/apex/FunctionsSelector.getFunctionsByApiName';

import DATA_JSON_FIELD from '@salesforce/schema/Step__c.dataJson__c';
import NAME_FIELD from '@salesforce/schema/Function__c.Name';
import PARAMETERS_FIELD from '@salesforce/schema/Function__c.Parameters__c';
import API_NAME_FIELD from '@salesforce/schema/Function__c.API_Name__c';
import Function from '@salesforce/label/c.Function';
import Function_Parameters from '@salesforce/label/c.Function_Parameters';
import Function_Parameters_Helptext from '@salesforce/label/c.Function_Parameters_Helptext';
import Parameter_Name from '@salesforce/label/c.Parameter_Name';
import Parameter_Name_Placeholder from '@salesforce/label/c.Parameter_Name_Placeholder';
import Parameter_Value from '@salesforce/label/c.Parameter_Value';
import Parameter_Value_Placeholder from '@salesforce/label/c.Parameter_Value_Placeholder';
import DELETE from '@salesforce/label/c.DELETE';
import Add_new_parameter from '@salesforce/label/c.Add_new_parameter';
import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';

export default class DeploymentStepsFunction extends LightningElement {
    label = {
        Function,
        Function_Parameters,
        Function_Parameters_Helptext,
        Parameter_Name,
        Parameter_Name_Placeholder,
        Parameter_Value,
        Parameter_Value_Placeholder,
        DELETE,
        Add_new_parameter
    };

    @api currentFunctionId;
    @api stepId;

    oldFunctionAPIName;
    selectedFunction;
    lookupHasChanged = false;
    modalMode = 'new';
    parameters = [
        {
            id: uniqueKey('parameter'),
            parameterName: '',
            parameterValue: ''
        }
    ];

    // This variables are used to reset edited step information to the original value if modal is closed
    _originalSelectedFunctionId;
    _originalSelectedFunction;
    _originalParameters = [];

    get uniqueKey() {
        return uniqueKey('parameter');
    }

    // If stepId changes to actually be another valid step Id, the wiredStep is called again
    // but if it is not actually an id, then wiredStep is not called
    @wire(getRecord, { recordId: '$stepId', fields: [DATA_JSON_FIELD] })
    wiredStep(value) {
        const { data, error } = value;
        if (data) {
            this.parseDataIntoVariables(data);
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
        }
    }

    parseDataIntoVariables(data) {
        const dataJsonValueObject = JSON.parse(getFieldValue(data, DATA_JSON_FIELD));
        if (!this.oldFunctionAPIName) {
            this.oldFunctionAPIName = dataJsonValueObject.functionAPIName;
        }
        if (dataJsonValueObject.functionParameters) {
            this.parseFunctionParametersIntoVariables(dataJsonValueObject.functionParameters);
        }

        this.getFunctionDetailsFromApiName(dataJsonValueObject.functionAPIName);
    }

    getFunctionDetailsFromApiName(apiName) {
        getFunctionsByApiName({ functionApiName: apiName })
            .then((result) => {
                if (result && result.length > 0) {
                    this._originalSelectedFunctionId = result[0].Id;
                }
            })
            .catch((error) => {
                showToastError(this, {
                    message: error.body ? error.body.message : error.message
                });
            });
    }

    parseFunctionParametersIntoVariables(functionParameters) {
        const parameters = [];
        functionParameters.forEach((parameter) => {
            parameters.push({
                id: uniqueKey('parameter'),
                parameterName: parameter.name,
                parameterValue: parameter.defaultValue || parameter.value,
                parameterRequired: parameter.required
            });
        });
        // JSON.parse(JSON.stringify()) is used in order to create a deep copy of the array
        this._originalParameters = JSON.parse(JSON.stringify(parameters));
        this.parameters = JSON.parse(JSON.stringify(parameters));
    }

    // If _originalSelectedFunctionId changes to actually be another valid function Id, the wiredOriginalFunction is called again
    // but if it is not actually an id, then it wiredOriginalFunction is not called
    @wire(getRecord, {
        recordId: '$_originalSelectedFunctionId',
        fields: [NAME_FIELD, PARAMETERS_FIELD, API_NAME_FIELD]
    })
    wiredOriginalFunction(value) {
        const { data, error } = value;
        if (data) {
            this.selectedFunction = this._originalSelectedFunction = {
                Id: this._originalSelectedFunctionId,
                Name: getFieldValue(data, NAME_FIELD),
                Parameters: getFieldValue(data, PARAMETERS_FIELD),
                ApiName: getFieldValue(data, API_NAME_FIELD)
            };
            this.modalMode = this.stepId ? 'edit' : 'new';
            if (
                (this.modalMode === 'new' ||
                    this.oldFunctionAPIName !== this.selectedFunction.ApiName ||
                    (this.modalMode === 'edit' && this.oldFunctionAPIName == this.selectedFunction.ApiName && this.lookupHasChanged)) &&
                this.selectedFunction.Parameters
            ) {
                this.parseFunctionParametersIntoVariables(JSON.parse(this.selectedFunction.Parameters));
            }
            const lookup = this.template.querySelector('c-lookup');
            if (lookup) {
                lookup.selection = [
                    {
                        Id: this.selectedFunction.Id,
                        sObjectType: 'Function',
                        icon: 'standard:choice',
                        title: this.selectedFunction.Name,
                        subtitle: 'Function • ' + this.selectedFunction.Name
                    }
                ];
            }
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            this.selectedFunction = undefined;
        }
    }

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._search, {
            title: Error_Searching_Records
        });

        const queryConfig = {
            searchField: 'Name',
            objectName: 'Function__c',
            searchKey: event.detail.searchTerm,
            extraFilterType: undefined,
            filterFormattingParameters: undefined
        };

        const result = await safeSearch(this, { queryConfig, objectLabel: 'Function' });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }

    getSelectedId(lookupData) {
        if (lookupData.detail.length) {
            this.lookupHasChanged = true;
            this._originalSelectedFunctionId = lookupData.detail[0];
        } else {
            this.selectedFunction = undefined;
        }
    }

    handleParameterChange(event) {
        const parameterId = event.target.dataset.id;
        const index = this.parameters.findIndex((parameter) => parameter.id === parameterId);
        this.parameters[index][event.target.name] = event.detail.value;
    }

    handleAddParameter() {
        const newElement = {
            id: uniqueKey('parameter'),
            parameterName: '',
            parameterValue: ''
        };
        this.parameters = [...this.parameters, newElement];
    }

    handleDeleteParameter(event) {
        const parameterId = event.target.dataset.id;
        this.parameters = this.parameters.filter((parameter) => parameter.id !== parameterId);
    }

    @api
    getAutoFormValidation() {
        return autoFormValidation(this.template, this);
    }

    @api
    getFieldsToSave() {
        const fields = {};
        fields[DATA_JSON_FIELD.fieldApiName] = JSON.stringify(this.generateDataJSONFieldValue());
        return fields;
    }

    generateDataJSONFieldValue() {
        const functionParameters = [];
        this.parameters.forEach((parameter) => {
            functionParameters.push({
                name: parameter.parameterName,
                value: parameter.parameterValue
            });
        });

        return {
            functionAPIName: this.selectedFunction ? this.selectedFunction.ApiName : '',
            functionParameters: functionParameters
        };
    }

    @api
    restoreOriginalValues() {
        this.selectedFunction = this._originalSelectedFunction;
        this.parameters = JSON.parse(JSON.stringify(this._originalParameters));
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _search(self, queryConfig) {
        return search(queryConfig);
    }
}