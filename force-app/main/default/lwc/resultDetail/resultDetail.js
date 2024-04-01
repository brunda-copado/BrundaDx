import { LightningElement, api } from 'lwc';

import TIMEZONE from '@salesforce/i18n/timeZone';

import { images, labels, queueStatus } from './constants';

import getQueuedJobs from '@salesforce/apex/ResultMonitorLWCHandler.getQueuedJobs';
import releaseResource from '@salesforce/apex/ResultMonitorLWCHandler.releaseResource';

import * as utils from 'c/copadocoreUtils';

export default class ResultDetail extends LightningElement {
    @api recordId;
    @api jobStepLabel;
    @api jobStepId;
    @api jobStepObjectApiName; // deprecated, can not be deleted since it is already being used in managed package
    @api jobStepType;
    @api jobStepCustomType;
    @api resultId;
    @api resultObjectApiName; // deprecated, can not be deleted since it is already being used in managed package
    @api resultLabel;
    @api resultValue;
    @api subscribedMessage;
    @api jobExecutionStatus;
    @api queueStatus;
    @api isQueuedStep;

    isLoading = false;
    _resultStatus;

    label = labels;
    images = images;

    @api
    get resultStatus() {
        return this._resultStatus;
    }
    set resultStatus(value) {
        this._resultStatus = value;
        if (value === 'In Progress') {
            this.sendScrollDataEvent();
        }
    }

    _historicalMessages = [];
    @api
    get historicalMessages() {
        return this._historicalMessages;
    }
    set historicalMessages(value) {
        if (value && value.length > 0) {
            this._historicalMessages = utils.cloneData(value).map((item) => {
                item.id = utils.uniqueKey('message');
                item.createdDate = this.formatDate(item.createdDate);
                return item;
            });
        }
    }

    _jobsStarted;
    @api
    get jobsStarted() {
        return this._jobsStarted;
    }
    set jobsStarted(value) {
        this._jobsStarted = value;

        if (this._resultStatus === 'Success' || this._resultStatus === 'Failed' || this._resultStatus === 'Cancelled') {
            this._jobsStarted = true;
        }
    }

    record;
    isCollapsableOpen = false;
    isMenuOpened = false;
    timezoneVariable = TIMEZONE;

    _resultUrl;
    get resultUrl() {
        return `/${this.resultId}`;
    }

    _jobStepUrl;
    get jobStepUrl() {
        return `/${this.jobStepId}`;
    }

    _isTouched = false;

    iconColor = '#025fb2';

    get isStatusInProgress() {
        return this._resultStatus === 'In Progress';
    }

    get isStatusNotStarted() {
        return this._resultStatus === 'Not Started';
    }

    get hasNoResultDetails() {
        return this._resultStatus === 'Skipped' || this._resultStatus === 'Not Started' || (this._resultStatus === 'In Progress' && this.jobStepType === 'Manual');
    }

    get areJobsStarted() {
        return this._jobsStarted && this._resultStatus !== 'In Progress';
    }

    get isManualTaskJobStep() {
        return this.jobStepType === 'Manual';
    }

    get isTestJobStep() {
        return this.jobStepType === 'Test';
    }

    get isNeitherManualNorTest() {
        return !this.isManualTaskJobStep && !this.isTestJobStep;
    }

    get isManualTaskInProgress() {
        return this.isManualTaskJobStep && this.isStatusInProgress;
    }

    get jobClass() {
        const openClass = 'slds-is-open';
        const baseClass = 'slds-timeline__item_expandable';
        let jobClass = baseClass;

        if (this._resultStatus === 'Success') {
            jobClass = `${baseClass} success-class`;
        }
        if (this._resultStatus === 'Failed') {
            jobClass = `${baseClass} failed-class`;
        }
        if (this._resultStatus === 'Skipped') {
            jobClass = `${baseClass} skipped-class`;
        }

        if (this.isCollapsableOpen) {
            jobClass = `${jobClass} ${openClass}`;
        }

        return jobClass;
    }

    get menuClasses() {
        const classes = 'slds-dropdown-trigger slds-dropdown-trigger_click menu';
        return this.isMenuOpened ? `${classes} slds-is-open` : classes;
    }

    get iconClass() {
        const baseClass = 'custom-result-icon';
        return this._resultStatus === 'Skipped' ? `${baseClass} custom-skipped-icon` : baseClass;
    }

    get hasCollapsible() {
        return this.jobStepType !== 'Flow' && this._resultStatus !== 'Not Started' && this._resultStatus !== 'Skipped' && this._historicalMessages && this._historicalMessages.length > 0;
    }

    get hasMenu() {
        const manualTaskCondition = this.isManualTaskJobStep && (this._resultStatus === 'Not Started' || this._resultStatus === 'In Progress');
        return manualTaskCondition && this.jobExecutionStatus !== 'Error';
    }

    get collapsibleClass() {
        return this.isCollapsableOpen ? 'is-open' : '';
    }

    get iconVariant() {
        const variantByStatus = {
            Success: 'success',
            Failed: 'error'
        };

        return variantByStatus[this._resultStatus];
    }

    get iconName() {
        const iconByStatus = {
            Success: 'utility:success',
            Failed: 'utility:error',
            Cancelled: 'utility:ban',
            Skipped: 'utility:omni_channel'
        };

        return iconByStatus[this._resultStatus] || 'utility:clock';
    }


    get iconForTestStep() {
        const iconsByStatus = {
            Success: this.images.TEST_SUCCESS_ICON,
            Failed: this.images.TEST_ERROR_ICON,
            'In Progress': this.images.TEST_IN_PROGRESS_ICON
        };

        return iconsByStatus[this._resultStatus] || this.images.TEST_NOT_STARTED_ICON;
    }


    get resultValueLabel() {
        const labelByStatus = {
            Success: `${this.label.SUCCESS} ${this.label.DETAILS}`,
            Failed: `${this.label.ERROR} ${this.label.DETAILS}`,
            'In Progress': `${this.label.INPROGRESS} ${this.label.DETAILS}`,
            Cancelled: `${this.label.CANCELLATION} ${this.label.DETAILS}`
        }

        return labelByStatus[this._resultStatus];
    }


    get jobStartDate() {
        return this._historicalMessages && this._historicalMessages.length > 0 ? this.formatDate(this._historicalMessages[0].createdDate) : '';
    }


    get columns() {
        return [
            {
                label: '',
                fieldName: '',
                initialWidth: 10,
                hideDefaultActions: true,
                cellAttributes: {
                    iconName: { fieldName: 'icon' },
                    iconPosition: 'left'
                }
            },
            {
                label: this.label.Task,
                fieldName: 'processLink',
                type: 'url',
                typeAttributes: { label: { fieldName: 'processName' }, target: '_blank' }
            },
            {
                label: this.label.STATUS, fieldName: 'status'
            },
            {
                label: this.label.Context,
                fieldName: 'contextLink',
                type: 'url',
                typeAttributes: { label: { fieldName: 'contextName' }, target: '_blank' }
            },
            {
                label: this.label.Owner,
                fieldName: 'ownerLink',
                type: 'url',
                typeAttributes: { label: { fieldName: 'ownerName' }, target: '_blank' }
            }
        ];
    }

    get resourceName() {
        return this.queueStatus?.currentJob?.resourceName;
    }


    get hasQueuedJob() {
        return this.queueStatus?.allQueuedJob?.length > 1;
    }


    get continueQueueWithBlockedJob() {
        return this.hasQueuedJob && this.queueStatus?.allQueuedJob[0]?.status === queueStatus.BLOCKED ? labels.ContinueQueueForFailedJob : '';
    }


    get continueQueueWithInProgressJob() {
        return this.hasQueuedJob && this.queueStatus?.allQueuedJob[0]?.status === queueStatus.IN_PROGRESS ? labels.ContinueQueueForInProgressJob : '';
    }


    get allQueuedJobs() {
        return this.queueStatus?.allQueuedJob ? this.queueStatus.allQueuedJob.map((job) => {
            const linkTag = job.contextLink ? this.htmlToElement(job.contextLink) : {
                textContent: 'NA'
            };
            const contextName = linkTag?.textContent;
            const contextLink = linkTag?.href || job.processLink;

            return {
                ...job,
                contextName,
                contextLink,
                icon: job.id === this.queueStatus.currentJob.id ? 'utility:record' : ''
            }
        }) : [];
    }


    htmlToElement(html) {
        const template = document.createElement('template');
        html = html?.trim();
        template.innerHTML = html;

        return template.content.firstChild;
    }


    _closeMenu() {
        const sldsCombobox = this.template.querySelector('.menu');
        if (sldsCombobox) {
            sldsCombobox.classList.remove('slds-is-open');
            this.isMenuOpened = false;
        }
    }


    handleClick(event) {
        if (event.target.closest('.menu') !== this.template.querySelector('.menu')) {
            this._closeMenu();
        }
    }


    @api showQueueStatus() {
        this.template.querySelector('c-copadocore-modal').show();
    }


    hideQueueStatus() {
        this.template.querySelector('c-copadocore-modal').hide();
    }


    sendScrollDataEvent() {
        const eventData = {
            jobStepId: this.jobStepId
        };

        if (!this._isTouched) {
            this.dispatchEvent(new CustomEvent('newstatus', { detail: eventData }));
        }
    }


    formatDate(value) {
        let date = new Date(value);
        return Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    }


    toggleCollapse() {
        this.isCollapsableOpen = !this.isCollapsableOpen;
        this._isTouched = true;
        this.dispatchEvent(new CustomEvent('userworking', { detail: this._isTouched }));
    }


    handleMenuSelect(event) {
        const selectedItemValue = event.detail.value;

        if (selectedItemValue === this.label.UPDATE_MANUAL_TASK_BUTTON) {
            this.dispatchEvent(new CustomEvent('completemanualtask', { detail: this.jobStepId }));
        }
    }

    async refreshQueueStatus() {
        this.isLoading = true;
        try {
            await getQueuedJobs({ jobStepId: this.jobStepId });
        } catch (error) {
            console.error(error);
        }
        this.isLoading = false;
    }


    async releaseResource() {
        this.isLoading = true;
        try {
            await releaseResource({ jobStepId: this.queueStatus?.allQueuedJob[0].contextId });
            this.hideQueueStatus();
            const nextJob = this.getNextQueuedJob();
            showToastSuccess(this, {
                message: this.label.TaskInProgress,
                messageData: [{
                    url: nextJob?.processLink,
                    label: nextJob?.processName
                }],
                mode: 'sticky'
            });
        } catch (error) {
            console.error(error);
        }
        this.isLoading = false;
    }


    getNextQueuedJob() {
        return this.queueStatus.allQueuedJob.find((job) => job.status === 'Queued');
    }


    refreshManually() {
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    showResultModal() {
        this.dispatchEvent(new CustomEvent('viewdetail', {
            bubbles: true,
            composed: true,
            detail: {
                resultId: this.resultId,
                isConsolidated: this.jobStepType === 'Test'
            }
        }));
    }
}