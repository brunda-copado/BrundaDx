import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange, getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { labels, schema } from './constants';
import { showToastSuccess } from 'c/copadocoreToastNotification';
import deactivateAutomationRule from '@salesforce/apex/AutomationRuleDeactivationCtrl.deactivateAutomationRule';

export default class AutomationActivationModal extends LightningElement {

    @api recordId;
    automationRuleName = '';
    errorMessage

    labels = labels;
    showSpinner;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.AUTOMATION_RULE_NAME] })
    getAutomationRule({ error, data }) {
        if (data) {
            this.automationRuleName = getFieldValue(data, schema.AUTOMATION_RULE_NAME);
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async deactivate(event) {
        try {
            this.showSpinner = true;
            event.preventDefault();
            await deactivateAutomationRule({ automationRuleId: this.recordId});

            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.closeQuickAction();
            showToastSuccess(this, { message: labels.TOAST_SUCCESS, messageData: [this.automationRuleName] });
        } catch (e) {
            this.errorMessage =  e.message || e.body?.message;
        } finally {
            this.showSpinner = false;
        }
    }
}