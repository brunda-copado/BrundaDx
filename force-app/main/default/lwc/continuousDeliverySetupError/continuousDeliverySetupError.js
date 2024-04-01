import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { label } from './constants';

export default class ContinuousDeliverySetupError extends LightningElement {
    @api messages;

    label = label;
    modalCommunicationId = 'continuousDeliverySetupErrorAlert';
    splittedMessages = [];
    isRendered = false;

    @wire(MessageContext)
    messageContext;

    renderedCallback() {
        if(!this.isRendered) {
            this.messageAlert(label.You_cant_configure_Continuous_Delivery, 'error', false, this.modalCommunicationId);
            this.splittedMessages = this.messages.split('-');

            const spinner = new CustomEvent('stopspinner', {
                detail: true
            });

            this.dispatchEvent(spinner);
            this.isRendered = true;
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

    handleCancel() {
        const cancel = new CustomEvent('closemodal', {
            detail: true
        });

        this.dispatchEvent(cancel);
    }
}