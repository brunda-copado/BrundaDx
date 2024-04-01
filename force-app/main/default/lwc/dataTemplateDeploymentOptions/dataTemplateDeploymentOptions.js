import { LightningElement, api, wire } from 'lwc';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { label, schema, FIELDS, SELECT_ATTACHMENT_OPTIONS } from './constants';

import getTemplateDetail from '@salesforce/apex/DataTemplateMainObjectTableCtrl.getTemplateDetail';
import updateTemplateDetailAttachment from '@salesforce/apex/DataTemplateMainObjectTableCtrl.updateTemplateDetailAttachment';
import getDescribeObject from '@salesforce/apex/DataTemplateMainObjectTableCtrl.getDescribeObject';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import deActivateTemplate from '@salesforce/apex/DataTemplateDeactivateCtrl.deActivateTemplate';

export default class DataTemplateDeploymentOptions extends LightningElement {
    @api recordId;
    @api validCredential;

    label = label;
    schema = schema;
    fields = FIELDS;
    attachmentOptions = SELECT_ATTACHMENT_OPTIONS;

    attachmentType;

    _templateDetail;
    _objectDescribe;

    editMode = false;
    showSpinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: [FIELDS.DATA_TEMPLATE_ACTIVE] })
    getTemplateDetail({ data, error }) {
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } else if (data) {
            this.dataTemplate = data;
        }
    }

    get disableInputs() {
        return !this.editMode;
    }

    get disableMatchRecordType() {
        return this.disableInputs || !this._fieldInDescribeResult('RecordTypeId');
    }

    get disbledMatchOwner() {
        return this.disableInputs || !this._fieldInDescribeResult('OwnerId');
    }

    async connectedCallback() {
        try {
            this.showSpinner = true;
            await this._loadData();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleEdit(event) {
        let templateStatus = getFieldValue(this.dataTemplate, FIELDS.DATA_TEMPLATE_ACTIVE);
        if (templateStatus) {
            this.template.querySelector('c-copadocore-modal').show();
        } else {
            this.editMode = true;
        }
    }

    handleChange(event) {
        this.attachmentType = event.detail.value;
    }

    handleCancel(event) {
        this.editMode = false;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }

        this.attachmentType = this._getSelectedAttachmentType();
    }

    async handleSave(event) {
        try {
            this.showSpinner = true;
            this.editMode = false;
            event.preventDefault();
            const fields = event.detail.fields;
            this._modifyTemplateDetail(fields);
            this.template.querySelector('lightning-record-edit-form').submit(fields);
            await updateTemplateDetailAttachment({ recordId: this.recordId, modifiedTemplateDetail: JSON.stringify(this._templateDetail) });
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async _loadData() {
        await this._getFields();
        await this._getTemplateDetail();
    }

    async _getFields() {
        const result = await getDescribeObject({ recordId: this.recordId });
        this._objectDescribe = JSON.parse(result);
    }

    async _getTemplateDetail() {
        const result = await getTemplateDetail({ recordId: this.recordId });
        this._templateDetail = JSON.parse(result);
        this.attachmentType = this._getSelectedAttachmentType();
    }

    _modifyTemplateDetail(fields) {
        this._templateDetail.dataTemplate.templateAttachmentOption = fields[FIELDS.ATTACHMENT_OPTIONS.fieldApiName];
        this._templateDetail.dataTemplate.templateMatchOwners = fields[FIELDS.MATCH_OWNERS.fieldApiName];
        this._templateDetail.dataTemplate.templateMatchRecordTypes = fields[FIELDS.MATCH_RECORD_TYPES.fieldApiName];
        this._templateDetail.dataTemplate.templateSelectedAttachmentType = this.attachmentType;
    }

    _fieldInDescribeResult(fieldName) {
        return this._objectDescribe && this._objectDescribe.findIndex((field) => field.name.toLowerCase() === fieldName.toLowerCase()) !== -1;
    }

    _getSelectedAttachmentType() {
        return this._templateDetail.dataTemplate.templateSelectedAttachmentType
            ? this._templateDetail.dataTemplate.templateSelectedAttachmentType
            : 'files';
    }

    async handleClickDeactivate(event) {
        try {
            this.showSpinner = true;
            this.handleEditCancel();
            const message = await deActivateTemplate({ recordId: this.recordId });
            if (message) {
                this._publishOnMessageChannel(message, 'error', 'add');
            } else {
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.editMode = true;
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleEditCancel() {
        this.template.querySelector('c-copadocore-modal').hide();
    }
}