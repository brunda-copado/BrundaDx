import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import { labels, schema } from './constants';
import { showToastSuccess } from 'c/copadocoreToastNotification';
import activateAutomationRule from '@salesforce/apex/AutomationRuleActivationCtrl.activateAutomationRule';
import getDuplicatedAutomationRule from '@salesforce/apex/AutomationRuleActivationCtrl.getDuplicatedAutomationRule';

export default class AutomationActivationModal extends LightningElement {

    @api recordId;
    automationRuleName = '';
    errorMessage;
    duplicatedRules;

    labels = labels;
    duplicatedRulesColumns;
    showSpinner;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.AUTOMATION_RULE_NAME] })
    getAutomationRule({ error, data }) {
        if (data) {
            this.automationRuleName = getFieldValue(data, schema.AUTOMATION_RULE_NAME);
        }
    }

    @wire(getObjectInfo, { objectApiName: schema.AUTOMATION_RULE_OBJECT })
    getAutomationRuleInfo(result) {
        if (result.data) {
            this.duplicatedRulesColumns = [
                {label: result.data.fields[schema.AUTOMATION_RULE_NAME.fieldApiName].label, fieldName: 'RecordLink', type: 'url',
                    typeAttributes: {label: { fieldName: schema.AUTOMATION_RULE_NAME.fieldApiName }, target: '_blank'}},
                { label: result.data.fields[schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName].label,
                    fieldName: schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName, hideDefaultActions: true },
                { label: result.data.fields[schema.AUTOMATION_RULE_AUTOMATED_ACTION.fieldApiName].label,
                    fieldName: schema.AUTOMATION_RULE_AUTOMATED_ACTION.fieldApiName, hideDefaultActions: true }
            ]
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async activate(event) {
        try {
            this.showSpinner = true;
            event.preventDefault();
            await activateAutomationRule({ automationRuleId: this.recordId});

            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.closeQuickAction();
            showToastSuccess(this, { message: labels.TOAST_SUCCESS, messageData: [this.automationRuleName] });
        } catch (e) {
            this.errorMessage = e.message || e.body?.message;
            if(this.errorMessage === labels.DUPLICATED_ERROR) {
                this.duplicatedRules = await getDuplicatedAutomationRule({ automationRuleId: this.recordId});
                this.duplicatedRules.forEach((record) => {
                    record.RecordLink = '/' + record.Id;
                });
            }
        } finally {
            this.showSpinner = false;
        }
    }
}