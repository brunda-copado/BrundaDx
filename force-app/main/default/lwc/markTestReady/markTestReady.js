import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';

import READY_TO_RUN from '@salesforce/schema/Test__c.ReadyToRun__c';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

import SUCCESSFULLY_READY from '@salesforce/label/c.TestSuccessfullyReadyToRun';

export default class MarkTestReady extends LightningElement {
    @api recordId;

    _isExecuting = false;

    @api
    async invoke() {
        if (!this._isExecuting) {
            this._isExecuting = true;
            try {
                const fields = {};
                fields.Id = this.recordId;
                fields[READY_TO_RUN.fieldApiName] = true;

                await updateRecord({fields});
                
                showToastSuccess(this, { message: SUCCESSFULLY_READY });
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
            this._isExecuting = false;
        }
    }
}