import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { MessageContext, subscribe, publish } from 'lightning/messageService';

import { namespace, handleAsyncError, reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import editBaseBranchAvailable from '@salesforce/customPermission/Edit_User_Story_Commit_Base_Branch';

import reCreateFeatureBranchAvailable from '@salesforce/apex/UserStoryCommitCtrl.isReCreateFeatureBranchAvailable';

import COMMIT_PAGE_COMMUNICATION_CHANNEL from '@salesforce/messageChannel/CommitPageCommunication__c';

import { label, schema } from './constants';

export default class UserStoryCommitBody extends LightningElement {
    label = label;
    schema = schema;

    showSpinner = false;

    editBaseBranchAvailable = editBaseBranchAvailable;
    reCreateFeatureBranchAvailable;

    commitMessage;
    reCreate;
    changeBaseBranch;
    baseBranch;

    @wire(MessageContext)
    _context;

    // These variables, although "private", do not start with '_'
    recordId;

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        if (pageReference && pageReference.state) {
            const parameterName = `${namespace || 'c__'}recordId`;
            this.recordId = pageReference.state[parameterName];
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [schema.NAME, schema.TITLE] })
    wiredRecord({ error, data }) {
        if (data) {
            this.commitMessage = `${getFieldValue(data, schema.NAME)} ${getFieldValue(data, schema.TITLE)}`;
            this.showSpinner = false;
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async connectedCallback() {
        this.showSpinner = true;
        const safeReCreateFeatureBranchAvailable = handleAsyncError(this._reCreateFeatureBranchAvailable, {});
        this.reCreateFeatureBranchAvailable = await safeReCreateFeatureBranchAvailable(this, {});
        this._handleSubscribe();
    }

    // TEMPLATE

    handleInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleCheckBoxChange(event) {
        this[event.target.name] = event.target.checked;
    }

    // PRIVATE

    _handleSubscribe() {
        subscribe(this._context, COMMIT_PAGE_COMMUNICATION_CHANNEL, (event) => {
            if (event != null && event.type === 'request') {
                const payload = {
                    type: 'commitInformation',
                    commitMessage: this.commitMessage,
                    reCreateFeatureBranch: this.reCreate,
                    changeBaseBranch: this.changeBaseBranch,
                    baseBranch: this.baseBranch
                };
                publish(this._context, COMMIT_PAGE_COMMUNICATION_CHANNEL, payload);
            }
        });
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _reCreateFeatureBranchAvailable(self, fields) {
        return reCreateFeatureBranchAvailable(fields);
    }
}