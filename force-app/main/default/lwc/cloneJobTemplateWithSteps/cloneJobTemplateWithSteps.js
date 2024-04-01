import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

import { fields, labels } from './constants';
import { showToastSuccess } from 'c/copadocoreToastNotification';

import cloneTemplate from '@salesforce/apex/CloneJobTemplateWithSteps.cloneTemplate';

export default class CloneJobTemplateWithSteps extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;

    fields = fields;
    labels = labels;

    showSpinner;
    error;

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
            const result = await cloneTemplate({ templateId: this.recordId, newTemplate: fields });

            showToastSuccess(this, { message: labels.CLONE_JOB_TEMPLATE_SUCCESS });
            this._naviagateToRecord(result);
        } catch (e) {
            this.error = {
                title: labels.ERROR,
                message: e.message || e.body?.message
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