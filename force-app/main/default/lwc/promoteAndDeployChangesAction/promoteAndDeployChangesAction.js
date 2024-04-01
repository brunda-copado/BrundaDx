import { LightningElement, api, wire } from 'lwc';
import { reduceErrors, namespace } from 'c/copadocoreUtils';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { publish, MessageContext } from 'lightning/messageService';

import { label } from './constants';
import result from '@salesforce/apex/ResultMonitorLWCHandler.result';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import execute from '@salesforce/apex/RunPromoteAndDeployJobTemplateHandler.execute';
import validate from '@salesforce/apex/RunPromoteAndDeployJobTemplateHandler.validate';

import DESTINATION_ENVIRONMENT from '@salesforce/schema/Promotion__c.Destination_Environment__r.Name';
import LAST_PROMOTION_EXECUTION_ID_FIELD from '@salesforce/schema/Promotion__c.Last_Promotion_Execution_Id__c';
import LAST_DEPLOYMENT_EXECUTION_ID_FIELD from '@salesforce/schema/Promotion__c.Last_Deployment_Execution_Id__c';

const fields = [DESTINATION_ENVIRONMENT];

export default class PromoteAndDeployChangesAction extends LightningElement {
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
        return label.Merge_and_deploy_changes_to_Environment + ' ' + (this.destinationEnvironment ? "'" + this.destinationEnvironment + "'" : '');
    }

    get destinationEnvironment() {
        return this.promotion ? getFieldValue(this.promotion.data, DESTINATION_ENVIRONMENT) : '';
    }

    closeModal() {
        this.template.querySelector('c-platform-event-subscriber').unsubscribe();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async mergeAndDeploy() {
        try {
            this.showSpinner = true;
            await this.template.querySelector('c-platform-event-subscriber').subscribe();
            const recordId = this.recordId;
            const deploymentSteps = this.template.querySelector('c-order-deployment-steps').getDeploymentStepIds();
            await execute({ recordId, deploymentSteps });
        } catch (error) {
            this._messageAlert(
                label.Error_while_processing_the_Merge_and_Deploy_Changes + ' ' + reduceErrors(error),
                'error',
                true,
                this.communicationId
            );
            this.showSpinner = false;
            this.closeModal();
        }
    }

    async handleEvent(event) {
        const promotionExecutionDetail = await result({
            recId: this.recordId,
            objectApiName: this.objectApiName,
            fieldApiName: LAST_PROMOTION_EXECUTION_ID_FIELD.fieldApiName
        });

        const deploymentExecutionDetail = await result({
            recId: this.recordId,
            objectApiName: this.objectApiName,
            fieldApiName: LAST_DEPLOYMENT_EXECUTION_ID_FIELD.fieldApiName
        });

        if (this._isRelevant(event, promotionExecutionDetail) || this._isRelevant(event, deploymentExecutionDetail)) {
            this._closeModalAndRefresh();
        }
    }

    _isRelevant(event, recordDetail) {
        const parsedMessage = event.detail.response;
        const fieldName = (!!namespace ? namespace : '') + 'Topic_Uri__c';
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
                this._messageAlert(label.There_is_a_job_execution_in_progress_for_this_Promotion, 'error', false, this.modalCommunicationId);
                this.modalBodyMessage = label.Wait_until_job_execution_finished;
                this.cancelButtonLabel = label.Close;
                this.showActionButtons = false;
            } else if (validationResponse.promotionIsCancelled) {
                this._messageAlert(label.Unable_to + ' ' + this.headerText, 'error', false, this.modalCommunicationId);
                this.modalBodyMessage = label.Cancelled_Promotions;
                this.cancelButtonLabel = label.Close;
                this.showActionButtons = false;
            } else {
                this._messageAlert(label.Merge_Deploy_Body, 'info', false, this.modalCommunicationId);
                this.modalBodyMessage = label.Merge_Deploy_Body_2;
                this.showActionButtons = true;
            }
        } else {
            this._messageAlert(label.Unable_to + ' ' + this.headerText, 'error', false, this.modalCommunicationId);
            this.modalBodyMessage = label.Please_add_at_least_one_user_story_to_your_promotion;
            this.cancelButtonLabel = label.Close;
            this.showActionButtons = false;
        }

        this.showSpinner = false;
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