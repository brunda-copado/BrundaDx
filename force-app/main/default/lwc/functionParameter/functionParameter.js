import { api, LightningElement } from 'lwc';

import { uniqueKey } from 'c/copadocoreUtils';

import Delete from '@salesforce/label/c.DELETE';
import Is_Required from '@salesforce/label/c.Is_Required';
import Parameter_Name from '@salesforce/label/c.Parameter_Name';
import Parameter_Name_Placeholder from '@salesforce/label/c.Parameter_Name_Placeholder';
import Parameter_Value from '@salesforce/label/c.Parameter_Value';
import Default_Value from '@salesforce/label/c.Default_Value';
import Parameter_Value_Placeholder from '@salesforce/label/c.Parameter_Value_Placeholder';

export default class FunctionParameter extends LightningElement {
    @api
    parameter = {};

    @api index;
    @api areDetailsVisible;

    label = {
        Delete,
        Is_Required,
        Default_Value,
        Parameter_Name,
        Parameter_Value,
        Parameter_Name_Placeholder,
        Parameter_Value_Placeholder
    };

    get columnClass() {
        return this.isFirst ? 'slds-p-top_x-small slds-p-right_x-small' : 'slds-p-top_small slds-p-right_small slds-p-bottom_x-small';
    }

    get variant() {
        return this.isFirst ? 'label-stacked' : 'label-hidden';
    }

    get checkboxLabel() {
        return this.isFirst ? this.label.Is_Required : '';
    }

    get deleteClass() {
        return this.isFirst ? 'slds-m-top_x-large slds-text-align_right' : 'slds-m-top_small slds-text-align_right';
    }

    get isFirst() {
        return this.index === 0;
    }

    get uniqueKey() {
        return uniqueKey('parameter');
    }

    handleParameterChange(event) {
        const parameter = JSON.parse(JSON.stringify(this.parameter));

        parameter[event.target.name] = event.detail.value || event.detail.checked;
        this.parameter = parameter;
        this.dispatchEvent(
            new CustomEvent('parameterchange', {
                detail: {
                    parameter,
                    index: this.index
                },
                bubbles: true
            })
        );
    }

    handleDeleteParameter(event) {
        this.dispatchEvent(
            new CustomEvent('parameterdelete', {
                detail: {
                    index: this.index
                },
                bubbles: true
            })
        );
    }
}