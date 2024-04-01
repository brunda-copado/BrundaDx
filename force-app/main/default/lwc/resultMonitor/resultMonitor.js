import { LightningElement, api, track, wire } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import TIMEZONE from '@salesforce/i18n/timeZone';
import { fireEvent } from 'c/copadoCorePubsub';
import { labels } from './constants';

import result from '@salesforce/apex/ResultMonitorLWCHandler.result';
import resume from '@salesforce/apex/ResultMonitorLWCHandler.resume';

export default class ResultMonitor extends LightningElement {
    @api fieldApiName;
    @api recordId; // Necessary for lightning__FlowScreen
    @api objectApiName;
    @track recordDetail = {};
    @api noJobTitle = labels.Job_Execution_Not_Started;
    @api noJobMessage = labels.Live_Message_Component_Message;
    @wire(CurrentPageReference) pageRef;

    label = labels;
    currentJobStepId;
    isLoading = false;
    jobsStarted = false;
    isJobExecutionEmpty = false;
    timezoneVariable = TIMEZONE;
    showMessageHelp = false;

    _isUserWorking = false;
    _interval;

    get hasJobSteps() {
        return Boolean(this.recordDetail?.resultDetails.length);
    }

    get JobEmptyTitle() {
        if (this.recordDetail.mainTitle && this.recordDetail.jobTemplateId) {
            return `${this.recordDetail.mainTitle} ${labels.isEmpty}`;
        }

        this.isJobExecutionEmpty = true;
        return labels.Nothing_to_execute;
    }

    get jobTemplateLink() {
        return `/${this.recordDetail.jobTemplateId}`;
    }

    get jobExecutionLink() {
        return `/${this.recordDetail.jobExecutionId}`;
    }

    get stopPolling() {
        const expectedStatus = new Set(['Success', 'Failed', 'Cancelled', 'Skipped']);
        let isCompleted = false;
        if (this.recordDetail) {
            isCompleted = this.recordDetail?.resultDetails?.every((resultDetail) => {
                return expectedStatus.has(resultDetail.resultStatus);
            });
        }
        return this.recordDetail?.resultDetails?.length !== 0 && isCompleted;
    }

    get jobLastModifiedDate() {
        return this.recordDetail.lastModifiedDate ? this._formatDate(this.recordDetail.lastModifiedDate) : '';
    }

    get isResourceBlocked() {
        return this.recordDetail?.jobExecutionStatus === 'Error' && this.recordDetail?.queueStatus?.allQueuedJob?.length;
    }

    showManageQueue() {
        const queuedResultDetailComponent = this.template.querySelector(
            `c-result-detail[data-step-id=${this.recordDetail?.queueStatus?.currentJob?.contextId}]`
        );

        if (queuedResultDetailComponent) {
            queuedResultDetailComponent.showQueueStatus();
        }
    }

    async connectedCallback() {
        const FIVE_SECONDS = 5000;

        this.isLoading = true;

        await this._refreshRecordDetail();

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._interval = setInterval(() => {
            this._refreshRecordDetail();
            this.jobsStarted = this._isJobStarted();
            const allQueuedJob = this.recordDetail?.queueStatus?.allQueuedJob || [];
            const isQueueStuck = allQueuedJob.every((job) => job.status === 'Queued');

            if (allQueuedJob.length && isQueueStuck) {
                resume({ jobStepId: this.recordDetail?.queueStatus?.allQueuedJob[0].contextId });
            }

            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            fireEvent(this.pageRef, 'refreshResultMonitor', this);
            if (this.stopPolling) {
                clearInterval(this._interval);
            }
        }, FIVE_SECONDS);

        this.isLoading = false;
    }

    disconnectedCallback() {
        clearInterval(this._interval);
    }

    async refreshManually() {
        this.isLoading = true;

        try {
            await this._refreshRecordDetail();
        } catch (error) {
            console.error(error);
        }

        this.isLoading = false;
    }

    getQueuedStepId() {
        const queuedStep = this.recordDetail.resultDetails.find((resultDetail) => resultDetail.resultStatus === 'Not Started');

        return queuedStep?.jobStepId;
    }

    openManualTaskModal(data) {
        this.currentJobStepId = data.detail;
        this.template.querySelector('c-copadocore-modal').show();
    }

    hideModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    saveManualTaskStatus() {
        this.template.querySelector('c-complete-manual-task').saveManualTaskFromCustomModal();
    }

    setUserWorking(event) {
        this._isUserWorking = event.detail;
    }

    scrollToCurrentStep(event) {
        const jobStepId = event.detail.jobStepId;
        const offset = 5;

        if (!this._isUserWorking) {
            const stepContainer = this.template.querySelector(`[id^="timelineList"]`);
            const steps = Array.prototype.slice.call(stepContainer.children);
            const currentStep = steps.find((step) => step.jobStepId === jobStepId);
            const scrollPosition = currentStep ? currentStep.offsetTop - offset : 0;

            stepContainer.scrollTop = scrollPosition;
        }
    }

    navigateToJobExecution() {
        window.open(this.jobExecutionLink, '_self');
    }

    async _refreshRecordDetail() {
        try {
            this.recordDetail = await result({
                recId: this.recordId,
                objectApiName: this.objectApiName,
                fieldApiName: this.fieldApiName
            });

            if (this.recordDetail.jobExecutionStatus === 'Successful') {
                this.recordDetail.message = labels.Completed;
                this.recordDetail.iconName = 'utility:success';
                this.recordDetail.iconVariant = 'success';
                this.recordDetail.isUnfinished = false;
                this.showMessageHelp = false;
            } else if (this.recordDetail.jobExecutionStatus === 'Error') {
                this.recordDetail.message = this._trimErrorMessage(this.recordDetail.jobExecutionErrorMessage) || labels.Error_Message;
                this.recordDetail.iconName = 'utility:error';
                this.recordDetail.iconVariant = 'error';
                this.recordDetail.isUnfinished = false;
            } else if (this.recordDetail.jobExecutionStatus === 'Canceled') {
                this.recordDetail.message = this._trimErrorMessage(this.recordDetail.jobExecutionErrorMessage) || labels.Error_Message;
                this.recordDetail.iconName = 'utility:ban';
                this.recordDetail.isUnfinished = false;
            } else {
                this.recordDetail.isUnfinished = true;
                this.showMessageHelp = false;
            }

            // if first step is manual, we consider jobs are already started
            if (this.recordDetail?.resultDetails.length && this.recordDetail.resultDetails[0].jobStepType === 'Manual') {
                this.jobsStarted = true;
            }
        } catch (error) {
            console.error(error);
        }
    }

    _trimErrorMessage(message) {
        if (message && message.length > 200) {
            this.showMessageHelp = true;
            return message.substring(0, 199) + '... '; // NOTE : Error messages with more than 200 characters need to be trimmed
        }
        return message;
    }

    _isJobStarted() {
        const expectedStatus = new Set(['Success', 'Failed', 'Cancelled', 'Skipped']);
        let isStarted = false;
        if (this.recordDetail) {
            isStarted = this.recordDetail?.resultDetails?.some((resultDetail) => {
                return expectedStatus.has(resultDetail.resultStatus);
            });
        }
        return this.recordDetail?.resultDetails?.length && isStarted;
    }

    _formatDate(value) {
        let date = new Date(value);
        return Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    }
}