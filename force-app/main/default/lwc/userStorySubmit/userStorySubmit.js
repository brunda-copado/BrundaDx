import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';

import { CloseActionScreenEvent } from 'lightning/actions';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors, formatLabel } from 'c/copadocoreUtils';

import Skip_Continuous_Delivery_Rules from '@salesforce/customPermission/Skip_Continuous_Delivery_Rules';
import getData from '@salesforce/apex/UserStorySubmitCtrl.getData';
import resubmitUserStory from '@salesforce/apex/UserStorySubmitCtrl.resubmitUserStory';

import { label, schema, constants } from './constants';

export default class UserStorySubmit extends LightningElement {
    label = label;
    schema = schema;
    constants = constants;

    userStoryData = {};
    skipContinuousDeliveryRules = false;
    submitButtonDisabled = true;
    displayError = false;
    displaySpinner = true;

    pipelineStages = [];

    _userStoryId;
    @api
    get recordId() {
        return this._userStoryId;
    }
    set recordId(value) {
        this._userStoryId = value;
        (async () => {
            try {
                this.displaySpinner = true;
                this.userStoryData = await getData({ userStoryId: this.recordId });
                this.displayError = this.userStoryData.errorList ? this.userStoryData.errorList.length > 0 : false;
                this.userStoryData.submitBehaviour = this._submitBehaviour();
                if (
                    this.userStoryData.pipelineId &&
                    this.userStoryData.destinationEnvironmentName &&
                    (!this.userStoryData.userStoryReadyToPromote || this._isResubmit)
                ) {
                    this.submitButtonDisabled = false;
                    this._setPipelineStages();
                }
            } catch (error) {
                this._handleError(error);
            } finally {
                this.displaySpinner = false;
            }
        })();
    }

    get canSkipCDRules() {
        return this.userStoryData.submitBehaviour === constants.AUTOMATION_EXECUTION_SCHEDULED ||
            this.userStoryData.submitBehaviour === label.SUBMIT_BEHAVIOUR_MANUALLY
            ? Skip_Continuous_Delivery_Rules
            : false;
    }

    get reSubmitUserStoryWarning() {
        return this.userStoryData.userStoryReadyToPromote && !this.userStoryData.hasLastFailedPromotion;
    }

    get submitUserStoryForPromotionLabel() {
        return this.userStoryData.userStoryName ? formatLabel(label.SUBMIT_USER_STORY_FOR_PROMOTION, [this.userStoryData.userStoryName]) : '';
    }

    get submitUserStoryDeployChangesText() {
        switch (this.userStoryData.submitBehaviour) {
            case constants.AUTOMATION_EXECUTION_SCHEDULED:
                return this._scheduledBehaviourText();
            case constants.AUTOMATION_EXECUTION_IMMEDIATE:
                return this._immediateBehaviourText();
            default:
                return this._manualBehaviourText();
        }
    }

    get userStoryCanNotBeSubmittedLabel() {
        return this.userStoryData.userStoryName ? formatLabel(label.USER_STORY_CAN_NOT_BE_SUBMITTED, [this.userStoryData.userStoryName]) : '';
    }

    get userStoryCouldNotBeSubmittedLabel() {
        return this.userStoryData.userStoryName ? formatLabel(label.USER_STORY_COULD_NOT_BE_SUBMITTED, [this.userStoryData.userStoryName]) : '';
    }

    handleChangeOmit(event) {
        this.skipContinuousDeliveryRules = event.target.checked;
    }

    async handleSubmit() {
        try {
            this.displaySpinner = true;
            if (this._isResubmit()) {
                this._resubmitUserStory();
            } else {
                await updateRecord(this._userStoryToUpdate());
            }
            showToastSuccess(this, { message: label.USER_STORY_SUCCESSFULLY_SUBMITTED });
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this._handleError(error);
        } finally {
            this.displaySpinner = false;
        }
    }
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // PRIVATE

    _submitBehaviour() {
        return this.userStoryData.automationRule && this.userStoryData.automationRule[schema.AUTOMATION_EXECUTION_FIELD.fieldApiName]
            ? this.userStoryData.automationRule[schema.AUTOMATION_EXECUTION_FIELD.fieldApiName]
            : label.SUBMIT_BEHAVIOUR_MANUALLY;
    }

    _scheduledBehaviourText() {
        return (
            formatLabel(label.SUBMIT_BEHAVIOUR_SCHEDULED_DATE_TIME, [this.userStoryData.automationRuleScheduledJobDateTime]) +
            ' ' +
            formatLabel(label.SUBMIT_BEHAVIOUR_SCHEDULED_BY_THE_AUTOMATION, [
                this.userStoryData.automationRule.Id,
                this.userStoryData.automationRule.Name
            ])
        );
    }

    _immediateBehaviourText() {
        return (
            formatLabel(label.SUBMIT_USER_STORY_DEPLOY_CHANGES, [label.SUBMIT_BEHAVIOUR_IMMEDIATELY]) +
            ' ' +
            formatLabel(label.SUBMIT_BEHAVIOUR_SCHEDULED_BY_THE_AUTOMATION, [
                this.userStoryData.automationRule.Id,
                this.userStoryData.automationRule.Name
            ])
        );
    }

    _manualBehaviourText() {
        return this.userStoryData.submitBehaviour ? formatLabel(label.SUBMIT_USER_STORY_DEPLOY_CHANGES, [label.SUBMIT_BEHAVIOUR_MANUALLY, '.']) : '';
    }

    _setPipelineStages() {
        this.pipelineStages.push({
            label: this.userStoryData.sourceEnvironmentName,
            value: this.userStoryData.sourceEnvironmentName,
            class: 'slds-path__item slds-is-current slds-is-active'
        });

        this.pipelineStages.push({
            label: this.userStoryData.destinationEnvironmentName,
            value: this.userStoryData.destinationEnvironmentName,
            class: 'slds-path__item slds-is-incomplete'
        });
    }

    _isResubmit() {
        return this.userStoryData.userStoryReadyToPromote && this.userStoryData.hasLastFailedPromotion;
    }

    async _resubmitUserStory() {
        await resubmitUserStory({ userStoryId: this.recordId });
    }

    _userStoryToUpdate() {
        const isImmediate =
            this.skipContinuousDeliveryRules || this.userStoryData.submitBehaviour === constants.AUTOMATION_EXECUTION_IMMEDIATE ? true : false;
        return {
            fields: {
                Id: this.recordId,
                [schema.PROMOTEANDDEPLOY.fieldApiName]: isImmediate,
                [schema.READYTOPROMOTE.fieldApiName]: isImmediate ? false : true
            }
        };
    }

    _handleError(error) {
        const errorMessage = reduceErrors(error);
        showToastError(this, { message: this.userStoryCouldNotBeSubmittedLabel + errorMessage });
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}