import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { reduceErrors } from 'c/copadocoreUtils';
import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';

import getSteps from '@salesforce/apex/OrderStepsController.getSteps';
import saveSteps from '@salesforce/apex/OrderStepsController.saveSteps';

import NAME_FIELD from '@salesforce/schema/JobStep__c.Name';
import CUSTOM_TYPE_FIELD from '@salesforce/schema/JobStep__c.CustomType__c';
import ORDER_FIELD from '@salesforce/schema/JobStep__c.Order__c';
import EXECUTION_SEQUENCE_FIELD from '@salesforce/schema/JobStep__c.ExecutionSequence__c';

import NAME from '@salesforce/label/c.NAME';
import TYPE from '@salesforce/label/c.TYPE';
import Save from '@salesforce/label/c.Save';
import Cancel from '@salesforce/label/c.Cancel';
import Job_Steps from '@salesforce/label/c.Job_Steps';
import Job_Steps_Saved from '@salesforce/label/c.Job_Steps_Saved';
import Order_Job_Steps from '@salesforce/label/c.Order_Job_Steps';
import Before_Deployment from '@salesforce/label/c.Before_Deployment';
import After_Deployment from '@salesforce/label/c.After_Deployment';
import Order_Job_Steps_Information from '@salesforce/label/c.Order_Job_Steps_Information';
import LOADING from '@salesforce/label/c.LOADING';
import Drag_Drop_Order from '@salesforce/label/c.Drag_Drop_Order';
import Error_Value from '@salesforce/label/c.Error_Value';

export default class OrderSteps extends LightningElement {
    label = {
        Save,
        Cancel,
        Job_Steps,
        Order_Job_Steps,
        After_Deployment,
        LOADING
    };

    columns = [
        {
            hideDefaultActions: true,
            fixedWidth: 62,
            cellAttributes: { iconName: 'utility:drag_and_drop', iconAlternativeText: Drag_Drop_Order }
        },
        { label: NAME, fieldName: NAME_FIELD.fieldApiName, hideDefaultActions: true },
        { label: TYPE, fieldName: CUSTOM_TYPE_FIELD.fieldApiName, hideDefaultActions: true }
    ];

    @api applySequence;
    @api sequence;
    @api parentId;

    beforeSteps = [];
    afterSteps = [];
    messageAlert;
    loading = false;

    get beforeStepTitle() {
        return this.applySequence ? Before_Deployment : Job_Steps;
    }

    get beforeStepCount() {
        return this.beforeSteps.length;
    }

    get afterStepCount() {
        return this.afterSteps.length;
    }

    connectedCallback() {
        this.initSteps();
        registerListener('dropRowEvent', this.handleDragAndDrop, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    @wire(CurrentPageReference) pageRef;

    async initSteps() {
        this.loading = true;

        try {
            if (this.parentId) {
                const data = await getSteps({ "parentId": this.parentId });

                if (data) {
                    let beforeData = [];
                    let afterData = [];

                    data.forEach(step => {
                        if (this.applySequence && step[EXECUTION_SEQUENCE_FIELD.fieldApiName] === "after") {
                            afterData.push(step);
                        } else {
                            beforeData.push(step);
                        }
                    });

                    this.beforeSteps = beforeData;
                    this.afterSteps = afterData;
                }
            }

            this.messageAlert = { variant: 'info', message: Order_Job_Steps_Information };
        } catch (error) {
            this.messageAlert = { variant: 'error', message: Error_Value + ' ' + reduceErrors(error) };
        }

        this.loading = false;
    }

    async handleSave() {
        this.loading = true;

        try {
            await saveSteps({ "records": this.jobSteps() });
            getRecordNotifyChange(this.stepIds());

            this.showToast('', Job_Steps_Saved, 'success');
            this.dispatchEvent(new CustomEvent('closeordermodal'));
        } catch (error) {
            this.messageAlert = { variant: 'error', message: Error_Value + ' ' + reduceErrors(error) };
        }

        this.loading = false;
    }

    jobSteps() {
        let result = [];

        this.beforeSteps.forEach(step => {
            result.push(step);
        });

        this.afterSteps.forEach(step => {
            result.push(step);
        });

        return result;
    }

    stepIds() {
        let result = [];

        this.beforeSteps.forEach(step => {
            result.push({ recordId: step.Id });
        });

        this.afterSteps.forEach(step => {
            result.push({ recordId: step.Id });
        });

        return result;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('closeordermodal'));
    }

    handleDragAndDrop(event) {
        try {
            const oldIndex = event.draggingBeginsAt;
            const newIndex = event.draggingEndsAt;
            const source = event.sourceName;
            const data = source === "before-steps" ? [...this.beforeSteps] : [...this.afterSteps];

            let i;
            const targetRow = this.row(source, oldIndex);

            if (oldIndex < newIndex) {
                for (i = oldIndex; i < newIndex; i++) {
                    data[i] = this.swappedRow(this.row(source, i + 1), i);
                }
            } else {
                for (i = oldIndex; i > newIndex; i--) {
                    data[i] = this.swappedRow(this.row(source, i - 1), i);
                }
            }

            data[newIndex] = this.swappedRow(targetRow, newIndex);

            if (source === "before-steps") {
                this.beforeSteps = data;
            } else {
                this.afterSteps = data;
            }
        } catch (error) {
            this.messageAlert = { variant: 'error', message: Error_Value + ' ' + reduceErrors(error) };
        }
    }

    row(source, index) {
        return source === "before-steps" ? this.beforeSteps[index] : this.afterSteps[index];
    }

    swappedRow(row, index) {
        return Object.assign(JSON.parse(JSON.stringify(row)), { [ORDER_FIELD.fieldApiName]: (index + 1) });
    }

    showToast(title, message, variant = 'error') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}