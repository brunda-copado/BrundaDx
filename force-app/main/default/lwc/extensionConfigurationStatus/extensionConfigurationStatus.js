import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import ACTIVE from "@salesforce/schema/ExtensionConfiguration__c.Active__c";

import extensionConfigurationStatusTitle from '@salesforce/label/c.EXTENSION_CONFIGURATION_STATUS';


export default class ExtensionConfigurationStatus extends LightningElement {

    label = {
        extensionConfigurationStatusTitle
    };

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [ACTIVE]
    })
    extension;

    @api recordId;

    toggleTooltip() {
        this.template.querySelectorAll('.slds-popover').forEach(tooltip => tooltip.classList.toggle('slds-hide'));
    }

    get active() {
        return getFieldValue(this.extension.data, ACTIVE);
    }

    get message(){
        const messageByActive= {
            true: 'Active',
            false: 'Inactive'
        };
        return messageByActive[this.active];
    }

    get icon() {
        return {
            name: this.iconName,
            variant: this.iconVariant
        };
    }

    get iconName() {
        const iconByActive = {
            true: 'utility:success',
            false: 'utility:clear'
        };
        return iconByActive[this.active];
    }

    get iconVariant() {
        const variantByActive = {
            true: 'success',
            false: 'error'
        };

        return variantByActive[this.active];
    }
}