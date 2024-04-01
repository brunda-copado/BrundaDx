import { LightningElement, api, track } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import STATUS from '@salesforce/schema/Result__c.Status__c';
import FUNCTION from '@salesforce/schema/Result__c.Function__c';
import PROGRESS_STATUS from '@salesforce/schema/Result__c.Progress_Status__c';

import result from '@salesforce/apex/ResultMonitor.result';
import getHistoryData from '@salesforce/apex/ResultMonitor.getHistoryData';

import LOADING from '@salesforce/label/c.LOADING';
import VIEWRESULT from '@salesforce/label/c.VIEWRESULT';
import PROGRESS from '@salesforce/label/c.Progress_Status';
import STOP_EXECUTION from '@salesforce/label/c.Stop_Execution';
import NO_RECORD_FOUND from '@salesforce/label/c.Result_not_Found';
import NO_FIELD_HISTORY from '@salesforce/label/c.No_Field_History';

export default class ResultStatusMonitor extends LightningElement {
    label = {
        PROGRESS,
        LOADING,
        VIEWRESULT,
        STOP_EXECUTION,
        NO_RECORD_FOUND,
        NO_FIELD_HISTORY
    };

    @api recordId;
    @api showDetailLink;

    // Deprecated API properties that are not in use
    @api headerText;
    @api headerTextRecordId;
    @api headerTextObjectApiName;
    @api enableHeaderAsLink;
    @api objectApiName;
    @api contextId;
    @api contextName;
    @api contextObjectApiName;
    @api contextLabel;


    @track historicalMessages;
    @track showSpinner = true;

    record = {};
    _interval;
    _hideStopExecution;

    async getRecord() {
        try {
            this.record = await result({ id: this.recordId });
        } catch (error) {
            this.error = error;
        }
    }

    async connectedCallback() {
        this.getRecord();

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._interval = setInterval(async () => {
            this.getRecord();
            this.historicalMessages = await getHistoryData({id : this.recordId});
            getRecordNotifyChange([{ recordId: this.recordId }]);

            if (this.historicalMessages.length) {
                this.historicalMessages = this.historicalMessages.map((item) => {
                    item.createdDate = this.formatDate(item.createdDate);
                    return item;
                });
            }

            this.showSpinner = false;

            if (!this.inProgress) {
                clearInterval(this._interval);
            }
        }, 5000);
    }

    disconnectedCallback() {
        clearInterval(this._interval);
    }

    navigateToResult() {
        window.open(`/${this.recordId}`, "_self");
    }

    stopExecution() {
        this.template.querySelector('c-result-stop-execution').showModal(this.recordId);
    }

    hideStopExecution() {
        this._hideStopExecution = true;
    }

    formatDate(value) {
        let date = new Date(value);
        return Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    }

    get allowStopExecution() {
        return (this.record && this.inProgress && this.isNotStarting && this.isFunction && !this._hideStopExecution);
    }

    get message() {
        return (this.inProgress ? this.record[PROGRESS_STATUS.fieldApiName] || this.status || 'Not Started' : this.status);
    }

    get status() {
        return this.record[STATUS.fieldApiName];
    }

    get inProgress() {
        return (this.status === 'In Progress' || this.status === 'Not Started');
    }

    get hasHistoricalMessage() {
        return this.historicalMessages?.length;
    }

    get noHistoryRecord() {
        return (!this.historicalMessages?.length && !this.showSpinner);
    }

    get isFunction() {
        return this.record[FUNCTION.fieldApiName] != null;
    }

    get isNotStarting() {
        return this.record[PROGRESS_STATUS.fieldApiName] !== 'Starting';
    }
}