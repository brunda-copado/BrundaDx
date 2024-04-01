import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';

import getPromotionJob from '@salesforce/apex/PromotionProgressAlertsController.getPromotionJob';
import getDeploymentJob from '@salesforce/apex/PromotionProgressAlertsController.getDeploymentJob';
import getAfterQualityGateJobs from '@salesforce/apex/QualityChecksMonitorCtrl.getAfterQualityGateJobs';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

import { label, schema, messageParams, communicationName, jobStatus } from './constants';

export default class PromotionProgressAlerts extends LightningElement {
    @api recordId;

    _promotionId;
    _interval;

    _promotionJob;
    _deploymentJob;
    _promotionQualityChecks;
    _deploymentQualityChecks;

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
        return communicationName.PROMOTION_ALERTS + this.recordId;
    }

    // PRIVATE

    async _execute() {
        if (!this._promotionId) {
            try {
                const promotionJob = await getPromotionJob({ promotionId: this.recordId });
                if (promotionJob) {
                    this._promotionJob = promotionJob;
                    const promotionJobStatus = this._getJobStatus(promotionJob).toLowerCase();

                    if (promotionJobStatus === jobStatus.SUCCESSFUL.toLowerCase()) {
                        this._getPromotionQualityChecks(promotionJob);
                    } else if (promotionJobStatus === jobStatus.ERROR.toLowerCase()) {
                        this._getDeploymentJob();
                    }
                }
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        }
    }

    async _getDeploymentJob() {
        const deploymentJob = await getDeploymentJob({ promotionId: this.recordId });
        if (deploymentJob) {
            this._deploymentJob = deploymentJob;
            const deploymentJobStatus = this._getJobStatus(deploymentJob).toLowerCase();
            if (deploymentJobStatus === jobStatus.SUCCESSFUL.toLowerCase()) {
                this._getDeploymentQualityChecks(deploymentJob);
            } else if (deploymentJobStatus === jobStatus.ERROR.toLowerCase()) {
                this._showPromotionProgressAlert();
            }
        } else {
            this._showPromotionProgressAlert();
        }
    }

    async _getPromotionQualityChecks(jobExecution) {
        const afterQualityChecks = await getAfterQualityGateJobs({ recordId: this.recordId, jobExecutionId: jobExecution.Id });
        if (afterQualityChecks && afterQualityChecks.jobExecutions.length > 0) {
            this._promotionQualityChecks = afterQualityChecks.jobExecutions;
            this._getDeploymentJob();
        }
    }

    async _getDeploymentQualityChecks(jobExecution) {
        const afterQualityChecks = await getAfterQualityGateJobs({ recordId: this.recordId, jobExecutionId: jobExecution.Id });
        if (afterQualityChecks && afterQualityChecks.jobExecutions.length > 0) {
            this._deploymentQualityChecks = afterQualityChecks.jobExecutions;
            this._showDeploymentProgressAlert();
        }
    }

    _showPromotionProgressAlert() {
        if (this._promotionQualityChecks) {
            const qualityChecksStatus = this._getQualityChecksStatus(this._promotionQualityChecks).toLowerCase();
            const promotionJobStatus = this._getJobStatus(this._promotionJob).toLowerCase();

            if (promotionJobStatus === jobStatus.SUCCESSFUL.toLowerCase() && qualityChecksStatus === jobStatus.ERROR.toLowerCase()) {
                const alert = this._defaultAlert(this.recordId);
                alert.message = label.PROMOTION_PROGRESS_ALERT;
                this._showAlert(alert);
            }
        }
    }

    _showDeploymentProgressAlert() {
        const qualityChecksStatus = this._getQualityChecksStatus(this._deploymentQualityChecks).toLowerCase();
        const deploymentJobStatus = this._getJobStatus(this._deploymentJob).toLowerCase();

        if (deploymentJobStatus === jobStatus.SUCCESSFUL.toLowerCase() && qualityChecksStatus === jobStatus.ERROR.toLowerCase()) {
            const alert = this._defaultAlert(this.recordId);
            alert.message = label.DEPLOYMENT_PROGRESS_ALERT;
            this._showAlert(alert);
        }
    }

    _getQualityChecksStatus(jobExecutions) {
        return jobExecutions.length === 0
            ? jobStatus.NOT_STARTED
            : jobExecutions.some(
                  (jobExecution) => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS_FIELD.fieldApiName] === jobStatus.IN_PROGRESS
              )
            ? jobStatus.IN_PROGRESS
            : jobExecutions.some((jobExecution) => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS_FIELD.fieldApiName] === jobStatus.ERROR)
            ? jobStatus.ERROR
            : jobExecutions.every(
                  (jobExecution) => jobExecution.recordDetail[schema.JOB_EXECUTION_STATUS_FIELD.fieldApiName] === jobStatus.SUCCESSFUL
              )
            ? jobStatus.SUCCESSFUL
            : jobStatus.NOT_STARTED;
    }

    _getJobStatus(jobExecution) {
        return jobExecution[schema.JOB_EXECUTION_STATUS_FIELD.fieldApiName];
    }

    _defaultAlert(alertId) {
        return {
            message: '',
            dismissible: false,
            variant: messageParams.WARNING,
            communicationId: this.communicationId,
            id: alertId,
            operation: messageParams.ADD
        };
    }

    _showAlert(alert) {
        this._promotionId = this.recordId;
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