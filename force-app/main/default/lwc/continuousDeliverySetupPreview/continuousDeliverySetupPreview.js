import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { label, columns } from './constants';

export default class ContinuousDeliverySetupPreview extends LightningElement {
    @api recordId; // deprecated
    @api summaryData;

    modalCommunicationId = 'continuousDeliverySetupPreviewAlert';
    summaryColumns = columns;
    label = label;

    @wire(MessageContext)
    messageContext;

    get isSummaryDataLoaded() {
        return this.summaryData && this.summaryData.length !== 0;
    }

    renderedCallback() {
        if(this.isSummaryDataLoaded) {
            this.messageAlert(label.CD_Setup_Preview_Info_Message, 'error', false, this.modalCommunicationId);

            const spinner = new CustomEvent('stopspinner', {
                detail: true
            });
    
            this.dispatchEvent(spinner);
        }
    }

    messageAlert(message, variant, dismissible, communicationId) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    handleNext() {
        const next = new CustomEvent('getnextstep', {
            detail: true
        });

        this.dispatchEvent(next);
    }

    handleCancel() {
        const cancel = new CustomEvent('closemodal', {
            detail: true
        });

        this.dispatchEvent(cancel);
    }
}