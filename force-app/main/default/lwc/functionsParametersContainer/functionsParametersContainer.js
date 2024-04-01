import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

import { refreshApex } from '@salesforce/apex';

import { uniqueKey } from 'c/copadocoreUtils';

import ID_FIELD from '@salesforce/schema/Function__c.Id';
import PARAMETERS_FIELD from '@salesforce/schema/Function__c.Parameters__c';

import Execute_Function from '@salesforce/label/c.Execute_Function';
import Execute from '@salesforce/label/c.Execute';
import Save from '@salesforce/label/c.Save';
import Edit from '@salesforce/label/c.EDIT';
import Cancel from '@salesforce/label/c.Cancel';
import Function_Parameters from '@salesforce/label/c.Function_Parameters';
import Overwrite_Parameters from '@salesforce/label/c.Overwrite_Parameters';
import Parameters_Field_Help_Text from '@salesforce/label/c.Parameters_Field_Help_Text';
import Add_new_parameter from '@salesforce/label/c.Add_new_parameter';
import Parameters_Saved from '@salesforce/label/c.Parameters_Saved';
import ContextId from '@salesforce/label/c.ContextId';
import EnterContextId from '@salesforce/label/c.EnterContextId';
import HelpTextForContextId from '@salesforce/label/c.HelpTextForContextId';
import ApplicationError from '@salesforce/label/c.ApplicationError';
import SUCCESS from '@salesforce/label/c.SUCCESS';

export default class FunctionsParametersContainer extends LightningElement {
    label = {
        ApplicationError,
        Execute_Function,
        Execute,
        Save,
        Edit,
        Cancel,
        SUCCESS,
        Add_new_parameter,
        Function_Parameters,
        Overwrite_Parameters,
        Parameters_Field_Help_Text,
        ContextId,
        EnterContextId,
        HelpTextForContextId
    };

    @api recordId;
    @api editValuesOnly;
    @api canAddParameters;
    @api enableRequiredInput;

    @track _target = '';
    @track _contextId = '';
    @track _overwriteParameters = '';

    readOnly;
    editMode = false;
    isFieldEditable;
    selectedFunction;
    areDetailsVisible;
    parameters = [];

    get showEdit() {
        return !this.editMode && !this.areDetailsVisible;
    }

    get hasParameters() {
        return this.parameterCount > 0;
    }

    get parameterCount() {
        return this.parameters?.length;
    }

    @api
    get target() {
        return this._target;
    }

    set target(val) {
        this._target = val;
    }

    @api
    get contextId() {
        return this._contextId;
    }

    set contextId(val) {
        this._contextId = val;
    }

    @api
    get overwriteParameters() {
        return this._overwriteParameters;
    }

    set overwriteParameters(val) {
        this._overwriteParameters = val;
    }

    connectedCallback() {
        this.areDetailsVisible = this._target;
        this.readOnly = !this.editValuesOnly;
    }

    parseParameters(functionParameters) {
        const parameters = [];

        functionParameters.forEach(parameter => {
            parameters.push({
                id: uniqueKey("parameter"),
                name: parameter.name,
                value: parameter.defaultValue,
                required: parameter.required
            });
        });

        this.parameters = JSON.parse(JSON.stringify(parameters));
    }

    @wire(getObjectInfo, { objectApiName: PARAMETERS_FIELD.objectApiName })
    wiredInfo({ error, data }) {
        if (error) {
            this.showToastMessage(this.label.ApplicationError, error.body.message, 'error', 'dismissable');
            this.readOnly = true;
        } else if (data) {
            const field = data.fields[PARAMETERS_FIELD.fieldApiName];
            this.isFieldEditable = field.updateable;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [PARAMETERS_FIELD]
    })
    wiredOriginalFunction(value) {
        const { data, error } = value;

        if (data) {
            this.selectedFunction = {
                Id: data.id,
                Parameters: getFieldValue(data, PARAMETERS_FIELD)
            };

            this.parseParameters(JSON.parse(this.selectedFunction.Parameters));
        } else if (error) {
            this.showToastMessage(this.label.ApplicationError, error.body.output.errors[0].message, 'error', 'dismissable');
            this.selectedFunction = undefined;
        }
    }

    handleChangeContextId(event) {
        this._contextId = event.target.value;
    }

    handleUpdateParameter(event) {
        const parameter = event.detail;
        this.parameters[parameter.index][parameter.name] = parameter.value;
    }

    handleUpdateRequired(event) {
        this.handleUpdateParameter(event);
        this.parameters = JSON.parse(JSON.stringify(this.parameters));
    }

    handleAddParameter(event) {
        const parameter = event.detail;
        this.parameters = [...this.parameters, parameter];
    }

    handleDeleteParameter(event) {
        const parameterId = event.detail;
        this.parameters = this.parameters.filter((parameter) => parameter.id !== parameterId);
    }

    handleSave() {
        const fields = {
            [ID_FIELD.fieldApiName]: this.recordId,
            [PARAMETERS_FIELD.fieldApiName]: JSON.stringify(this.generateDataJSONFieldValue())
        };

        updateRecord({ fields })
            .then(() => {
                this.showToastMessage(this.label.SUCCESS, Parameters_Saved, 'success', 'dismissable');
                this.editMode = false;
                this.readOnly = true;
                return refreshApex(this.contact);
            })
            .catch(error => {
                this.showToastMessage(this.label.ApplicationError, error.body.output.errors[0].message, 'error', 'dismissable');
            });
    }

    handleExecute() {
        this.dispatchEvent(new FlowAttributeChangeEvent('contextId', this._contextId));
        this._overwriteParameters = JSON.stringify(this.generateDataJSONFieldValue());
        this.dispatchEvent(new FlowAttributeChangeEvent('overwriteParameters', this._overwriteParameters));
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleCancel() {
        this.editMode = false;
        this.readOnly = true;
        this.parseParameters(JSON.parse(this.selectedFunction.Parameters));
    }

    toggleEditMode() {
        this.editMode = true;
        this.readOnly = false;
    }

    generateDataJSONFieldValue() {
        const result = [];

        this.parameters.forEach(parameter => {
            result.push({
                name: parameter.name,
                defaultValue: parameter.value,
                required: parameter.required
            });
        });

        return result;
    }

    showToastMessage(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            })
        );
    }
}