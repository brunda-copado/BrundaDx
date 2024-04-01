import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import verifyDataSet from '@salesforce/apex/DataSetAlertsCtrl.verifyDataSet';

export default class DataSetAlerts extends LightningElement {
    @api recordId;

    communicationId = 'dataSetAlerts';

    @wire(MessageContext)
    messageContext;

    @wire(verifyDataSet, { recordId: '$recordId' })
    showAlerts({ error, data }) {
        if (data) {
            data.forEach((alert) => {
                const dataSetAlert = { ...alert, communicationId: this.communicationId };
                publish(this.messageContext, COPADO_ALERT_CHANNEL, dataSetAlert);
            });
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }
}