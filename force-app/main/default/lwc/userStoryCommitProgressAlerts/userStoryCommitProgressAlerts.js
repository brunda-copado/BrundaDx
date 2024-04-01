import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';

import getJobExecution from '@salesforce/apex/UserStoryCommitProgressAlertsCtrl.getJobExecution';
import getLastPromotion from '@salesforce/apex/UserStoryCommitProgressAlertsCtrl.getLastPromotion';
import getAfterQualityGateJobs from '@salesforce/apex/QualityChecksMonitorCtrl.getAfterQualityGateJobs';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import { showToastError } from 'c/copadocoreToastNotification';
import { formatLabel, reduceErrors } from 'c/copadocoreUtils';

import { label, schema, messageParams, commitStatus, communicationName, jobStatus } from './constants';

export default class UserStoryCommitProgressAlerts extends LightningElement {
    @api recordId;

    _commitId;
    _promotionId;
    _interval;
    _previousStatus;
    _previousQualityStatus;

    @wire(MessageContext)
    _context;

    // TEMPLATE

    connectedCallback() {
        this._execute();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._interval = setInterval(() => {
            this._execute();
        }, 30000);
    }

    disconnectedCallback() {
        clearInterval(this._interval);
        this._interval = null;
    }

    get communicationId() {
        return communicationName.USER_STORY_COMMIT + this.recordId;
    }

    // PRIVATE

    async _execute() {
        try {
            const promotedUserStories = await getLastPromotion({ recordId: this.recordId });
            if (promotedUserStories && promotedUserStories.length > 0) {
                const promotedUserStory = promotedUserStories[0];
                const promotionStatus = this._getPromotionStatus(promotedUserStory).toLowerCase();
                if (this._promotionId) {
                    this._clearAlert(this._promotionId);
                }

                if (promotionStatus === commitStatus.IN_PROGRESS.toLowerCase()) {
                    this._promotionId = this._getPromotionId(promotedUserStory);
                    const alert = this._defaultAlert(this._promotionId);

                    alert.message = formatLabel(label.PROMOTION_IN_PROGRESS_ALERT, ['/' + this._promotionId]);
                    alert.dismissible = false;
                    alert.variant = messageParams.WARNING;

                    if (alert.message) {
                        this._showAlert(alert);
                    }
                } else {
                    this._handleCommitJobExecution();
                }
            } else {
                this._handleCommitJobExecution();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async _handleCommitJobExecution() {
        const jobExecutions = await getJobExecution({ recordId: this.recordId });
        if (jobExecutions && jobExecutions.length > 0) {
            const lastJobExecution = jobExecutions[0];
            await this._handleJobExecution(lastJobExecution);
        }
    }

    async _handleJobExecution(jobExecution) {
        const lastCommitId = this._getUserStoryCommitId(jobExecution);
        if (this._commitId && this._commitId !== lastCommitId) {
            this._clearAlert(this._commitId);
        }
        this._commitId = lastCommitId;
        const afterQualityChecks = await getAfterQualityGateJobs({ recordId: this._commitId, jobExecutionId: jobExecution.Id });
        const qualityChecksStatus = this._handleQualityChecksStatus(afterQualityChecks.jobExecutions);
        const returnedCommitStatus = this._getUserStoryCommitStatus(jobExecution);
        this._handleCommitStatus(returnedCommitStatus, qualityChecksStatus);
    }

    _handleQualityChecksStatus(jobExecutions) {
        return jobExecutions.length === 0
            ? jobStatus.NOT_STARTED
            : jobExecutions.some(jobExecution => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS_FIELD.fieldApiName] === jobStatus.IN_PROGRESS)
            ? jobStatus.IN_PROGRESS
            : jobExecutions.some(jobExecution => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS_FIELD.fieldApiName] === jobStatus.ERROR)
            ? jobStatus.ERROR
            : jobExecutions.every(jobExecution => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS_FIELD.fieldApiName] === jobStatus.SUCCESSFUL)
            ? jobStatus.SUCCESSFUL
            : jobStatus.NOT_STARTED;
    }

    _handleCommitStatus(status, qualityChecksStatus) {
        if (this._previousStatus !== status && this._previousQualityStatus !== qualityChecksStatus) {
            const alert = this._defaultAlert(this._commitId);

            switch (status) {
                case commitStatus.IN_PROGRESS:
                case commitStatus.PENDING:
                    alert.message = formatLabel(label.USER_STORY_COMMIT_IN_PROGRESS_ALERT, ['/' + this._commitId]);
                    alert.dismissible = false;
                    alert.variant = messageParams.INFO;
                    break;
                case commitStatus.NO_CHANGES:
                    alert.message =
                        qualityChecksStatus === jobStatus.ERROR
                            ? label.COMMIT_NO_CHANGES_FAILED_QUALITY_CHECKS
                            : label.USER_STORY_COMMIT_NO_CHANGES_ALERT;
                    alert.dismissible = false;
                    alert.variant = messageParams.WARNING;
                    break;
                case commitStatus.COMPLETE:
                    alert.message =
                        qualityChecksStatus === jobStatus.ERROR
                            ? formatLabel(label.USER_STORY_COMMIT_SUCCESS_ALERT_FAILED_QUALITY_CHECKS, ['/' + this._commitId])
                            : formatLabel(label.USER_STORY_COMMIT_SUCCESS_ALERT, ['/' + this._commitId]);
                    alert.variant = qualityChecksStatus === jobStatus.ERROR ? messageParams.WARNING : messageParams.SUCCESS;
                    break;
                case commitStatus.FAILED:
                    alert.message = formatLabel(label.USER_STORY_COMMIT_FAILED_ALERT, ['/' + this._commitId]);
                    alert.variant = messageParams.ERROR;
                    break;
                default:
                    break;
            }
            if (alert.message) {
                this._clearAlert(this._commitId);
                this._showAlert(alert);
            }
        }
        this._previousStatus = status;
        this._previousQualityStatus = qualityChecksStatus;
    }

    _getUserStoryCommitId(jobExecution) {
        return jobExecution[schema.JOB_EXECUTION_USER_STORY_COMMIT_FIELD.fieldApiName];
    }

    _getUserStoryCommitStatus(jobExecution) {
        return jobExecution[schema.JOB_EXECUTION_USER_STORY_COMMIT_FIELD.fieldApiName.replace('__c', '__r')][
            schema.USER_STORY_COMMIT_STATUS_FIELD.fieldApiName
        ];
    }

    _getPromotionId(promotedUserStory) {
        return promotedUserStory[schema.PROMOTED_USER_STORY_PROMOTION_FIELD.fieldApiName];
    }

    _getPromotionStatus(promotedUserStory) {
        return promotedUserStory[schema.PROMOTED_USER_STORY_PROMOTION_FIELD.fieldApiName.replace('__c', '__r')][
            schema.PROMOTION_STATUS_FIELD.fieldApiName
        ];
    }

    _defaultAlert(alertId) {
        return {
            message: '',
            dismissible: true,
            variant: '',
            communicationId: this.communicationId,
            id: alertId,
            operation: messageParams.ADD
        };
    }

    _showAlert(alert) {
        publish(this._context, COPADO_ALERT_CHANNEL, alert);
    }

    _clearAlert(alertId) {
        const alert = {
            communicationId: this.communicationId,
            id: alertId,
            operation: messageParams.REMOVE
        };
        publish(this._context, COPADO_ALERT_CHANNEL, alert);
    }
}