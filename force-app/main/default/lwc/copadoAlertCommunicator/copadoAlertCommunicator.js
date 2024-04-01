import { LightningElement, wire,api } from 'lwc';
import getAllAlerts from '@salesforce/apex/CopadoAlertCommunicatorCtrl.getAlerts';
import { publish, MessageContext } from 'lightning/messageService';
import alertMessage from '@salesforce/messageChannel/CopadoAlert__c';
import { reduceErrors } from 'c/copadocoreUtils';
const ERROR_VARIANT = 'error';
const ALERT_OPERATION_ADD = 'add';

export default class CopadoAlertCommunicator extends LightningElement {
    @api recordId;
    @api communicationId;
    @wire(MessageContext)
    messageContext;

    errorAlert = null;

    get hasErrorAlert() {
        if (this.errorAlert) {
            return true;
        } else {
            return false;
        }
    }

    connectedCallback() {
        this._alertCheck();   
    }

    handleCloseAlert() {
        this.errorAlert = null;
    }

    async _alertCheck() {
        try {
            const alerts = await getAllAlerts({ recordId: this.recordId , communicationId: this.communicationId});
            this._handleAlerts(alerts);
            
        } catch (error) {
            this._handleError(reduceErrors(error));
            
        }
    }

    _handleAlerts(alerts) {
        if(alerts) {
            alerts.forEach((eachAlert) => {
                const alert = Object.assign({}, eachAlert);
                alert.operation = ALERT_OPERATION_ADD;
                alert.communicationId = this.communicationId;
                this._publishAlert(alert);
            }
            );
        }
    }

    _publishAlert(alert) {
        publish(this.messageContext, alertMessage, alert);
    }

    _handleError(message) {
        this.errorAlert = this._prepareAlert(message,ERROR_VARIANT,true);
    }

    _prepareAlert(message, variant, isDismissible) {
        return { message: message, variant: variant, dismissible: isDismissible };
    }

}