import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { refreshApex } from '@salesforce/apex';

import getDataTemplatesForObject from '@salesforce/apex/DataTemplateDeploymentTemplateCtrl.getDataTemplatesForObject';
import checkDuplicateName from '@salesforce/apex/DataTemplateDeploymentTemplateCtrl.checkDuplicateName';
import quickCreateTemplate from '@salesforce/apex/DataTemplateDeploymentTemplateCtrl.quickCreateTemplate';

import { label, schema, SELECT_TEMPLATE_OPTION } from './constants';

export default class DataTemplateDeploymentTemplate extends NavigationMixin(LightningElement) {
    label = label;
    schema = schema;
    requiredFlag = true;

    @api recordId;
    @api objectName;
    @api objectLabel;
    @api fieldName;
    @api fieldType;
    @api readOnlyMode;
    @api deploymentTemplateId;

    @track options = [];

    @wire(getRecord, { recordId: '$recordId', fields: [schema.SCHEMA_CREDETIAL] })
    mainTemplate;

    @wire(getDataTemplatesForObject, { recordId: '$recordId', objectName: '$objectName' })
    getDataTemplates(value) {
        this._wiredTemplateValues = value;
        const { data, error } = value;
        if (data) {
            this.requiredFlag = this.objectName === 'User' ? false : true;
            this._configureOptions(data);
            this._setDefaultOption();
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    @wire(getRecord, { recordId: '$deploymentTemplateId', fields: [schema.NAME,schema.ACTIVE] })
    getRelatedTemplateInfo({ data, error }) {
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } else if (data) {
           if(getFieldValue(data, schema.ACTIVE) === false) {
            const option = {label : getFieldValue(data, schema.NAME), value : this.deploymentTemplateId};
            this.options = [...this.options, option];
           }
        }
    }

    deploymentTemplate;
    showSpinner = false;
    saveDisabled = false;
    hasDuplicateName = false;
    displayInfo = true;
    templateName;
    validInput = true;
    
    get linkVisible() {
        return this._templateSelected() && this.readOnlyMode === false;
    }

    get dataTemplateName() {
        return this.deploymentTemplate || '';
    }

    handleChangeDataTemplate(event) {
        this.deploymentTemplateId = event.detail.value;
        
        const dataTemplateOption = this._findOptionByValue(this.deploymentTemplateId);
        if (dataTemplateOption) {
            this.deploymentTemplate = dataTemplateOption.label;
        }
        this.dispatchEvent(
            new CustomEvent('setdeploymenttemplate', {
                bubbles: true,
                composed: true,
                detail: { fieldName: this.fieldName, deploymentTemplate: this.deploymentTemplate, deploymentTemplateId: this.deploymentTemplateId }
            })
        );
    }

    handleClickDataTemplate(event) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.deploymentTemplateId,
                objectApiName: schema.DATA_TEMPLATE_OBJECT.objectApiName,
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_blank');
        });
    }

    handleClickNewDataTemplate(event) {
        this.show();
        this.templateName = `${this.objectLabel} Template`;
    }

    handleNameChange(event) {
        this.templateName = event.detail.value;
    }
    show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    handleCloseInfoAlert(event) {
        this.displayInfo = false;
    }

    handleCloseDuplicateNameAlert(event) {
        this.hasDuplicateName = false;
    }

    async handleClickSave(event) {
        try {
            this.saveDisabled = true;
            if (!this.templateName) {
                this.validInput = false;
                this._displayErrorForRequiredField();
                this.saveDisabled = false;
                return;
            }
            this.showSpinner = true;
            this.hasDuplicateName = await checkDuplicateName({ templateName: this.templateName });
            if (!this.hasDuplicateName) {
                await this._createTemplateAndAttachment();
                this._closeModal();
                this._clearValues();
                showToastSuccess(this, { message: label.SUCCESS_MESSAGE });
            }
            this.saveDisabled = false;
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleClickCancel(event) {
        this.showSpinner = false;
        this._closeModal();
        this._clearValues();
    }

    handleModalClose(event) {
        this._clearValues();
    }

    _closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    _configureOptions(dataTemplates) {
        const dataTemplateOptions = dataTemplates.map((dataTemplate) => {
            return { label: dataTemplate.Name, value: dataTemplate.Id };
        });
        this.options = [...this.options, ...dataTemplateOptions];
    }

    _setDefaultOption() {
        if (this.deploymentTemplateId) {
            const dataTemplateOption = this._findOptionByValue(this.deploymentTemplateId);
            if (dataTemplateOption) {
                this.deploymentTemplate = dataTemplateOption.label;
            }
        }
    }

    _templateSelected() {
        return this.deploymentTemplateId;
    }

    _findOptionByLabel(label) {
        return this.options.find((option) => option.label === label);
    }

    _findOptionByValue(value) {
        return this.options.find((option) => option.value === value);
    }

    _clearValues() {
        this.templateName = '';
        this.hasDuplicateName = false;
        this.displayInfo = true;
        this.validInput = true;
        this.saveDisabled = false;
    }

    _displayErrorForRequiredField() {
        this.template.querySelector('[data-id="templatename"]').reportValidity();
    }

    async _createTemplateAndAttachment() {
        await this._createDataTemplate();
        await this._createAttachment();
        await refreshApex(this._wiredTemplateValues);
        this._postTemplateCreationProcess();
    }

    async _createDataTemplate() {
        const fields = {};
        fields[schema.NAME.fieldApiName] = this.templateName;
        fields[schema.SCHEMA_CREDETIAL.fieldApiName] = getFieldValue(this.mainTemplate.data, schema.SCHEMA_CREDETIAL);
        fields[schema.MAIN_OBJECT.fieldApiName] = this.objectName;
        fields[schema.ACTIVE.fieldApiName] = true;
        const recordInput = { apiName: schema.DATA_TEMPLATE_OBJECT.objectApiName, fields };
        const result = await createRecord(recordInput);
        this.deploymentTemplateId = result.id;
    }

    async _createAttachment() {
        const credential = getFieldValue(this.mainTemplate.data, schema.SCHEMA_CREDETIAL);
        await quickCreateTemplate({
            templateId: this.deploymentTemplateId,
            mainObject: this.objectName,
            schemaCredential: credential
        });
    }

    _postTemplateCreationProcess() {
        this.options = [...this.options, { label: this.templateName, value: this.deploymentTemplateId }];
        this.deploymentTemplate = this.templateName;
        this.dispatchEvent(
            new CustomEvent('setdeploymenttemplate', {
                bubbles: true,
                composed: true,
                detail: {
                    fieldName: this.fieldName,
                    deploymentTemplate: this.deploymentTemplate,
                    deploymentTemplateId: this.deploymentTemplateId
                }
            })
        );
    }

    renderedCallback() {
        const inputCmp = this.template.querySelector('[data-id=dataTemplateName]');
        if(inputCmp) {
            inputCmp.reportValidity();
        }
    }
}