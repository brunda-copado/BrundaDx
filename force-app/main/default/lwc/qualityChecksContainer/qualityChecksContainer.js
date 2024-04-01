import { LightningElement, api } from 'lwc';
import TIMEZONE from '@salesforce/i18n/timeZone';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import { images, label, schema, statuses } from './constants';

import getAfterQualityGateJobs from '@salesforce/apex/QualityChecksMonitorCtrl.getAfterQualityGateJobs';

export default class QualityChecksContainer extends LightningElement {
    @api recordId;
    @api jobExecutionId;

    jobExecutions = [];
    isCollapsableOpen = false;

    _interval;

    timezoneVariable = TIMEZONE;
    images = images;
    label = label;
    schema = schema;

    get showQualityChecks() {
        return this.jobExecutions.length > 0;
    }

    get iconForQualityChecks() {
        const iconsByStatus = {
            [statuses.SUCCESSFUL]: this.images.TEST_SUCCESS_ICON,
            [statuses.ERROR]: this.images.TEST_ERROR_ICON,
            [statuses.IN_PROGRESS]: this.images.TEST_IN_PROGRESS_ICON
        };

        return iconsByStatus[this.status] || this.images.TEST_NOT_STARTED_ICON;
    }

    get status() {
        return this.jobExecutions.length === 0
            ? statuses.NOT_STARTED
            : this.jobExecutions.some((jobExecution) => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS.fieldApiName] === statuses.IN_PROGRESS)
            ? statuses.IN_PROGRESS
            : this.jobExecutions.some((jobExecution) => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS.fieldApiName] === statuses.ERROR)
            ? statuses.ERROR
            : this.jobExecutions.every((jobExecution) => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS.fieldApiName] === statuses.SUCCESSFUL)
            ? statuses.SUCCESSFUL
            : statuses.NOT_STARTED;
    }

    get isStatusInProgress() {
        return this.status === statuses.IN_PROGRESS;
    }

    get lastModifiedDate() {
        return new Date(
            Math.max(
                ...this.jobExecutions.map((jobExecution) => new Date(jobExecution.recordDetail[schema.JOB_EXECUTION_LAST_MODIFIED_DATE.fieldApiName]))
            )
        );
    }

    get jobClass() {
        const openClass = 'slds-is-open';
        const baseClass = 'slds-timeline__item_expandable';
        let jobClass = baseClass;

        if (this.status === statuses.SUCCESSFUL) {
            jobClass = `${baseClass} success-class`;
        }
        if (this.status === statuses.ERROR) {
            jobClass = `${baseClass} failed-class`;
        }

        if (this.isCollapsableOpen) {
            jobClass = `${jobClass} ${openClass}`;
        }

        return jobClass;
    }

    get collapsibleClass() {
        return this.isCollapsableOpen ? 'is-open' : '';
    }

    async connectedCallback() {
        await this._getLatestData();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._interval = setInterval(async () => {
            await this._getLatestData();
            if (this.status !== statuses.NOT_STARTED && this.status !== statuses.IN_PROGRESS) {
                clearInterval(this._interval);
            }
        }, 5000);
    }

    disconnectedCallback() {
        clearInterval(this._interval);
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

    async refreshManually() {
        try {
            await this._getLatestData();
        } catch (error) {
            console.error(error);
        }
    }

    // PRIVATE

    async _getLatestData() {
        try {
            const data = await getAfterQualityGateJobs({ recordId: this.recordId, jobExecutionId: this.jobExecutionId });
            this.jobExecutions = data.jobExecutions;
            console.log(this.jobExecutions);
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
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