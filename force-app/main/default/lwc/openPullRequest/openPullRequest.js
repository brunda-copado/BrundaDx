import { LightningElement, api } from 'lwc';
import { reduceErrors } from 'c/copadocoreUtils';

import { CloseActionScreenEvent } from 'lightning/actions';
import { label, fields } from './constants';
import { generatePullRequestUrl } from './utils';

import getData from '@salesforce/apex/OpenPullRequestController.getData';

export default class PromotePullRequest extends LightningElement {
    @api set recordId(value) {
        this._recordId = value;
        this._getData();
    }
    get recordId() {
        return this._recordId;
    }
    _recordId;

    label = label;

    promotion;
    pipeline;
    destinationBranch;

    showSpinner = true;

    errorMessage;

    openPullRequest() {
        const gitRepository = this.pipeline[fields.GIT_REPOSITORY.fieldApiName];
        const pullRequestBase = this.pipeline[fields.GIT_REPOSITORY.fieldApiName.replace('__c', '__r')][fields.PULL_REQUEST_BASE_URL.fieldApiName];
        const gitProvider = this.pipeline[fields.GIT_REPOSITORY.fieldApiName.replace('__c', '__r')][fields.GIT_PROVIDER.fieldApiName];
        const branch = this.destinationBranch;
        try {
            if (gitRepository && pullRequestBase && pullRequestBase !== '' && gitProvider && gitProvider !== '' && branch && branch !== '') {
                const config = {};
                config.type = gitProvider;
                config.url = pullRequestBase;
                config.base = branch;
                config.compare = 'promotion/' + this.promotionName;
                const pullVar = generatePullRequestUrl(config);
                this.closeAction();

                const win = window.open(pullVar);
                if (win) {
                    //Browser has allowed it to be opened
                    win.focus();
                } else {
                    //Browser has blocked it
                    this.errorMessage = label.POPUP_BLOCKER_MESSAGE;
                }
            } else {
                this.errorMessage = label.PULL_REQUEST_VALIDATION;
            }
        } catch (error) {
            this.errorMessage = 'Error: ' + reduceErrors(error);
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async _getData() {
        try {
            const data = await getData({ recordId: this.recordId });
            this.promotion = data.promotion;
            this.promotionName = this.promotion[fields.PROMOTION_NAME.fieldApiName];
            this.pipeline = data.pipeline;
            this.destinationBranch = data.destinationEnvironmentBranch;
            if (!data.isMerged) {
                this.errorMessage = label.PULL_REQUEST_FOR_PROMOTION_CAN_NOT_BE_OPEN;
                return;
            }
            const gitRepository = this.pipeline[fields.GIT_REPOSITORY.fieldApiName];
            if (gitRepository == null) {
                this.errorMessage = label.GIT_REPOSITORY_REQUIRED;
                return;
            }
            const pullRequestBase = this.pipeline[fields.GIT_REPOSITORY.fieldApiName.replace('__c', '__r')][
                fields.PULL_REQUEST_BASE_URL.fieldApiName
            ];
            if (pullRequestBase == null) {
                this.errorMessage = label.GIT_URL_EMPTY;
                return;
            }
        } catch (error) {
            this.errorMessage = 'Error: ' + reduceErrors(error);
        } finally {
            this.showSpinner = false;
        }
    }
}