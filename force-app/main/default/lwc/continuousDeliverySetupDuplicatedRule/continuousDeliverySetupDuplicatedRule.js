import { LightningElement, api, wire } from 'lwc';
import { label, schema } from './constants';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getDuplicatedAutomationRule from '@salesforce/apex/ContinuousDeliverySetupController.getDuplicatedAutomationRule';

export default class ContinuousDeliverySetupDuplicatedRule extends LightningElement {
    @api recordId;
    @api configuration;
    @api pipelineStages;

    duplicatedRules;
    duplicatedRulesColumns;
    isRendered = false;
    label = label;

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

    async renderedCallback() {
        if(!this.isRendered) {
            this.duplicatedRules = await getDuplicatedAutomationRule({ pipelineId: this.recordId, automationConfig: JSON.stringify(this.configuration) });
            if(this.duplicatedRules.length === 0) {
                this.handleNext();
            }
            this.duplicatedRules.forEach((record) => {
                record.RecordLink = '/' + record.Id;
            });
            this.isRendered = true;
            this.spinner('stopspinner');
        }
    }

    handleNext() {
        const cancel = new CustomEvent('getnextstep', {
            detail: true
        });

        this.dispatchEvent(cancel);
    }

    handlePrev() {
        const stageIds = this.configuration.backpromotionSettings ? this.configuration.backpromotionSettings.uptoStage : '';
        this.selectedStage = stageIds ? this.pipelineStages.find(element => element.label === stageIds[stageIds.length - 1]).value : '';

        const previous = new CustomEvent('getprevstep', {
            detail: {
                selectedStage: this.selectedStage
            }
        });

        this.dispatchEvent(previous);
    }

    handleCancel() {
        const cancel = new CustomEvent('closemodal', {
            detail: true
        });

        this.dispatchEvent(cancel);
    }

    spinner(event) {
        const spinner = new CustomEvent(event, {
            detail: true
        });

        this.dispatchEvent(spinner);
    }
}