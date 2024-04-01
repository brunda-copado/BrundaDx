import { LightningElement, api, wire } from 'lwc';
import { reduceErrors, namespace } from 'c/copadocoreUtils';

import { CloseActionScreenEvent } from 'lightning/actions';
import { publish, MessageContext } from 'lightning/messageService';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import result from '@salesforce/apex/ResultMonitorLWCHandler.result';

import { label } from './constants';

import execute from '@salesforce/apex/RunPromoteJobTemplateHandler.execute';
import validate from '@salesforce/apex/RunPromoteJobTemplateHandler.validate';

import LAST_PROMOTION_EXECUTION_ID_FIELD from '@salesforce/schema/Promotion__c.Last_Promotion_Execution_Id__c';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

export default class PromoteChangesAction extends NavigationMixin(LightningElement) {
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
    promotionHasUserStories = false;
    showSpinner = true;
    modalBodyMessage = '';
    showActionButtons = false;
    cancelButtonLabel = label.Cancel;
    stepChannelName = `/event/${namespace}Event__e`;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this._recordId = currentPageReference.state.recordId;
            this._validatePromotion();
        }
    }

    @wire(MessageContext)
    messageContext;

    closeModal() {
        this.template.querySelector('c-platform-event-subscriber').unsubscribe();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async merge() {
        try {
            this.showSpinner = true;
            await this.template.querySelector('c-platform-event-subscriber').subscribe();
            const recordId = this.recordId;
            const doNotRunJob = false;
            await execute({ recordId, doNotRunJob });
        } catch (error) {
            this._messageAlert(label.Error_while_processing_the_Merge_Changes + ' ' + reduceErrors(error), 'error', true, this.communicationId);
            this.showSpinner = false;
            this.closeModal();
        }
    }

    async createJobExecutionOnly() {
        try {
            this.showSpinner = true;
            const recordId = this.recordId;
            const doNotRunJob = true;
            await execute({ recordId, doNotRunJob });
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
            fieldApiName: LAST_PROMOTION_EXECUTION_ID_FIELD.fieldApiName
        });

        if (this._isRelevant(event, recordDetail)) {
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
            } else if (!validationResponse.hasMetadata) {
                this._messageAlert(label.Error_while_processing_the_Merge_Changes, 'error', false, this.modalCommunicationId);
                this.modalBodyMessage = label.Can_Not_Promote_If_Either_No_Deployment_Steps_or_Metadata_Commits;
                this.cancelButtonLabel = label.Close;
                this.showActionButtons = false;
            } else if (validationResponse.promotionIsCancelled) {
                this._messageAlert(label.Error_while_processing_the_Merge_Changes, 'error', false, this.modalCommunicationId);
                this.modalBodyMessage = label.Cancelled_Promotions;
                this.cancelButtonLabel = label.Close;
                this.showActionButtons = false;
            } else {
                this._messageAlert(label.Merge_Changes_Body, 'info', false, this.modalCommunicationId);
                this.modalBodyMessage = label.Merge_Changes_Body_2;
                this.showActionButtons = true;
            }
        } else {
            this._messageAlert(label.There_are_not_User_Stories_in_this_Promotion, 'error', false, this.modalCommunicationId);
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