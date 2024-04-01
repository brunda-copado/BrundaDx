import { LightningElement, api } from 'lwc';
import TIMEZONE from '@salesforce/i18n/timeZone';

import { namespace } from 'c/copadocoreUtils';
import { images, label, schema } from './constants';

export default class QualityCheckExecutionDetail extends LightningElement {
    @api jobExecution;
    @api historicalMessages;

    isCollapsableOpen = false;

    timezoneVariable = TIMEZONE;

    images = images;
    schema = schema;
    label = label;

    get jobExecutionUrl() {
        return `/${this.jobExecution.Id}`;
    }

    get jobExecutionLabel() {
        return this.jobExecution[schema.JOB_EXECUTION_JOB_TEMPLATE.fieldApiName.replace('__c', '__r')][schema.JOB_TEMPLATE_NAME.fieldApiName];
    }

    get jobExecutionStatus() {
        return this.jobExecution[schema.JOB_EXECUTION_STATUS.fieldApiName];
    }

    get jobStartDate() {
        return this.jobExecution[schema.JOB_EXECUTION_CREATED_DATE.fieldApiName];
    }

    get resultId() {
        return this._findLastStepWithResult()[schema.JOB_STEP_RESULT.fieldApiName];
    }

    get resultStatus() {
        return this._findLastStepWithResult()[schema.JOB_STEP_STATUS.fieldApiName];
    }

    get isStatusInProgress() {
        return this.jobExecutionStatus === 'In Progress';
    }

    get hasResult() {
        return !!this.resultId;
    }

    get jobClass() {
        const openClass = 'slds-is-open';
        const baseClass = 'slds-timeline__item_expandable';
        let jobClass = baseClass;

        if (this.jobExecutionStatus === 'Successful') {
            jobClass = `${baseClass} success-class`;
        }
        if (this.jobExecutionStatus === 'Error') {
            jobClass = `${baseClass} failed-class`;
        }
        if (this.jobExecutionStatus === 'Skipped') {
            jobClass = `${baseClass} skipped-class`;
        }

        if (this.isCollapsableOpen) {
            jobClass = `${jobClass} ${openClass}`;
        }

        return jobClass;
    }

    get collapsibleClass() {
        return this.isCollapsableOpen ? 'is-open' : '';
    }

    get iconForJobExecution() {
        const iconsByStatus = {
            Successful: this.images.TEST_SUCCESS_ICON,
            Error: this.images.TEST_ERROR_ICON,
            'In Progress': this.images.TEST_IN_PROGRESS_ICON
        };

        return iconsByStatus[this.jobExecutionStatus] || this.images.TEST_NOT_STARTED_ICON;
    }

    get resultLabel() {
        const labelByStatus = {
            Success: `${this.label.SUCCESS} ${this.label.DETAILS}`,
            Failed: `${this.label.ERROR} ${this.label.DETAILS}`,
            'In Progress': `${this.label.INPROGRESS} ${this.label.DETAILS}`,
            Cancelled: `${this.label.CANCELLATION} ${this.label.DETAILS}`
        };

        return labelByStatus[this.resultStatus] || this.label.PENDING;
    }

    showResultModal() {
        this.dispatchEvent(
            new CustomEvent('viewdetail', {
                bubbles: true,
                composed: true,
                detail: {
                    resultId: this.resultId,
                    isConsolidated: false
                }
            })
        );
    }

    handleClickCollapse(event) {
        if (event.target.closest('.menu') !== this.template.querySelector('.menu')) {
            this._closeMenu();
        }
    }

    toggleCollapse() {
        this.isCollapsableOpen = !this.isCollapsableOpen;
        this._isTouched = true;
        this.dispatchEvent(new CustomEvent('userworking', { detail: this._isTouched }));
    }

    refreshManually() {
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    // PRIVATE

    _findLastStepWithResult() {
        return this.jobExecution[namespace + 'JobSteps__r'].findLast(
            step => step[schema.JOB_STEP_RESULT.fieldApiName] !== null && step[schema.JOB_STEP_RESULT.fieldApiName] !== undefined
        );
    }

    _formatDate(value) {
        const date = new Date(value);
        return Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    }

    _closeMenu() {
        const sldsCombobox = this.template.querySelector('.menu');
        if (sldsCombobox) {
            sldsCombobox.classList.remove('slds-is-open');
            this.isMenuOpened = false;
        }
    }
}