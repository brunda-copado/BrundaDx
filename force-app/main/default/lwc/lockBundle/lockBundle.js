import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getFieldsFromFieldSet from '@salesforce/apex/LockBundleCtrl.getFieldsFromFieldSet';
import getLockedChildStories from '@salesforce/apex/LockBundleCtrl.getLockedChildStories';
import createPrefilledStory from '@salesforce/apex/LockBundleCtrl.createPrefilledStory';
import lockBundle from '@salesforce/apex/LockBundleCtrl.lockBundle';
import isPlatformBundle from '@salesforce/apex/LockBundleCtrl.isPlatformBundle';

import ORG_CREDENTIAL from '@salesforce/schema/User_Story__c.Org_Credential__c';
import ENVIRONMENT from '@salesforce/schema/User_Story__c.Environment__c';
import PROJECT from '@salesforce/schema/User_Story__c.Project__c';
import RELEASE from '@salesforce/schema/User_Story__c.Release__c';
import TITLE from '@salesforce/schema/User_Story__c.User_Story_Title__c';

import CANCEL from '@salesforce/label/c.Cancel';
import LOADING from '@salesforce/label/c.LOADING';
import LOCK_BUNDLE from '@salesforce/label/c.USB_LOCK_BUNDLE';
import CANNOT_LOCK_BUNDLE from '@salesforce/label/c.USB_CANNOT_LOCK_BUNDLE';
import ERROR_ALREADY_LOCKED_STORY from '@salesforce/label/c.USB_ERROR_ALREADY_LOCKED_STORY';

import copadoUtils from 'c/copadocoreUtils';

export default class LockBundle extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectName = ORG_CREDENTIAL.objectApiName;
    @api fieldSet = copadoUtils.namespace + 'Bundle';

    isLoading = true;
    error = false;
    submitError = {
        isError: false,
        message: ''
    };
    label = {
        CANCEL,
        LOCK_BUNDLE,
        LOADING,
        CANNOT_LOCK_BUNDLE
    };

    displayFields = [];

    isPlatform = false;

    async handleOnLoad() {
        if (this.isLoading) {
            try {
                this.isPlatform = await isPlatformBundle({ bundleId: this.recordId });
                const result = await getLockedChildStories({ version: this.recordId });
                if (result.length) {
                    this.error = ERROR_ALREADY_LOCKED_STORY + '\n\n' + result.join('\n');
                }
                await this._getDisplayFields();
                await this._generateInputForm();
                this.isLoading = false;
                this.template.querySelector('.body').classList.remove('slds-hide');
            } catch (e) {
                this.submitError = {
                    isError: true,
                    message: copadoUtils.reduceErrors(e)
                };
            }
        }
    }

    // PUBLIC

    async handleSubmit(event) {
        this.isLoading = true;
        try {
            event.preventDefault();
            const result = await lockBundle({
                story: event.detail.fields,
                bundleId: this.recordId
            });

            this.template.querySelector('.body').classList.add('slds-hide');

            this._handleSuccess(result);
        } catch (e) {
            let errorMessage = copadoUtils.reduceErrors(e);
            if (errorMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                errorMessage = this._getfieldValidationError(errorMessage);
            }
            this.submitError = {
                isError: true,
                message: errorMessage
            };
        } finally {
            this.isLoading = false;
        }
    }

    saveForm() {
        const btn = this.template.querySelector('.slds-hide');
        if (btn) {
            btn.click();
        }
    }

    closeModal() {
        const closeQA = new CustomEvent('close', {
            bubbles: true,
            composed: true
        });

        this.dispatchEvent(closeQA);
    }

    // PRIVATE

    async _generateInputForm() {
        const prefilledStory = await createPrefilledStory({ version: this.recordId });
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            this._prefillForm(prefilledStory, inputFields);
        }
    }

    _prefillForm(prefilledStory, inputFields) {
        inputFields.forEach(field => {
            field.value = prefilledStory[field.fieldName];
        });
    }

    async _getDisplayFields() {
        this.displayFields = [
            { fieldName: TITLE.fieldApiName, readOnly: false, required: true },
            { fieldName: ORG_CREDENTIAL.fieldApiName, readOnly: this.isPlatform, required: true },
            { fieldName: ENVIRONMENT.fieldApiName, readOnly: this.isPlatform, required: true },
            { fieldName: PROJECT.fieldApiName, readOnly: this.isPlatform, required: true },
            { fieldName: RELEASE.fieldApiName, readOnly: false, required: false }
        ];
        const fieldNames = await getFieldsFromFieldSet({
            objectName: this.objectName,
            fieldSet: this.fieldSet
        });
        fieldNames.forEach(fieldName => {
            if (!this.displayFields.some(field => field.fieldName === fieldName)) {
                this.displayFields.push({ fieldName: fieldName, required: false, readOnly: false });
            }
        });
    }

    _handleSuccess(detail) {
        if (detail.isPlatform) {
            let recordId = detail.storyId;
            if (detail.commitIds.length > 0) {
                recordId = detail.commitIds[0];
            }
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            });
        } else {
            const namespace = copadoUtils.namespace.length === 0 ? 'c' : copadoUtils.namespace.replace('__', '');
            const cmpDefinition = {
                componentDef: `${namespace}:waitingPage`,
                attributes: {
                    storyId: detail.storyId,
                    actionIds: detail.commitIds,
                    snapshotId: detail.snapshotId,
                    actionType: 'commit'
                }
            };

            // Note: Base64 encode the cmpDefinition JS object
            const encodedCmpDefinition = btoa(JSON.stringify(cmpDefinition));
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/one/one.app#' + encodedCmpDefinition
                }
            });
        }
    }

    _getfieldValidationError(errorMessage) {
        const fieldValidationError = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION')[1];
        errorMessage = errorMessage.includes(':') ? fieldValidationError.split(':')[0] : fieldValidationError;
        errorMessage = errorMessage.length && errorMessage.includes(', ') ? errorMessage.split(', ')[1] : errorMessage;
        return errorMessage;
    }
}