import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { uniqueKey } from 'c/copadocoreUtils';

import { showToastError } from 'c/copadocoreToastNotification';
import { autoFormValidation, handleAsyncError } from 'c/copadocoreUtils';

import search from '@salesforce/apex/CustomLookupComponentHelper.search';
import getFunctionsByApiName from '@salesforce/apex/FunctionsSelector.getFunctionsByApiName';

import DATA_JSON_FIELD from '@salesforce/schema/JobStep__c.ConfigJson__c';
import RESULT_VIEWER_JOB_STEP from '@salesforce/schema/JobStep__c.Result_Viewer_Component__c';

import NAME_FIELD from '@salesforce/schema/Function__c.Name';
import PARAMETERS_FIELD from '@salesforce/schema/Function__c.Parameters__c';
import API_NAME_FIELD from '@salesforce/schema/Function__c.API_Name__c';
import RESULT_VIEWER_FUNCTION from '@salesforce/schema/Function__c.Result_Viewer_Component__c';

import Function from '@salesforce/label/c.Function';
import Function_Configuration from '@salesforce/label/c.Function_Configuration';
import Function_Parameters from '@salesforce/label/c.Function_Parameters';
import Function_Parameters_Helptext from '@salesforce/label/c.Function_Parameters_Helptext';
import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';
import Result_Viewer_Component from '@salesforce/label/c.Result_Viewer_Component';
import ResultViewerCmpHelpText from '@salesforce/label/c.ResultViewerCmpHelpText';

export default class JobStepFunction extends LightningElement {
    label = {
        Function,
        Function_Configuration,
        Function_Parameters,
        Function_Parameters_Helptext,
        Result_Viewer_Component,
        ResultViewerCmpHelpText
    };

    @api currentFunctionId;
    @api recordId;
    @api editParameterValuesOnly;
    @api canAddParameters;
    @api readOnly;

    _readOnly;
    _configJson;
    _resultViewer;

    functionApiName;
    functionId;
    selectedFunction;
    selectedViewerComponent;

    parameters = [];

    get hasParameters() {
        return this.parameterCount > 0;
    }

    get parameterCount() {
        return this.parameters?.length;
    }

    get fullEditMode() {
        return !this.isReadOnly;
    }

    @api set configJson(value) {
        this._configJson = value;
    }

    get configJson() {
        return this._configJson;
    }

    @api set resultViewerComponent(value) {
        this._resultViewer = value
    }

    get resultViewerComponent() {
        return this._resultViewer;
    }

    @api set isReadOnly(value) {
        this._readOnly = value;
    }

    get isReadOnly() {
        return this._readOnly;
    }

    get functionDetailLink() {
        return "/" + this.functionId;
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [DATA_JSON_FIELD, RESULT_VIEWER_JOB_STEP]
    })
    wiredStep(value) {
        const { data, error } = value;

        if (data) {
            this._configJson = getFieldValue(data, DATA_JSON_FIELD);
            this._resultViewer = getFieldValue(data, RESULT_VIEWER_JOB_STEP);
            this.parseData();
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
        }
    }

    @wire(getRecord, {
        recordId: '$functionId',
        fields: [NAME_FIELD, PARAMETERS_FIELD, API_NAME_FIELD, RESULT_VIEWER_FUNCTION]
    })
    wiredFunction(value) {
        const { data, error } = value;

        if (data) {
            this.initFunction(data);
            if (!this.isReadOnly) {
                this.parameters = this.parseParameters(JSON.parse(this.selectedFunction.Parameters));
                this.selectedViewerComponent = this.updateViewerCmp(this.selectedFunction);
            }
            this.functionApiName = this.selectedFunction.ApiName;
            this.initLookup();
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            this.selectedFunction = undefined;
        }
    }

    connectedCallback() {
        this.parseData();
    }

    parseData() {
        if (this.configJson) {
            const config = JSON.parse(this.configJson);

            if (!this.functionApiName) {
                this.functionApiName = config.functionName;
            }

            if (this.isReadOnly && config.parameters) {
                this.parameters = this.parseParameters(config.parameters);
            }

            this.getFunctionDetailsFromApiName(config.functionName);
        }

        if (this.resultViewerComponent && this.isReadOnly) {
            this.selectedViewerComponent = this.resultViewerComponent;
        }
    }

    updateViewerCmp(selectedFunction) {
        let configFunctionName;

        if (this.configJson) {
            const config = JSON.parse(this.configJson);
            if (config && config.functionName) {
                configFunctionName = config.functionName;
            }
        }

        if (selectedFunction.ApiName !== configFunctionName) {
            return this.selectedFunction.ResultViewerComponent
        } else {
            return this._resultViewer;
        }
    }

    parseParameters(defaultParameters) {
        const result = [];
        let stepParameterMap;


        // TODO: Make sure Function API name matches the one in the configJson so we don't override parameters
        // from another function with the same parameter names
        if (this.configJson) {
            const config = JSON.parse(this.configJson);

            if (config && config.parameters) {
                stepParameterMap = new Map(config.parameters.map(parameter => [parameter.name, parameter]));
            }
        }

        defaultParameters.forEach((parameter) => {
            result.push({
                id: uniqueKey("parameter"),
                name: parameter.name,
                value: this.getParameterValue(stepParameterMap, parameter),
                required: parameter.required
            });
        });

        return result;
    }

    getParameterValue(stepParameterMap, parameter) {
        let result;

        const stepParameter = stepParameterMap && stepParameterMap.get(parameter.name);
        result = stepParameter ? stepParameter.value : parameter.defaultValue;

        return result;
    }

    getFunctionDetailsFromApiName(apiName) {
        getFunctionsByApiName({ functionApiName: apiName })
            .then((result) => {
                if (result && result.length > 0) {
                    this.functionId = result[0].Id;
                }
            })
            .catch((error) => {
                showToastError(this, {
                    message: error.body ? error.body.message : error.message
                });
            });
    }

    initFunction(data) {
        this.selectedFunction = {
            Id: data.id,
            Name: getFieldValue(data, NAME_FIELD),
            Parameters: getFieldValue(data, PARAMETERS_FIELD),
            ApiName: getFieldValue(data, API_NAME_FIELD),
            ResultViewerComponent: getFieldValue(data, RESULT_VIEWER_FUNCTION)
        };
    }

    initLookup() {
        const lookup = this.template.querySelector('c-lookup');

        if (lookup) {
            lookup.selection = [
                {
                    Id: this.selectedFunction.Id,
                    sObjectType: 'Function',
                    icon: 'standard:choice',
                    title: this.selectedFunction.Name,
                    subtitle: 'API Name: ' + this.functionApiName
                }
            ];
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
            this._configJson = undefined;
        }
    }

    getSelectedId(lookupData) {
        if (lookupData.detail.length) {
            this.functionId = lookupData.detail[0];
        } else {
            this.selectedFunction = undefined;
        }
    }

    @api
    getAutoFormValidation() {
        return autoFormValidation(this.template, this);
    }

    @api
    getConfig() {
        return this.generateDataJsonFieldValue();
    }

    generateDataJsonFieldValue() {
        const functionParameters = [];

        this.parameters.forEach((parameter) => {
            if (parameter.name) {
                functionParameters.push({
                    name: parameter.name,
                    value: parameter.value,
                    required: parameter.required
                });
            }
        });

        return {
            type: "Function",
            resultViewerCmp: this.selectedViewerComponent,
            configJson: {
                functionName: this.functionApiName,
                parameters: functionParameters
            }
        };
    }

    handleUpdateParameter(event) {
        const parameter = event.detail;
        this.parameters[parameter.index][parameter.name] = parameter.value;
    }

    handleViewerComponentChange(event) {
        this.selectedViewerComponent = event.target.value
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _search(self, queryConfig) {
        return search(queryConfig);
    }
}