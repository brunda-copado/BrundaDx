import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { MessageContext, publish, subscribe } from 'lightning/messageService';
import COMMIT_PAGE_COMMUNICATION_CHANNEL from '@salesforce/messageChannel/CommitPageCommunication__c';

import { handleAsyncError } from 'c/copadocoreUtils';

import commitChanges from '@salesforce/apex/UserStoryCommitCtrl.commitChanges';

import { label, schema } from './constants';

export default class UserStoryCommitChangesModal extends NavigationMixin(LightningElement) {
    label = label;

    @api recordId;

    @wire(MessageContext)
    _context;

    // Note: variable name is important to match event type
    commitInformation;
    changes;

    validationResult;

    isRunning = false;

    get _isRequestReady() {
        return !!this.commitInformation && !!this.changes;
    }

    get showErrorPopover() {
        return this.validationResult && this.validationResult.valid === false;
    }

    get errorPopoverMessage() {
        return this.validationResult.message;
    }

    // PUBLIC

    @api
    show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    // TEMPLATE

    connectedCallback() {
        subscribe(this._context, COMMIT_PAGE_COMMUNICATION_CHANNEL, (event) => {
            if (event != null && event.type !== 'request') {
                this[event.type] = event;
                this._commit();
            }
        });
    }

    handleClickCancel() {
        this.template.querySelector('c-copadocore-modal').hide();
        this._reset();
    }

    handleClickCommit() {
        this.isRunning = true;
        this.commitInformation = null;
        this.changes = null;
        const payload = {
            type: 'request'
        };
        publish(this._context, COMMIT_PAGE_COMMUNICATION_CHANNEL, payload);
    }

    // PRIVATE

    async _commit() {
        if (this._isRequestReady) {
            this.validationResult = this._validateRequest();

            if (this.validationResult.valid) {
                const request = {
                    userStoryId: this.recordId,
                    changes: this.changes.value,
                    reCreateFeatureBranch: this.commitInformation.reCreateFeatureBranch || false,
                    executeCommit: true,
                    baseBranch: this.commitInformation.baseBranch,
                    message: this.commitInformation.commitMessage
                };

                const safeCommitChanges = handleAsyncError(this._commitChanges, {});
                const result = await safeCommitChanges(this, { request });
                if (result) {
                    this.template.querySelector('c-copadocore-modal').hide();
                    this._navigateToUserStoryCommitRecord(result[schema.USER_STORY_COMMIT_FIELD.fieldApiName]);
                }
            } else {
                this.template.querySelector('c-copadocore-error-popover')?.openPopOver();
            }
            this.isRunning = false;
        }
    }

    _validateRequest() {
        const validCommitMessage = !!this.commitInformation.commitMessage;
        const validChanges = !!this.changes.value && this.changes.value.length > 0;
        const validBaseBranch =
            !this.commitInformation.changeBaseBranch || (this.commitInformation.changeBaseBranch && this.commitInformation.baseBranch);

        const valid = validCommitMessage && validChanges && validBaseBranch;
        
        var message = [];
        if(!validCommitMessage){
            message.push(label.COMMIT_MESSAGE_NOT_EMPTY);
        }
        if(!validBaseBranch){
            message.push(label.COMMIT_BASE_BRANCH_NOT_EMPTY);
        }
        if(!validChanges){
            message.push(label.COMMIT_CHANGES_NOT_EMPTY);
        }
       
        return {
            valid,
            message
        };
    }

    _navigateToUserStoryCommitRecord(userStoryCommitId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: userStoryCommitId,
                actionName: 'view'
            }
        });
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _commitChanges(self, fields) {
        return commitChanges(fields);
    }

    _reset() {
        this.validationResult = null;
        this.commitInformation = null;
        this.changes = null;
    }
}