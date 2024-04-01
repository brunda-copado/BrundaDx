import { LightningElement, api, wire } from 'lwc';

import { publish, MessageContext } from 'lightning/messageService';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { label, schema, constants } from './constants';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { reduceErrors, formatLabel } from 'c/copadocoreUtils';
import hasRemoveMetadataCustomPermission from '@salesforce/customPermission/Remove_metadata_from_Promotion';

import saveIgnoreChanges from '@salesforce/apex/PromotionMetadatasRemovalController.saveIgnoreChanges';
import getMetadataDetails from '@salesforce/apex/PromotionMetadatasRemovalController.getMetadataDetails';

import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PromotionUserStoryMetadatasRemovalModal extends LightningElement {
    @api changes;
    @api recordId;
    @api rowsCount;

    communicationId = 'promotionRecordPageAlerts';
    modalCommunicationId = 'modalAlerts';

    label = label;
    schema = schema;
    isLoading;

    fileData = [];
    metadataChanges = [];

    _versionId;

    get hasNoPermission() {
        return !hasRemoveMetadataCustomPermission;
    }

    get body() {
        return this.hasNoPermission
            ? label.Unable_to_remove_changes_body
            : this.rowsCount === this.changes?.length
            ? label.Remove_All_Changes_Error_Message
            : formatLabel(label.Remove_Changes_Confirmation, [this.changes?.length]);
    }

    get showActionButtons() {
        return this.rowsCount === this.changes?.length || this.hasNoPermission ? false : true;
    }

    get cancelButtonLabel() {
        return this.rowsCount === this.changes?.length ? label.Close : label.Cancel;
    }

    @wire(MessageContext)
    messageContext;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: schema.RESULT_DOC_RELATIONSHIP,
        fields: [
            `${schema.LATEST_PUBLISHED_VERSION_FIELD.objectApiName}.${schema.LATEST_PUBLISHED_VERSION_FIELD.fieldApiName}`,
            `${schema.TITLE_FIELD.objectApiName}.${schema.TITLE_FIELD.fieldApiName}`
        ]
    })
    documentLinksInfo({ error, data }) {
        if (data) {
            if (data.records?.length) {
                let ignoredChangeDoc = data.records.find((doc) =>
                    getFieldValue(doc, schema.TITLE_FIELD).includes(constants.IGNORED_CHANGES_FILE_NAME)
                );
                if (ignoredChangeDoc) {
                    this._versionId = getFieldValue(ignoredChangeDoc, schema.LATEST_PUBLISHED_VERSION_FIELD);
                }
            }
        } else if (error) {
            showToastError(this, { message: label.FETCH_DATA_ERROR + ': ' + reduceErrors(error) });
        }
    }

    @wire(getRecord, { recordId: '$_versionId', fields: [schema.VERSION_DATA_FIELD, schema.CONTENT_SIZE_FIELD] })
    wiredVersion({ data, error }) {
        if (data) {
            const size = getFieldValue(data, schema.CONTENT_SIZE_FIELD);
            if (size < constants.MAX_FILE_SIZE_SUPPORTED) {
                const ldata = getFieldValue(data, schema.VERSION_DATA_FIELD);
                this.fileData = this.b64DecodeUnicode(ldata);
            } else {
                showToastError(this, { message: label.FETCH_DATA_ERROR + ': ' + constants.IGNORED_CHANGES_FILE_NAME });
            }
        } else {
            showToastError(this, { message: label.FETCH_DATA_ERROR + ': ' + reduceErrors(error) });
        }
    }

    b64DecodeUnicode(str) {
        return decodeURIComponent(
            atob(str)
                .split('')
                .map(function (c) {
                    return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
                })
                .join('')
        );
    }

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    renderedCallback() {
        if (this.hasNoPermission || this.rowsCount === this.changes?.length) {
            this._messageAlert(label.Remove_Changes_Error, 'error', false, this.modalCommunicationId);
        } else {
            this._messageAlert(label.Remove_Changes_Warning, 'warning', false, this.modalCommunicationId);
        }
    }

    handleCancel() {
        this.hide();
    }

    async handleConfirm() {
        this._getMetadataRecords();
        this.hide();
        this.dispatchEvent(new CustomEvent('changesremoved'));
    }

    // Private

    _messageAlert(message, variant, dismissible, communicationId) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    async _getMetadataRecords() {
        try {
            if (this.changes) {
                let metadataIds = [];
                this.changes.forEach((change) => {
                    metadataIds.push(change.Id);
                });
                const data = await getMetadataDetails({ metadataIds });
                if (data) {
                    data.forEach((metadata) => {
                        let userStory = metadata[schema.USER_STORY_METADATA_USER_STORY_FIELD.fieldApiName.replace('__c', '__r')];

                        // Make sure to update change parameters in Promotion Service and Promotion Deployment Service if format of the file is changed here.
                        let metadataChange = {
                            u: userStory[schema.USER_STORY_NAME_FIELD.fieldApiName],
                            t: metadata[schema.USER_STORY_METADATA_TYPE_FIELD.fieldApiName],
                            n: metadata[schema.USER_STORY_METADATA_API_NAME_FIELD.fieldApiName],
                            m: metadata[schema.USER_STORY_METADATA_MODULE_DIRECTORY_FIELD.fieldApiName],
                            a: metadata[schema.USER_STORY_METADATA_ACTION_FIELD.fieldApiName]
                        };
                        this.metadataChanges.push(metadataChange);
                    });
                    this._saveChanges();
                }
            }
        } catch (error) {
            this.messageAlert(label.Error_while_removing_changes + ' ' + reduceErrors(error), 'error', false, this.communicationId);
        }
    }

    async _saveChanges() {
        try {
            if (this.metadataChanges) {
                let existingData = this.fileData.length ? JSON.parse(this.fileData) : [];
                const combinedData = existingData.concat(this.metadataChanges);
                let fileData = JSON.stringify(combinedData);
                const promotionId = this.recordId;
                await saveIgnoreChanges({ promotionId, fileData });
                showToastSuccess(this, { message: label.Changes_removed_successfully });
            }
        } catch (error) {
            this.messageAlert(label.Error_while_removing_changes + ' ' + reduceErrors(error), 'error', false, this.communicationId);
        }
    }
}