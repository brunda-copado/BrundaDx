import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/copadocoreUtils';
import { fireEvent } from 'c/copadoCorePubsub';

import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import execute from '@salesforce/apex/RunJobController.execute';
import getNextStep from '@salesforce/apex/RunJobController.getNextStep';

import Cancel from '@salesforce/label/c.Cancel';
import Executing_First from '@salesforce/label/c.Executing_First';
import Job_Execution_Launched from '@salesforce/label/c.Job_Execution_Launched';
import Restart_Execution from '@salesforce/label/c.Restart_Execution';
import Restart_Job_Execution from '@salesforce/label/c.Restart_Job_Execution';
import Restart_Job_Execution_Information from '@salesforce/label/c.Restart_Job_Execution_Information';
import Error_Value from '@salesforce/label/c.Error_Value';

export default class RestartJobExecution extends LightningElement {
    @api recordId;

    @wire(CurrentPageReference) pageRef;

    showSpinner;
    nextStep;
    _messageAlert;

    label = {
        Cancel,
        Executing_First,
        Restart_Execution,
        Restart_Job_Execution
    };

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    set messageAlert(value) {
        this._messageAlert = value;
    }

    get messageAlert() {
        return this._messageAlert;
    }

    async handleConfirm() {
        const recordId = this.recordId;
        this.showSpinner = true;
        try {
            await execute({ "jobId": recordId, "allSteps": true });
            getRecordNotifyChange([{ recordId }]);
            this.showToast('', Job_Execution_Launched, 'success');
            fireEvent(this.pageRef, 'refreshResultMonitor', this);
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.messageAlert = { variant: 'error', message: Error_Value + ' ' + reduceErrors(error) }
        } finally {
            this.showSpinner = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    connectedCallback() {
        this.showSpinner = true;
        this.initNextStep();
        this.showSpinner = false;
    }

    async initNextStep() {
        try {
            if (this.recordId) {
                this.nextStep = await getNextStep({ "jobId": this.recordId, "allSteps": true });
            }

            this.messageAlert = { variant: 'info', message: Restart_Job_Execution_Information }
        } catch (error) {
            this.messageAlert = { variant: 'error', message: Error_Value + ' ' + reduceErrors(error) }
        }
    }

    showToast(title, message, variant = 'error') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}