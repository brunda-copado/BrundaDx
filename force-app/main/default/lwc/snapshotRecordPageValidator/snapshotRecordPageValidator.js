import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import validateSnapshot from '@salesforce/apex/GitSnapshotValidator.validateDataForRecordPage';

export default class SnapshotRecordPageValidator extends LightningElement {
    @api recordId;
    communicationId = 'snapshotmessages';

    @wire(MessageContext)
    messageContext;

    async connectedCallback() {
        const alerts = await validateSnapshot({ recordId: this.recordId });
        if (alerts) {
            alerts.forEach(alert => {
                const snapshotAlert = { ...alert, communicationId: this.communicationId };
                publish(this.messageContext, COPADO_ALERT_CHANNEL, snapshotAlert);
            });
        }
    }
}