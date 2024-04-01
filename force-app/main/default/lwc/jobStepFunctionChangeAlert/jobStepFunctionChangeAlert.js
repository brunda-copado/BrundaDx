import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

import FUNCTION_NOT_FOUND from '@salesforce/label/c.Function_not_Found';
import JOB_STEP_FUNCTION_CHANGE_ALERT from '@salesforce/label/c.Job_Step_Function_Change_Alert';

import TYPE_FIELD from '@salesforce/schema/JobStep__c.Type__c';
import CONFIG_JSON_FIELD from '@salesforce/schema/JobStep__c.ConfigJson__c';
import NAME_FIELD from '@salesforce/schema/Function__c.Name';
import PARAMETERS_FIELD from '@salesforce/schema/Function__c.Parameters__c';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import getFunctionsByApiName from '@salesforce/apex/FunctionsSelector.getFunctionsByApiName';

export default class JobStepFunctionChangeAlert extends LightningElement {
    @api recordId;

    message = JOB_STEP_FUNCTION_CHANGE_ALERT;
    showAlert;

    _functionId;
    _functionName;
    _stepParameters = [];
    _functionParameters = [];

    // Wire

    @wire(getRecord, { recordId: '$recordId', fields: [TYPE_FIELD, CONFIG_JSON_FIELD] })
    wiredJobStep({ data, error }) {
        if (data) {
            if(getFieldValue(data, TYPE_FIELD) === 'Function') {
                const configJson = JSON.parse( getFieldValue(data, CONFIG_JSON_FIELD) );
                this._stepParameters = configJson.parameters;
                this._getFunctionId(configJson.functionName);
            }
        } else if (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    @wire(getRecord, { recordId: '$_functionId', fields: [NAME_FIELD, PARAMETERS_FIELD] })
    wiredFunction({ data, error }) {
        if (data) {
            this._functionName = getFieldValue(data, NAME_FIELD);
            this._functionParameters = JSON.parse( getFieldValue(data, PARAMETERS_FIELD) );
            this._compareParameters();
        } else if (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    // PRIVATE

    async _getFunctionId(functionApiName) {
        try {
            const result = await getFunctionsByApiName({ functionApiName });
            if (result && result.length > 0) {
                this._functionId = result[0].Id;
            } else {
                showToastError(this, {
                    message: FUNCTION_NOT_FOUND + functionApiName
                });
            }
        } catch (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    _compareParameters() {
        if ((this._stepParameters.length !== this._functionParameters.length) || this._isDifferent()) {
            this.showAlert = true;
        }
    }


    _isDifferent() {
        return this._functionParameters.some((functionParameter) => {
            const stepParameter = this._findSameParameter(functionParameter);
            if (this._isRequiredEmpty(functionParameter, stepParameter)) {
                return true;
            }
            return !stepParameter;
        });
    }


    _findSameParameter(functionParameter) {
        return this._stepParameters.find((stepParameter) => (functionParameter.name === stepParameter.name));
    }


    _isRequiredEmpty(functionParameter, stepParameter) {
        return functionParameter.required && !stepParameter?.value;
    }
}