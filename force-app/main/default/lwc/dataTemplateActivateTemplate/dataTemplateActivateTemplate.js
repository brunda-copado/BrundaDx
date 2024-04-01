import { LightningElement, api, wire } from 'lwc';

import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { createAlert } from './utils';
import { label } from './constants';
import activateTemplate from '@salesforce/apex/DataTemplateActivateTemplateCtrl.activateTemplate';

import STATUS from '@salesforce/schema/Data_Template__c.Active__c';
import ID_FIELD from '@salesforce/schema/Data_Template__c.Id';
import { clearAllActionAlerts, ACTIVATE_ALERT_ID } from 'c/datatemplateUtil';
export default class DataTemplateActivateTemplate extends LightningElement {
    @wire(MessageContext)
    messageContext;

    label = label;
    isExecuting = false;
    communicationId = 'DataTemplateAlerts';
    alertId = ACTIVATE_ALERT_ID;
    @api recordId;

    async handleClickActivate(event) {
        try {
            if (this.isExecuting) {
                return;
            }
            this.isExecuting = true;
            const message = await activateTemplate({ recordId: this.recordId });
            if (message) {
                this._publishOnMessageChannel(message, 'error', 'add');
            } else {
                await this._updateDataTemplate();
                this._clearActivateAlert();
                const successMessage = label.SUCCESS_MESSAGE;
                showToastSuccess(this, { message: successMessage });
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.isExecuting = false;
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleClickCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    _publishOnMessageChannel(message, type, operation) {
        clearAllActionAlerts(this.messageContext, COPADO_ALERT_CHANNEL, this.communicationId);
        const alertMessage = createAlert(message, type, true, this.communicationId, this.alertId, operation);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);
    }

    async _updateDataTemplate() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS.fieldApiName] = true;
        const recordInput = { fields };
        await updateRecord(recordInput);
    }

    _clearActivateAlert() {
        const alertMessage = createAlert(null, null, null, this.communicationId, this.alertId, 'remove');
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);
    }
}