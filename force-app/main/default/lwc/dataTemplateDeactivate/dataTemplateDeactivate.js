import { LightningElement, api, wire } from 'lwc';

import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import { CloseActionScreenEvent } from 'lightning/actions';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { createAlert } from './utils';
import { label } from './constants';
import deActivateTemplate from '@salesforce/apex/DataTemplateDeactivateCtrl.deActivateTemplate';
import { formatLabel } from 'c/copadocoreUtils';
import {getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import DATA_TEMPLATE_NAME_FIELD from '@salesforce/schema/Data_Template__c.Name';
import { clearAllActionAlerts, DEACTIVATE_ALERT_ID, DATATEMPLATE_COMMUNICATION_ID } from 'c/datatemplateUtil';
export default class DataTemplateDeactivate extends LightningElement {
    @wire(MessageContext)
    messageContext;

    label = label;
    communicationId = DATATEMPLATE_COMMUNICATION_ID;
    alertId = DEACTIVATE_ALERT_ID;

    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [DATA_TEMPLATE_NAME_FIELD] })
    dataTemplate;

    isExecuting = false;
    async handleClickDeactivate(event) {
        try {
            this.isExecuting = true;
            const message = await deActivateTemplate({ recordId: this.recordId });
            if (message) {
                this._publishOnMessageChannel(message, 'error', 'add');
            } else {
                const successMessage = formatLabel(label.SUCCESS_MESSAGE, [this.dataTemplate.data.fields.Name.value]);;
                getRecordNotifyChange([{recordId: this.recordId}]);
                showToastSuccess(this, { message: successMessage });
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this._publishOnMessageChannel(errorMessage, 'error', 'add');
        } finally {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.isExecuting = false;
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
}