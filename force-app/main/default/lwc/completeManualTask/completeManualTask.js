import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { publish, MessageContext } from 'lightning/messageService';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastSuccess } from 'c/copadocoreToastNotification';
import { labels, schema, statusOptions } from './constants';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import handleUpdate from '@salesforce/apex/UpdateStepStatus.handleUpdate';

export default class CompleteManualTask extends LightningElement {
    @api isNotActionButton = false;
    @api recordId;

    label = labels;
    statusOptions = statusOptions;

    showSpinner = true;
    commentsValue;
    taskDescription;
    completeInSourceEnvironment;
    completeInDestinationEnvironment;
    statusValue = 'Pending';
    currentStatus = this.label.Pending;
    jobStepHasResult = false;
    modalCommunicationId = 'modalAlerts';

    get containerClass() {
        return 'slds-modal__content' + (!this.isNotActionButton ? ' slds-var-p-around_medium' : '');
    }

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            schema.STATUS_FIELD,
            schema.RESULT_FIELD,
            schema.RESULT_DATA_JSON_FIELD,
            schema.CONFIG_JSON_FIELD,
            schema.SOURCE_ENVIRONMENT,
            schema.DESTINATION_ENVIRONMENT
        ]
    })
    wiredStep({ error, data }) {
        if (data) {
            this.commentsValue = getFieldValue(data, schema.RESULT_DATA_JSON_FIELD);
            const configJson = JSON.parse(getFieldValue(data, schema.CONFIG_JSON_FIELD));
            this.taskDescription = configJson.instructions;
            if (configJson.parameters) {
                configJson.parameters.forEach(parameter => {
                    if (parameter.name === 'performAtSource' && parameter.value === 'true') {
                        this.completeInSourceEnvironment = getFieldValue(data, schema.SOURCE_ENVIRONMENT);
                    } else if (parameter.name === 'performAtDestination' && parameter.value === 'true') {
                        this.completeInDestinationEnvironment = getFieldValue(data, schema.DESTINATION_ENVIRONMENT);
                    }
                });
            }
            this._validateResult(data);
        } else if (error) {
            this._showAlert(schema.Result_Record_Required, 'error', true, this.modalCommunicationId);
        }
        this.showSpinner = false;
    }

    @api
    async saveManualTaskFromCustomModal() {
        await this._updateManualTaskStatus();
        this.dispatchEvent(
            new CustomEvent('finishupdate', {
                detail: {
                    status: this.statusValue,
                    comments: this.commentsValue
                }
            })
        );
    }

    async updateManualTaskStatusFromActionScreen() {
        await this._updateManualTaskStatus();
        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        this.hideModal();
    }

    handleStatusChange(event) {
        this.statusValue = event.detail.value;
    }

    handleTextChange(event) {
        this.commentsValue = event.target.value;
    }

    hideModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async _updateManualTaskStatus() {
        this.showSpinner = true;
        try {
            await handleUpdate({ jobId: this.recordId, stepStatus: this.statusValue, comments: this.commentsValue });
        } catch (error) {
            this._showAlert(labels.Error_Value + ' ' + reduceErrors(error), 'error', true, this.modalCommunicationId);
        }
        showToastSuccess(this, { message: labels.Job_Step_Manual_Update });
        this.showSpinner = false;
    }

    async _validateResult(step) {
        this.jobStepHasResult = getFieldValue(step, schema.RESULT_FIELD) != null;
        if (!this.jobStepHasResult) {
            this._showAlert(labels.Result_Record_Required, 'error', true, this.modalCommunicationId);
        }
    }

    _showAlert(message, variant, dismissible, communicationId) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }
}