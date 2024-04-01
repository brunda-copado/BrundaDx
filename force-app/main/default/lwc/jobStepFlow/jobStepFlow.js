import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { uniqueKey } from 'c/copadocoreUtils';

import { showToastError } from 'c/copadocoreToastNotification';
import { autoFormValidation } from 'c/copadocoreUtils';

import DATA_JSON_FIELD from '@salesforce/schema/JobStep__c.ConfigJson__c';
import RESULT_VIEWER_CMP_FIELD from '@salesforce/schema/JobStep__c.Result_Viewer_Component__c';

import getFlowsAvailableForExecution from '@salesforce/apex/DeploymentStepsUtils.getFlowsAvailableForExecution';

import SALESFORCE_FLOW from '@salesforce/label/c.SALESFORCE_FLOW';
import Flow_Configuration from '@salesforce/label/c.Flow_Configuration';
import Salesforce_Flow_Placeholder from '@salesforce/label/c.Salesforce_Flow_Placeholder';
import Flow_Variables from '@salesforce/label/c.Flow_Variables';
import Result_Viewer_Component from '@salesforce/label/c.Result_Viewer_Component';
import ResultViewerCmpHelpText from '@salesforce/label/c.ResultViewerCmpHelpText';

export default class JobStepFlow extends LightningElement {
    label = {
        SALESFORCE_FLOW,
        Flow_Configuration,
        Salesforce_Flow_Placeholder,
        Flow_Variables,
        Result_Viewer_Component,
        ResultViewerCmpHelpText
    };

    @api recordId;
    @api editParameterValuesOnly;
    @api canAddParameters;
    @api readOnly;

    _readOnly;
    _configJson;
    _resultViewer;

    flowOptions;
    selectedFlow;
    selectedViewerComponent;

    parameters = [];

    get hasParameters() {
        return this.parameterCount > 0;
    }

    get parameterCount() {
        return this.parameters?.length;
    }

    get fullEditMode() {
        return !this.isReadOnly && !this.editParameterValuesOnly;
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

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [DATA_JSON_FIELD, RESULT_VIEWER_CMP_FIELD]
    })
    wiredStep(value) {
        const { data, error } = value;

        if (data) {
            this._configJson = getFieldValue(data, DATA_JSON_FIELD);
            this._resultViewer = getFieldValue(data, RESULT_VIEWER_CMP_FIELD);
            this.parseData();
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
        }
    }

    @wire(getFlowsAvailableForExecution)
    wiredFlows(value) {
        const { data, error } = value;
        if (data) {
            const flows = JSON.parse(data);
            this.flowOptions = flows.map(({ flowLabel, flowApiName }) => ({ label: flowLabel, value: flowApiName }));
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
            this.flowOptions = undefined;
        }
    }

    connectedCallback() {
        this.parseData();
    }

    parseData() {
        if (this.configJson) {
            const config = JSON.parse(this.configJson);

            if (config.flowName) {
                this.selectedFlow = config.flowName;
            }

            if (config.parameters) {
                this.parameters = this.parseParameters(config.parameters);
            }
        }
        if (this.resultViewerComponent) {
            this.selectedViewerComponent = this.resultViewerComponent;
        }
    }

    parseParameters(parameters) {
        const result = [];

        parameters.forEach((parameter) => {
            result.push({
                id: uniqueKey("parameter"),
                name: parameter.name,
                value: parameter.value || parameter.defaultValue,
                required: parameter.required
            });
        });

        return result;
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
        const flowParameters = [];

        this.parameters.forEach((parameter) => {
            if (parameter.name) {
                flowParameters.push({
                    name: parameter.name,
                    value: parameter.value
                });
            }
        });

        return {
            type: "Flow",
            resultViewerCmp: this.selectedViewerComponent,
            configJson: {
                flowName: this.selectedFlow,
                parameters: flowParameters
            }
        };
    }

    handleFlowChange(event) {
        this.selectedFlow = event.target.value;
        this.selectedViewerComponent = '';
    }

    handleViewerComponentChange(event) {
        this.selectedViewerComponent = event.target.value
    }

    handleUpdateParameter(event) {
        const parameter = event.detail;
        this.parameters[parameter.index][parameter.name] = parameter.value;
    }

    handleAddParameter(event) {
        const parameter = event.detail;
        this.parameters = [...this.parameters, parameter];
    }

    handleDeleteParameter(event) {
        const parameterId = event.detail;
        this.parameters = this.parameters.filter((parameter) => parameter.id !== parameterId);
    }
}