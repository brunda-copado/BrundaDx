import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/copadocoreUtils';

import { handleAsyncError } from 'c/copadocoreUtils';

import getSupportedObjects from '@salesforce/apex/CreateStandardRecordCtrl.getSupportedObjects';
import getRecordBundle from '@salesforce/apex/CreateStandardRecordCtrl.getRecordBundle';
import getNestedRecords from '@salesforce/apex/CreateStandardRecordCtrl.getNestedRecords';
import search from '@salesforce/apex/CustomLookupComponentHelper.search';

import NAME from '@salesforce/label/c.NAME';
import DELETE from '@salesforce/label/c.DELETE';
import ObjectType from '@salesforce/label/c.ObjectType';
import INFO from '@salesforce/label/c.Commit_Page_Info';
import STATUS from '@salesforce/label/c.STATUS';
import LOADING from '@salesforce/label/c.LOADING';
import SUCCESS from '@salesforce/label/c.SUCCESS';
import ERROR from '@salesforce/label/c.ERROR';

import SelectObject from '@salesforce/label/c.SelectObject';
import SelectRecord from '@salesforce/label/c.SelectRecord';
import CreateExtension from '@salesforce/label/c.CreateExtensionTab';
import COPY_TO_CLIPBOARD from '@salesforce/label/c.COPY_TO_CLIPBOARD';

import CreateExtensionInstruction from '@salesforce/label/c.CreateExtensionInstruction';

import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';

export default class CreateStandardRecordBundle extends LightningElement {
    selectedObject;
    isLoading = false;
    serializedBundle;

    _supportedObjects;
    copied = false;
    _uniqueSelectedRecords = new Set();

    @track
    _selectedRecords = [];

    _lastResults;

    label = {
        SelectObject,
        SelectRecord,
        CreateExtension,
        COPY_TO_CLIPBOARD,
        CreateExtensionInstruction,
        INFO,
        LOADING
    };

    columns = [
        {
            label: NAME,
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'recordName' }, target: '_blank' }
        },
        {
            label: ObjectType,
            fieldName: 'objectType'
        },
        {
            label: STATUS,
            fieldName: 'status',
            cellAttributes: { iconName: { fieldName: 'iconName' } }
        },
        {
            type: 'action',
            typeAttributes: { rowActions: [{ label: DELETE, name: 'Delete' }] }
        }
    ];

    _blackListedFields = {
        'LastModifiedDate': true,
        'SystemModstamp': true,
        'IsDeleted': true,
        'CreatedDate': true,
        'CurrencyISOCode': true
    };


    async connectedCallback() {
        this.isLoading = true;
        try {
            this._supportedObjects = await getSupportedObjects();
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    get selectedRecords() {
        const selectedRecords = this._selectedRecords || [];

        return selectedRecords.map((selectedRecord) => ({ ...selectedRecord, recordLink: '/' + selectedRecord.recordId }));
    }

    get selectedObjectLabel() {
        return this.supportedObjects.find((supportedObject) => supportedObject.value === this.selectedObject)?.label;
    }

    get supportedObjects() {
        return this._supportedObjects || [];
    }

    get isLookupDisabled() {
        return !this.selectedObject;
    }

    get isInValidBundle() {
        return !this.selectedRecords || this.selectedRecords.some((selectedRecord) => {
            return selectedRecord.status !== 'Success'
        });
    }

    get hasSelectedRecords() {
        return Boolean(this.selectedRecords.length);
    }

    selectObject(event) {
        this.selectedObject = event.detail.value;
    }

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._search, {
            title: Error_Searching_Records
        });

        const queryConfig = {
            searchField: 'Name',
            objectName: this.selectedObject,
            searchKey: event.detail.searchTerm,
            extraFilterType: undefined,
            filterFormattingParameters: undefined
        };

        this._lastResults = await safeSearch(this, { queryConfig, objectLabel: this.selectedObjectLabel });

        if (this._lastResults) {
            lookupElement.setSearchResults(this._lastResults);
        }
    }

    addToSelectedRecord(event) {
        if (event.detail.length && !this._uniqueSelectedRecords.has(event.detail[0])) {
            this._selectedRecords.push({
                recordId: event.detail[0],
                recordName: this._lastResults.find((el) => el.id === event.detail[0]).title,
                objectType: this.selectedObjectLabel,
                status: SUCCESS,
                iconName: 'utility:success'
            });
            this._uniqueSelectedRecords.add(event.detail[0]);

            if (this.selectedObjectLabel === 'Job Template') {
                this.addNestedRecords(event.detail[0]);
            }

            this.template.querySelector('c-lookup').handleClearSelection();
        } else if (event.detail[0] && this._uniqueSelectedRecords.has(event.detail[0])) {
            this.template.querySelector('c-lookup').handleClearSelection();
        }
    }


    async addNestedRecords(jobTemplateId) {
        this.isLoading = true;
        try {
            const nestedRecords = await getNestedRecords({ jobTemplateId });

            nestedRecords.forEach((nestedRecord) => {
                if (!this._uniqueSelectedRecords.has(nestedRecord.id)) {
                    this._selectedRecords.push({
                        recordId: nestedRecord.id,
                        recordName: nestedRecord.name,
                        objectType: nestedRecord.type,
                        status: SUCCESS,
                        iconName: 'utility:success'
                    });
                    this._uniqueSelectedRecords.add(nestedRecord.id);
                }
            });
        } catch (error) {
            this._selectedRecords.forEach((selectedRecord) => {
                if (selectedRecord.recordId === jobTemplateId) {
                    selectedRecord.status = reduceErrors(error);
                    selectedRecord.iconName = 'utility:error';
                }
            });
        }

        this.isLoading = false;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;

        if (actionName === 'Delete') {
            const { recordId } = event.detail.row;
            const selectedRowIndex = this._selectedRecords.findIndex((record) => record.recordId === recordId);

            this._selectedRecords.splice(selectedRowIndex, 1);
            this._uniqueSelectedRecords.delete(recordId);
        }
    }

    async getRecordBundle() {
        this.isLoading = true;

        try {
            const serializedBundle = await getRecordBundle({ recordIds: this.selectedRecords.filter((selectedRecord) => selectedRecord.objectType !== 'Job Step').map((selectedRecord) => selectedRecord.recordId) });
            const bundleWithNamespace = JSON.stringify(this.bundleWithNamespace(serializedBundle), null, 2);

            this.downloadObjectAsJson(bundleWithNamespace, 'extension');
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    downloadObjectAsJson(exportObj, exportName) {
        const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(exportObj);
        const downloadAnchorNode = document.createElement('a');
        downloadAnchorNode.setAttribute("href", dataStr);
        downloadAnchorNode.setAttribute("download", exportName + ".json");
        document.body.appendChild(downloadAnchorNode); // required for firefox
        downloadAnchorNode.click();
        downloadAnchorNode.remove();
    }

    bundleWithNamespace(serializedBundle) {
        const bundle = JSON.parse(serializedBundle);

        return {
            ...bundle,
            RecordSetBundles: this.addNamespaceToBundle(bundle.RecordSetBundles),
            recordTypeMap: this.addNamespaceToRecordTypeMap(bundle.recordTypeMap)
        };
    }

    addNamespaceToRecordTypeMap(recordTypeMap) {
        const result = {};

        // eslint-disable-next-line guard-for-in
        for (const recordTypeId in recordTypeMap) {
            result[recordTypeId] = {
                ...recordTypeMap[recordTypeId],
                SobjectType: this.withPrefix(recordTypeMap[recordTypeId].SobjectType)
            };
        }

        return result;
    }

    addNamespaceToBundle(bundles) {
        const result = bundles.map((bundle) => {
            const ObjectType = this.withPrefix(bundle.ObjectType);
            const Records = bundle.Records.sort((record1, record2) => {
                return new Date(record1.CreatedDate) - new Date(record2.CreatedDate);
            }).map((record) => {
                const result = {};

                for (const field in record) {
                    if (this._blackListedFields[field]) {
                        delete result[field];
                    }
                    else if (field === 'attributes') {
                        result[field] = {
                            type: this.withPrefix(record[field].type),
                            url: this.urlWithPrefix(record[field].url)
                        };
                    } else {
                        const updatedFieldName = this.withPrefix(field);
                        result[updatedFieldName] = record[field];
                    }
                }

                return result;
            });

            return { Records, ObjectType };
        });

        return result;
    }

    urlWithPrefix(url) {
        return !url.includes('copado__') ? url.replace('sobjects/', 'sobjects/copado__') : url;
    }

    withPrefix(text) {
        return text.endsWith('__c') && !text.startsWith('copado__') ? 'copado__' + text : text;
    }

    showError(error) {
        const title = error?.body?.exceptionType || ERROR;
        const message = error?.body?.message || error?.message || error;

        this.showToast(title, message);
    }

    showToast(title, message, variant = 'error') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _search(self, queryConfig) {
        return search(queryConfig);
    }
}