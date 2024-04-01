import { LightningElement, api, wire } from 'lwc';
import { uniqueKey, handleAsyncError, reduceErrors } from 'c/copadocoreUtils';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { refreshApex } from '@salesforce/apex';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';

import lookupSearch from '@salesforce/apex/CustomLookupComponentHelper.search';
import { label, schema, copadoCRTExtensionTool } from './constants';

export default class SelectTestsForAutomation extends LightningElement {
    @api recordId;

    label = label;
    _selectedTests = [];
    _storedTests = [];
    _selectedTestsJson;
    _showSpinner;

    automation;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.QUALITY_GATE_DATA_JSON_FIELD] })
    wiredAutomation(result) {
        this.automation = result;
        const { data, error } = result;
        if (data) {
            const dataJson = getFieldValue(data, schema.QUALITY_GATE_DATA_JSON_FIELD);
            if (dataJson) {
                const testsWrapper = JSON.parse(dataJson);
                if (testsWrapper.testIds && testsWrapper.testIds.length > 0) {
                    const multipleTestsInput = this.template.querySelector('[data-id="multipleTests"]');
                    let selections = [];
                    for (let i = 0; i < testsWrapper.testIds.length; i++) {
                        selections.push({ id: testsWrapper.testIds[i], title: testsWrapper.testNames[i], icon: 'standard:choice' });
                    }
                    multipleTestsInput.selection = selections;
                    this._selectedTests = this._storedTests = selections;
                }
            }
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    @api
    get showSpinner() {
        return this._showSpinner;
    }
    set showSpinner(value) {
        this._showSpinner = value;
    }

    get saveDisabled() {
        return this._selectedTests.length < 1 || JSON.stringify(this._storedTests) === JSON.stringify(this._selectedTests);
    }

    // PUBLIC

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._lookupSearch, {
            title: label.Error_Searching_Records
        });

        const queryConfig = {
            searchField: `Name`,
            objectName: schema.TEST_OBJECT.objectApiName,
            searchKey: event.detail.searchTerm,
            filterFormattingParameters: [event.detail.searchTerm],
            extraFilterType: 'CrtTest',
            additionalFields: [schema.TEST_TOOL_CONFIGURATION_FIELD.fieldApiName, schema.TEST_TOOL_FIELD.fieldApiName]
        };

        const result = await safeSearch(this, {
            queryConfig,
            objectLabel: label.TEST,
            subtitleField: schema.TEST_TOOL_FIELD.fieldApiName
        });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }

    handleLookupSelectionChange(event) {
        this._selectedTests = event.target.getSelection();

        if (this._selectedTests.length > 0) {
            const jsonElement = {
                testIds: [],
                testNames: []
            };
            this._selectedTests.forEach(info => {
                jsonElement.testIds.push(info.id);
                jsonElement.testNames.push(info.title);
            });
            this._selectedTestsJson = JSON.stringify(jsonElement);
        } else {
            event.target.errors = [];
        }
    }

    handleSave() {
        this._showSpinner = true;
        const fields = {};
        fields[schema.QUALITY_GATE_ID_FIELD.fieldApiName] = this.recordId;
        fields[schema.QUALITY_GATE_DATA_JSON_FIELD.fieldApiName] = this._selectedTestsJson;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                showToastSuccess(this, { message: label.RECORDS_UPDATED_SUCCESSFULLY });
                return refreshApex(this.automation);
            })
            .catch(error => {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            });
        this._showSpinner = false;
    }

    // PRIVATE

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _lookupSearch(self, queryConfig) {
        return lookupSearch(queryConfig);
    }
}