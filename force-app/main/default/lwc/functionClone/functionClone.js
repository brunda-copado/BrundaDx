import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

import { label, fields } from './constants';
import { reduceErrors } from 'c/copadocoreUtils';
import { showToastSuccess } from 'c/copadocoreToastNotification';

import NAME_FIELD from '@salesforce/schema/Function__c.Name';
import cloneFunction from '@salesforce/apex/CloneFunctionHandler.cloneFunction';

export default class FunctionClone extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    error;
    showSpinner = true;
    label = label;
    fields = fields;


    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
    wiredFunction({ data, error }) {
        if (data) {
            this.fields[0].value = `${label.CopyOf} ${getFieldValue(data, NAME_FIELD)}`;
            this.showSpinner = false;
        } else if (error) {
            this.error = {
                title: label.Error,
                message: reduceErrors(error)
            };
        }
    }


    clone() {
        const btn = this.template.querySelector('.submit');
        if (btn) {
            btn.click();
        }
    }


    async handleSubmit(event) {
        try {
            this.showSpinner = true;
            event.preventDefault();
            const fields = event.detail.fields;
            const result = await cloneFunction({ recordId: this.recordId, newFunction: fields });

            showToastSuccess(this, { message: label.Function_was_successfully_cloned });
            this._naviagateToRecord(result);
        } catch (e) {
            this.error = {
                title: label.Error,
                message: `${label.It_was_not_possible_to_clone_this_Function}: ${reduceErrors(e)}`
            };
        } finally {
            this.showSpinner = false;
        }
    }


    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }


    _naviagateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }
}