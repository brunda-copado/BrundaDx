import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { reduceErrors } from 'c/copadocoreUtils';
import cloneTemplate from '@salesforce/apex/DataTemplateCloneCtrl.cloneTemplate';
import { NavigationMixin } from 'lightning/navigation';
import { createAlert } from './utils';
import {clearAllActionAlerts, CLONE_ALERT_ID, DATATEMPLATE_COMMUNICATION_ID} from 'c/datatemplateUtil';
export default class DataTemplateClone extends NavigationMixin(LightningElement) {
    @wire(MessageContext)
    messageContext;

    @api recordId;

    isExecuting = false;
    _communicationId = DATATEMPLATE_COMMUNICATION_ID;
    _alertId = CLONE_ALERT_ID;
    @api 
    invoke() { 
        if(!this.isExecuting){
            this.isExecuting = true;
            this.cloneTemplate();
        }
    }
    async cloneTemplate(event) {
        try {
            const resp = await cloneTemplate({ recordId: this.recordId });
            this._navigateToRecordViewPage(resp);
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this._publishOnMessageChannel(errorMessage, 'error', 'add');
        } finally {
            this.isExecuting = false;
        }
    }
    
    _navigateToRecordViewPage(recordId) {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }  

    _publishOnMessageChannel(message, type, operation) {
        clearAllActionAlerts(this.messageContext, COPADO_ALERT_CHANNEL, this._communicationId);
        const alertMessage = createAlert(message, type, true, this._communicationId, this._alertId, operation);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);

    }      
}