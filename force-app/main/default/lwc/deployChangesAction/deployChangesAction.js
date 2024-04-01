import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { reduceErrors, namespace } from 'c/copadocoreUtils';

import { CloseActionScreenEvent } from 'lightning/actions';
import { publish, MessageContext } from 'lightning/messageService';

import { label } from './constants';
import result from '@salesforce/apex/ResultMonitorLWCHandler.result';

import execute from '@salesforce/apex/RunDeployJobTemplateHandler.execute';
import validate from '@salesforce/apex/RunDeployJobTemplateHandler.validate';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import DESTINATION_ENVIRONMENT from '@salesforce/schema/Promotion__c.Destination_Environment__r.Name';

import LAST_DEPLOYMENT_EXECUTION_ID_FIELD from '@salesforce/schema/Promotion__c.Last_Deployment_Execution_Id__c';

const fields = [DESTINATION_ENVIRONMENT];

export default class DeployChangesAction extends LightningElement {
    @api get recordId() {
        return this._recordId;
    }
    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }
    _recordId;
    @api objectApiName;

    label = label;

    communicationId = 'promotionRecordPageAlerts';
    modalCommunicationId = 'modalAlerts';
    showSpinner = true;
    modalBodyMessage = '';
    showActionButtons = false;
    cancelButtonLabel = label.Cancel;
    stepChannelName = `/event/${namespace}Event__e`;

    @wire(getRecord, { recordId: '$recordId', fields })
    promotion;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this._recordId = currentPageReference.state.recordId;
            this._validatePromotion();
        }
    }

    @wire(MessageContext)
    messageContext;

    get headerText() {
        return label.Deploy_changes_to_Environment + ' ' + (this.destinationEnvironment ? "'" + this.destinationEnvironment + "'" : '');
    }

    get destinationEnvironment() {
        return this.promotion ? getFieldValue(this.promotion.data, DESTINATION_ENVIRONMENT) : '';
    }

    closeModal() {
        this.template.querySelector('c-platform-event-subscriber').unsubscribe();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async deploy() {
        try {
            this.showSpinner = true;
            await this.template.querySelector('c-platform-event-subscriber').subscribe();
            const recordId = this.recordId;
            const doNotRunJob = false;
            const deploymentSteps = this.template.querySelector('c-order-deployment-steps').getDeploymentStepIds();
            await execute({ recordId, doNotRunJob, deploymentSteps });
        } catch (error) {
            this._messageAlert(label.Error_while_processing_the_Deploy_Changes + ' ' + reduceErrors(error), 'error', true, this.communicationId);
            this.showSpinner = false;
            this.closeModal();
        }
    }

    async createJobExecutionOnly() {
        try {
            this.showSpinner = true;
            const recordId = this.recordId;
            const doNotRunJob = true;
            const deploymentSteps = this.template.querySelector('c-order-deployment-steps').getDeploymentStepIds();
            await execute({ recordId, doNotRunJob, deploymentSteps });
            this.showSpinner = false;
            this._closeModalAndRefresh();
        } catch (error) {
            this._messageAlert(label.Error_while_creating_the_Job_Execution + ' ' + reduceErrors(error), 'error', true, this.communicationId);
            this.showSpinner = false;
            this.closeModal();
        }
    }

    async handleEvent(event) {
        const recordDetail = await result({
            recId: this.recordId,
            objectApiName: this.objectApiName,
            fieldApiName: LAST_DEPLOYMENT_EXECUTION_ID_FIELD.fieldApiName
        });

        if (this._isRelevant(event, recordDetail)) {
            this._closeModalAndRefresh();
        }
    }

    _isRelevant(event, recordDetail) {
        const parsedMessage = event.detail.response;
        const fieldName = namespace + 'Topic_Uri__c';
        const topicUri = parsedMessage.data.payload[fieldName];

        return (
            recordDetail.jobExecutionStatus === 'Queued' ||
            recordDetail.resultDetails.some(element => {
                return topicUri.includes('step-monitor') && (topicUri.includes(element.jobStepId) || topicUri.includes(element.resultId));
            })
        );
    }

    async _validatePromotion() {
        const recordId = this.recordId;
        const validationResponse = await validate({ recordId });

        if (validationResponse.promotedUserStoriesCreated) {
            if (validationResponse.jobInProgress) {
                this._showError(label.There_is_a_job_execution_in_progress_for_this_Promotion, label.Wait_until_job_execution_finished);
            } else if (!validationResponse.promotionJobCompleted && validationResponse.hasMetadata) {
                this._showError(label.Unable_to + ' ' + this.headerText, label.Merge_change_is_not_done);
            } else if (!validationResponse.removalsConsidered) {
                this._showError(label.Unable_to + ' ' + this.headerText, label.Promotion_Removals_Were_Not_Merged);
            } else if (validationResponse.promotionIsCancelled) {
                this._showError(label.Unable_to + ' ' + this.headerText, label.Cancelled_Promotions);
            } else {
                this._messageAlert(label.Deploy_Changes_Body, 'info', false, this.modalCommunicationId);
                this.modalBodyMessage = label.Deploy_Changes_Body_2;
                this.showActionButtons = true;
            }
        } else {
            this._showError(label.There_are_not_User_Stories_in_this_Promotion, label.Please_add_at_least_one_user_story_to_your_promotion);
        }

        this.showSpinner = false;
    }

    _showError(alert, message) {
        this._messageAlert(alert, 'error', false, this.modalCommunicationId);
        this.modalBodyMessage = message;
        this.cancelButtonLabel = label.Close;
        this.showActionButtons = false;
    }

    _messageAlert(message, variant, dismissible, communicationId) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    _closeModalAndRefresh() {
        this.closeModal();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            window.location.reload();
        }, 1000);
    }
}