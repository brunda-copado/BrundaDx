import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { showToastError } from 'c/copadocoreToastNotification';
import { handleAsyncError } from 'c/copadocoreUtils';

import search from '@salesforce/apex/CustomLookupComponentHelper.search';

import DATA_JSON_FIELD from '@salesforce/schema/Step__c.dataJson__c';
import NAME_FIELD from '@salesforce/schema/External_CI_Job__c.Name';

import EXTERNAL_CI_JOB from '@salesforce/label/c.EXTERNAL_CI_JOB';
import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';

export default class DeploymentStepsExternalCI extends LightningElement {
    label = {
        EXTERNAL_CI_JOB
    };

    @api stepId;

    selectedExternalCIJob;
    _originalSelectedExternalCIJobId;

    // This variables are used to reset edited step information to the original value if modal is closed
    _originalSelectedExternalCIJob;

    _lastResults;

    // If stepId changes to actually be another valid step Id, the wiredStep is called again
    // but if it is not actually an Id, then wiredStep is not called
    @wire(getRecord, { recordId: '$stepId', fields: DATA_JSON_FIELD })
    wiredStep(value) {
        const { data, error } = value;
        this.selectedExternalCIJob = this._originalSelectedExternalCIJob = undefined;
        if (data) {
            this.parseDataIntoVariables(data);
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
        }
    }

    parseDataIntoVariables(data) {
        const dataJsonValueObject = JSON.parse(getFieldValue(data, DATA_JSON_FIELD));
        this._originalSelectedExternalCIJobId = dataJsonValueObject.xciJobId;
    }

    // If _originalSelectedExternalCIJobId changes to actually be another valid External CI Job Id, the wiredOriginalExternalCIJob is called again
    // but if it is not actually an id, then it wiredOriginalExternalCIJob is not called
    @wire(getRecord, { recordId: '$_originalSelectedExternalCIJobId', fields: [NAME_FIELD] })
    wiredOriginalExternalCIJob(value) {
        const { data, error } = value;
        if (data) {
            this.selectedExternalCIJob = this._originalSelectedExternalCIJob = {
                Id: this._originalSelectedExternalCIJobId,
                Name: getFieldValue(data, NAME_FIELD)
            };
            const lookup = this.template.querySelector('c-lookup');
            if (lookup) {
                lookup.selection = [
                    {
                        Id: this.selectedExternalCIJob.Id,
                        sObjectType: 'External CI Job',
                        icon: 'standard:choice',
                        title: this.selectedExternalCIJob.Name,
                        subtitle: 'External CI Job • ' + this.selectedExternalCIJob.Name
                    }
                ];
            }
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
            this.selectedExternalCIJob = undefined;
        }
    }

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._search, {
            title: Error_Searching_Records
        });

        const queryConfig = {
            searchField: 'Name',
            objectName: 'External_CI_Job__c',
            searchKey: event.detail.searchTerm,
            extraFilterType: undefined,
            filterFormattingParameters: undefined
        };

        this._lastResults = await safeSearch(this, { queryConfig, objectLabel: 'External CI Job' });

        if (this._lastResults) {
            lookupElement.setSearchResults(this._lastResults);
        }
    }

    getSelectedId(lookupData) {
        if (lookupData.detail.length) {
            this.selectedExternalCIJob = {
                Id: lookupData.detail[0],
                Name: this._lastResults.find((el) => el.id === lookupData.detail[0]).title
            };
        } else {
            this.selectedExternalCIJob = undefined;
        }
    }

    @api
    getFieldsToSave() {
        const fields = {};
        fields[DATA_JSON_FIELD.fieldApiName] = JSON.stringify(this.generateDataJasonFieldValue());
        return fields;
    }

    generateDataJasonFieldValue() {
        return {
            xciJobId: this.selectedExternalCIJob ? this.selectedExternalCIJob.Id : ''
        };
    }

    @api
    restoreOriginalValues() {
        this.selectedExternalCIJob = this._originalSelectedExternalCIJob;
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _search(self, queryConfig) {
        return search(queryConfig);
    }
}