import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import selectedStories from '@salesforce/apex/UserStoryBundleCtrl.selectedStories';
import getAllMetadata from '@salesforce/apex/UserStoryBundleCtrl.getAllMetadata';
import createBundleRecords from '@salesforce/apex/UserStoryBundleCtrl.createBundleRecords';

import CANCEL from '@salesforce/label/c.Cancel';
import USER_STORY_BUNDLE from '@salesforce/label/c.User_Story_Bundle';
import CREATE_US_BUNDLE_BUTTON from '@salesforce/label/c.CREATE_US_BUNDLE_BUTTON';
import CANNOT_BUNDLE_MODAL_TITLE from '@salesforce/label/c.USB_CANNOT_BUNDLE_MODAL_TITLE';
import TITLE from '@salesforce/label/c.USDependency_Title';

import TITLE_FIELD from '@salesforce/schema/Artifact_Version__c.Name';

export default class UserStoryBundle extends NavigationMixin(LightningElement) {
    @api ids;

    label = {
        CANCEL,
        USER_STORY_BUNDLE,
        CREATE_US_BUNDLE_BUTTON,
        CANNOT_BUNDLE_MODAL_TITLE,
        TITLE
    };
    title = TITLE_FIELD.fieldApiName;
    objectApiName = TITLE_FIELD.objectApiName;
    isLoading = false;
    validationErrors = {
        isError: false,
        message: ''
    };
    submitError = {
        isError: false,
        message: ''
    };

    _stories;
    _metadata;
    _fullProfiles;
    _destructiveChanges;
    _error;

    async connectedCallback() {
        try {
            [this._stories, this._metadata, this._fullProfiles, this._destructiveChanges] = await Promise.all([
                selectedStories({ ids: this.ids }),
                getAllMetadata({ ids: this.ids, operations: ['', 'Commit Files', 'Recommit Files'] }),
                getAllMetadata({ ids: this.ids, operations: ['Full Profiles & Permission Sets', 'FullProfilePermissionSets'] }),
                getAllMetadata({ ids: this.ids, operations: ['Destructive Changes', 'GitDeletion'] })
            ]);
        } catch (e) {
            this._error = e;
        }
    }

    async handleSubmit(event) {
        this.isLoading = true;

        event.preventDefault();
        const fields = event.detail.fields;
        try {
            const recordid = await createBundleRecords({
                bundle: fields,
                stories: this._stories,
                metadata: this._metadata,
                fullProfiles: this._fullProfiles,
                destructiveChanges: this._destructiveChanges
            });

            this._navigateToRecordViewPage(recordid);
        } catch (e) {
            this.submitError = {
                isError: true,
                message: e.body.message
            };
        }

        this.isLoading = false;
    }

    closeModal() {
        this._navigateToRecordViewPage('');
    }

    _navigateToRecordViewPage(recordId) {
        const recordEvent = new CustomEvent('navigatetorecord', {
            detail: recordId,
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(recordEvent);
    }
}