import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

import { labels, constants, schema } from './util';
import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

export default class ResultLogVisualizer extends NavigationMixin(LightningElement) {
    @api recordId;

    logData;
    labels = labels;
    showLogs;
    showSpinner;
    illustration;
    showMessage = false;

    _recordId;
    _versionId;


    @wire(getRecord, { recordId: '$recordId', fields: [schema.STATUS_FIELD] })
    wiredResult({ data, error }) {
        this.showLogs = false;
        this.showSpinner = true;
        this.illustration = null;

        if (data) {
            const status = getFieldValue(data, schema.STATUS_FIELD);
            if (constants.FINISHED_STATUSES.includes(status)) {
                this._recordId = this.recordId;
            } else {
                this.showSpinner = false;
                this.illustration = {
                    name: 'no_data:desert',
                    title: labels.LOG_NOT_GENERATED,
                    body: labels.LOGS_IN_PROGRESS
                };
            }
        } else if (error) {
            this.showSpinner = false;
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    @wire(getRelatedListRecords, {
        parentRecordId: '$_recordId',
        relatedListId: schema.RESULT_DOC_RELATIONSHIP,
        fields: [
            `${schema.LATEST_PUBLISHED_VERSION_FIELD.objectApiName}.${schema.LATEST_PUBLISHED_VERSION_FIELD.fieldApiName}`,
            `${schema.TITLE_FIELD.objectApiName}.${schema.TITLE_FIELD.fieldApiName}`
        ]
    })
    docLinksInfo({ error, data }) {
        if (data) {
            let logsDoc;
            if (data.records?.length) {
                logsDoc = data.records.find((doc) =>
                    getFieldValue(doc, schema.TITLE_FIELD).includes(`Function Logs for ${this.recordId}.txt`)
                );
            }
            if (logsDoc) {
                this.showLogs = true;
                this._versionId = getFieldValue(logsDoc, schema.LATEST_PUBLISHED_VERSION_FIELD);
            } else {
                this.showSpinner = false;
                this.illustration = {
                    name: 'error:page_not_available',
                    title: labels.LOGS_NOT_AVAILABLE,
                    body: labels.LOG_NOT_GENERATED_PROCESS
                };
            }
        } else if (error) {
            this.showSpinner = false;
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    @wire(getRecord, { recordId: '$_versionId', fields: [schema.VERSION_DATA_FIELD, schema.CONTENT_SIZE_FIELD] })
    wiredVersion({ data, error }) {
        if (data) {
            const size = getFieldValue(data, schema.CONTENT_SIZE_FIELD);
            if (size > constants.MAX_FILE_SIZE_SUPPORTED) {
                this.showLogs = false;
                this.showMessage = true;
            } else {
                const ldata = getFieldValue(data, schema.VERSION_DATA_FIELD);
                this.logData = this.b64DecodeUnicode(ldata);
            }
        } else {
            showToastError(this, { message: reduceErrors(error) });
        }
        this.showSpinner = false;
    }


    b64DecodeUnicode(str) {
        return decodeURIComponent(atob(str).split('').map(function (c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
    }


    handleDownload() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: constants.DOWNLOAD_URL + this._versionId
            }
        });
    }
}