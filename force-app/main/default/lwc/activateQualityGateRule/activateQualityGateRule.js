import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import activateQualityGateRule from '@salesforce/apex/ActivateQualityGateRuleCtrl.activate';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

import { label } from './constants';

export default class ActivateQualityGateRule extends LightningElement {
    @api recordId;

    @wire(MessageContext)
    _context;

    _communicationId = 'qualityGateRuleAlerts';
    _alertId = 'qualityGateRuleActivationMessage';

    _isExecuting = false;

    @api
    async invoke() {
        if (!this._isExecuting) {
            this._isExecuting = true;
            try {
                this._clearAlert();
                const { activated, message } = await activateQualityGateRule({ qualityGateRuleId: this.recordId });
                if (activated) {
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                    showToastSuccess(this, { message: label.QUALITY_GATE_ACTIVATED });
                } else if (message) {
                    this._showAlert(message);
                }
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
            this._isExecuting = false;
        }
    }

    _showAlert(error) {
        const alert = {
            operation: 'add',
            message: error,
            dismissible: true,
            variant: 'error',
            communicationId: this._communicationId,
            id: this._alertId
        };
        publish(this._context, COPADO_ALERT_CHANNEL, alert);
    }

    _clearAlert() {
        const alert = {
            operation: 'remove',
            communicationId: this._communicationId,
            id: this._alertId
        };
        publish(this._context, COPADO_ALERT_CHANNEL, alert);
    }
}