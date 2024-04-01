import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { MessageContext, publish, subscribe, APPLICATION_SCOPE } from 'lightning/messageService';
import { loadStyle } from 'lightning/platformResourceLoader';

import { namespace, reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import { refreshApex } from '@salesforce/apex';
import commitChanges from '@salesforce/apex/UserStoryCommitCtrl.commitChanges';
import validateCommitRequirements from '@salesforce/apex/UserStoryCommitCtrl.validateCommitRequirements';

import DYNAMIC_RENDERING_COMMUNICATION_CHANNEL from '@salesforce/messageChannel/DynamicRenderingCommunication__c';

import { label, resource, schema } from './constants';

export default class UserStoryCommitHeader extends NavigationMixin(LightningElement) {
    label = label;

    recordId;
    validationErrors;
    fieldName = namespace + 'Commit_Page';

    _platform;
    _componentsToRender = new Set();

    _wiredRecord;

    _parametersReady = false;
    _recordFieldsReady = false;
    _validationErrorsReady = false;

    _subscription = null;

    get validEntryPoint() {
        return !!this.recordId;
    }

    get validCommitRequirements() {
        return this.validationErrors && this.validationErrors.length === 0;
    }

    get isPageValid() {
        return this.validEntryPoint && !!this.validCommitRequirements;
    }

    get pageLoaded() {
        const isPageLoaded = this._parametersReady && ((this._recordFieldsReady && this._validationErrorsReady) || !this.recordId);
        if (isPageLoaded && this.isPageValid) {
            this._renderComponentsQueue();
        }
        return isPageLoaded;
    }

    @wire(MessageContext)
    _context;

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        this.showSpinner = true;
        if (pageReference && pageReference.state) {
            const parameterName = `${namespace || 'c__'}recordId`;
            const newRecordId = pageReference.state[parameterName];
            this._parametersReady = true;
            this._clearData();
            if (newRecordId && newRecordId !== this.recordId) {
                // Note: as we are working with different recordId, the wire method automatically fires again
                this.recordId = newRecordId;
            } else {
                // Note: as it is the same recordId, we need to manually refresh wire method
                refreshApex(this._wiredRecord);
            }
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [schema.PLATFORM_FIELD] })
    async wiredRecord(result) {
        this._wiredRecord = result;
        const { error, data } = result;
        if (data) {
            this._platform = getFieldValue(data, schema.PLATFORM_FIELD);
            try {
                this.validationErrors = await validateCommitRequirements({ recordId: this.recordId });
                this._refreshDynamicComponents();
            } catch (e) {
                const errorMessage = reduceErrors(e);
                showToastError(this, { message: errorMessage });
            }
            this._validationErrorsReady = true;
            if (this.pageLoaded && this.isPageValid) {
                this._renderComponentsQueue();
            }
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
        if (data || error) {
            this._recordFieldsReady = true;
        }
    }

    connectedCallback() {
        this.showSpinner = true;
        loadStyle(this, resource.HIDE_LIGHTNING_HEADER);
        this._handleSubscribe();
    }

    // TEMPLATE

    handleClickCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    handleClickCommit() {
        this.template.querySelector('c-user-story-commit-changes-modal').show();
    }

    // PRIVATE

    _handleSubscribe() {
        if (!this._subscription) {
            this._subscription = subscribe(
                this._context,
                DYNAMIC_RENDERING_COMMUNICATION_CHANNEL,
                (event) => {
                    if (event != null && event.type === 'requiringPlatform') {
                        const uiSectionId = event.name;
                        this._componentsToRender.add(uiSectionId);
                        if (this.pageLoaded && this.isPageValid) {
                            this._renderComponentsQueue();
                        }
                    }
                },
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _commitChanges(self, fields) {
        return commitChanges(fields);
    }

    _renderComponentsQueue() {
        this._componentsToRender.forEach((uiSectionId) => {
            this._requestComponentToRender(uiSectionId, this._platform);
            this._componentsToRender.delete(uiSectionId);
        });
    }

    _requestComponentToRender(uiSectionId, platform) {
        const payload = {
            type: uiSectionId,
            platform: platform
        };
        publish(this._context, DYNAMIC_RENDERING_COMMUNICATION_CHANNEL, payload);
    }

    _clearData() {
        this._recordFieldsReady = false;
        this._validationErrorsReady = false;

        this._platform = null;
        this.validationErrors = null;

        this._componentsToRender = new Set();
    }

    _refreshDynamicComponents() {
        const payload = {
            action: 'refresh'
        };
        publish(this._context, DYNAMIC_RENDERING_COMMUNICATION_CHANNEL, payload);
    }
}