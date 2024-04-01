/* eslint-disable no-undef */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { refreshApex } from '@salesforce/apex';
import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';
import { CurrentPageReference } from 'lightning/navigation';

import getSteps from '@salesforce/apex/CustomJobStepController.getSteps';
import USER_STORY from '@salesforce/schema/User_Story__c';
import RESULT_FIELD from '@salesforce/schema/JobStep__c.Result__c'
import STATUS from '@salesforce/schema/JobExecution__c.Status__c'

import NEW from '@salesforce/label/c.NEW';
import ORDER from '@salesforce/label/c.Order';
import JOB_STEPS from '@salesforce/label/c.Job_Steps';
import DEPLOYMENT_STEPS from '@salesforce/label/c.DEPLOYMENT_STEPS';
import LOADING from '@salesforce/label/c.LOADING';

export default class JobStepsTable extends LightningElement {
    label = {
        NEW,
        ORDER,
        LOADING
    };

    @api parentId;
    @api parentApiName;
    @api columns;
    
    records;
    wiredResponse;
    showOrderSteps = false;
    loading;
    status;
    
    @wire(getRecord, { recordId: '$parentId', fields: [STATUS] })
    jobExecutionRecord;
    
    get title() {
        return this.isParentUserStory ? DEPLOYMENT_STEPS : JOB_STEPS;
    }
    
    get isParentUserStory() {
        return this.parentApiName === USER_STORY.objectApiName;
    }
    
    get stepCount() {
        return this.records?.length;
    }

    get isNotCompleted() {
        this.status = getFieldValue(this.jobExecutionRecord.data, STATUS);
        return this.status !== 'Successful';
    }
    
    connectedCallback() {
        this.loading = true;
        registerListener('refreshResultMonitor', this.refresh, this);
    }
    
    disconnectedCallback() {
        unregisterAllListeners(this);
    }
    
    @wire(CurrentPageReference) pageRef;

    @wire(getSteps, { parentId: '$parentId' })
    wiredSteps(response) {
        this.wiredResponse = response;
        let data = response.data;
        let error = response.error;
        
        if (data) {
            this.records = [];
            
            data.forEach(record => {
                this.records.push({
                    ...record,
                    nameUrl: '/' + record.Id,
                    resultName: this.resultName(record),
                    resultUrl: this.resultUrl(record)
                })
            });

            this.error = undefined;
        } else if (error) {
            this.records = undefined;
            this.error = error;
            console.error("error", error);
        }

        this.loading = false;
    }

    resultName(record) {
        const RESULT_LOOKUP = RESULT_FIELD.fieldApiName.replace('__c', '__r');
        return record[RESULT_FIELD.fieldApiName] ? record[RESULT_LOOKUP].Name : '';
    }

    resultUrl(record) {
        return record[RESULT_FIELD.fieldApiName] ? '/' + record[RESULT_FIELD.fieldApiName] : '';
    }

    @api refresh() {
        this.loading = true;
        refreshApex(this.wiredResponse);
        this.loading = false;
    }

    handleNew() {
        this.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                action: 'edit',
                stepId: undefined
            }
        }));
    }

    handleRowAction(event) {
        this.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                action: event.detail.action.name,
                stepId: event.detail.row.Id
            }
        }));
    }

    handleOrderSteps() {
        this.showOrderSteps = true;
    }

    closeOrderSteps() {
        this.showOrderSteps = false;
        this.refresh();
    }
}