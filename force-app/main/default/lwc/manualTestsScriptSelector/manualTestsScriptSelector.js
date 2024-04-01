import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { uniqueKey, handleAsyncError, flushPromises, reduceErrors, autoFormValidation, namespace } from 'c/copadocoreUtils';
import modal from '@salesforce/resourceUrl/ManualTestsScriptSelectorCss';
import { loadStyle } from 'lightning/platformResourceLoader';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';

import lookupSearch from '@salesforce/apex/CustomLookupComponentHelper.search';
import getRecentlyViewedTestScripts from '@salesforce/apex/ManualTestsScriptSelectorCtrl.getRecentlyViewedTestScripts';
import getSavedTestScriptsFor from '@salesforce/apex/ManualTestsScriptSelectorCtrl.getSavedTestScriptsFor';
import getSelectedScriptDetailsFor from '@salesforce/apex/ManualTestsScriptSelectorCtrl.getSelectedScriptDetailsFor';
import saveTestScriptSuitesFor from '@salesforce/apex/ManualTestsScriptSelectorCtrl.saveTestScriptSuitesFor';

import { labels, schema } from './constants';

export default class manualTestsScriptSelector extends LightningElement {
    @track modalOpen = false;
    @track isScriptListEmpty;
    @track testScripts = [];
    @track testScriptsBackup = [];

    recordId;
    isLoading = false;
    recentlyViewedUsers;
    labels = labels;

    _cssHiddenFormElement = 'slds-form-element script hidden';
    _cssVisibleFormElement = 'slds-form-element script';

    async connectedCallback() {
        await loadStyle(this, modal);
        this.isLoading = true;

        this.testScriptsBackup = await this._getData();
        this.testScripts = JSON.parse(JSON.stringify(this.testScriptsBackup));
        this.isScriptListEmpty = this.testScripts.length === 0 ? true : false;

        this.isLoading = false;
    }

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        if (pageReference && pageReference.state) {
            this.recordId = pageReference.attributes.recordId;
        }
    }

    @wire(getRecentlyViewedTestScripts)
    getRecentlyViewedTestScripts(result) {
        if (result) {
            this.recentlyViewedTestScripts = result.data;
        }
    }

    //PUBLIC

    async openModal() {
        this.modalOpen = true;
        if (this.testScripts.length === 0) {
            this.addScript();
        }
        // @Note: We need to flush promises for lookup to be available in next querySelector
        await flushPromises();

        this.testScripts.forEach(script => {
            const scriptLookup = this.template.querySelector(`c-lookup[data-scriptid="${script.id}"]`);

            if (scriptLookup) {
                scriptLookup.setDefaultResults(this.recentlyViewedTestScripts);
                if (script && script.testTitle) {
                    scriptLookup.selection = [
                        {
                            Id: script.id,
                            scriptRecordId: script.id,
                            sObjectType: script.sObjectType,
                            icon: 'standard:article',
                            title: script.testReference,
                            subtitle: script.testTitle
                        }
                    ];
                }
            }
        });
    }

    async handleChangeTestScript(event) {
        const scriptId = event.target.dataset.scriptid;
        const index = this.testScripts.findIndex(item => item.id === scriptId);
        const currentScript = this.testScripts.find(item => item.id === this.testScripts[index].id);

        const selectedValueInformation = event.target.getSelection().length ? event.target.getSelection()[0] : '';
        if (selectedValueInformation) {
            this.isLoading = true;

            let latestSearchElement;
            try {
                latestSearchElement = await this._getScriptDetails(selectedValueInformation.id);
                currentScript.cssClass = this._cssVisibleFormElement;
                this._cleanErrorOnLookup(scriptId);
            } catch (error) {
                this._showErrorOnLookup(scriptId, error);
            }

            if (latestSearchElement) {
                currentScript.testReference = latestSearchElement[0].testReference;
                currentScript.testTitle = latestSearchElement[0].testTitle;
                currentScript.testPrerequisites = latestSearchElement[0].testPrerequisites;
                currentScript.testExpectedResult = latestSearchElement[0].testExpectedResult;
                currentScript.testRisk = latestSearchElement[0].testRisk;
                currentScript.project = latestSearchElement[0].project;
                currentScript.scriptRecordId = selectedValueInformation.id;
                currentScript.scriptRecordUrl = '/' + selectedValueInformation.id;
                currentScript.suiteOrder = latestSearchElement[0].suiteOrder;
                currentScript.suiteScriptId = latestSearchElement[0].suiteScriptId;
                currentScript.steps = latestSearchElement[0].steps;
            }
            this.isLoading = false;
        } else {
            currentScript.testTitle = '';
            currentScript.testReference = '';
            currentScript.project = '';
            currentScript.steps = [];
        }
    }

    closeModal() {
        this.testScripts = JSON.parse(JSON.stringify(this.testScriptsBackup));
        this.modalOpen = false;
    }

    validateData() {
        if (this._lookupsEmpty()) {
            showToastError(this, { message: labels.COMPLETE_ALL_FIELDS });
        } else if (this._areScriptsDuplicated()) {
            showToastError(this, { message: labels.DUPLICATE_SCRIPTS });
        } else if (autoFormValidation(this.template, this)) {
            this._save();
        }
    }

    async addScript() {
        let newElement = {
            id: uniqueKey('script'),
            testScript: '',
            testTitle: '',
            project: '',
            steps: [],
            cssClass: this._cssHiddenFormElement
        };
        this.testScripts.push(newElement);

        // @Note: We need to flush promises for lookup to be available in next querySelector
        await flushPromises();

        const scriptLookup = this.template.querySelector(`c-lookup[data-scriptid="${newElement.id}"]`);
        if (scriptLookup) {
            scriptLookup.setDefaultResults(this.recentlyViewedTestScripts);
        }
    }

    deleteScript(event) {
        const testScriptId = event.target.dataset.scriptid;
        this.testScripts = this.testScripts.filter(o => o.id !== testScriptId);
        if (this.testScripts.length === 0) {
            this.addScript();
        }
    }

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._lookupSearch, {
            title: labels.ERROR_SEARCHING
        });

        const queryConfig = {
            searchField: `Name`,
            objectName: schema.TEST_SCRIPT.objectApiName,
            searchKey: event.detail.searchTerm,
            extraFilterType: `TestScriptTitleFilter`,
            filterFormattingParameters: [event.detail.searchTerm],
            additionalFields: [schema.SCRIPT_TITLE.fieldApiName]
        };

        const result = await safeSearch(this, {
            queryConfig,
            objectLabel: 'Test Script',
            iconName: 'standard:article',
            subtitleField: schema.SCRIPT_TITLE.fieldApiName
        });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }

    //PRIVATE

    async _save() {
        this.isLoading = true;
        try {
            await saveTestScriptSuitesFor({ testId: this.recordId, body: JSON.stringify(this._shapeDataToSave()) });
            this.testScriptsBackup = JSON.parse(JSON.stringify(this.testScripts));
            this.isScriptListEmpty = false;
            showToastSuccess(this, { message: labels.SCRIPT_SAVED });
        } catch (error) {
            showToastError(this, { message: labels.SCRIPT_SAVE_ERROR });
        }
        this.isLoading = false;
        this.modalOpen = false;
    }

    _shapeDataToSave() {
        let result = [];
        this.testScripts.forEach((item, index) => {
            result.push({
                testScriptId: item.scriptRecordId,
                order: index + 1,
                suiteScriptId: item.suiteScriptId
            });
        });
        return result;
    }

    _areScriptsDuplicated() {
        let result = false;

        let uniqueSet = {};
        this.testScripts.forEach(item => {
            if (uniqueSet[item.testReference]) {
                result = true;
            } else {
                uniqueSet[item.testReference] = item.testReference;
            }
        });

        return result;
    }

    _lookupsEmpty() {
        let result = false;

        this.testScripts.forEach(item => {
            if (!item.testReference) {
                result = true;
            }
        });

        return result;
    }

    async _getData() {
        this.isLoading = true;
        let result = [];
        try {
            const testScripts = await getSavedTestScriptsFor({ recordId: this.recordId });
            result = this._convertData(testScripts);
        } catch (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
        this.isLoading = false;
        return result;
    }

    _convertData(data) {
        let result = [];
        let scriptSteps = [];

        data.forEach(scriptItem => {
            const steps = this._prepareSteps(scriptSteps, scriptItem);
            result = this._prepareScript(result, scriptItem, steps);
        });
        result.sort((a, b) => a.suiteOrder - b.suiteOrder);
        return result;
    }

    _prepareSteps(scriptSteps, scriptItem) {
        scriptSteps = scriptItem[`${namespace}Script_Steps__r`];
        const result = [];

        if (scriptSteps) {
            scriptSteps.forEach(step => {
                result.push({
                    stepReference: step.Name,
                    action: step[schema.SCRIPT_STEP_ACTION_DESCRIPTION.fieldApiName],
                    expectedResult: step[schema.SCRIPT_STEP_EXPECTED_RESULT.fieldApiName],
                    guidanceNotes: step[schema.SCRIPT_STEP_GUIDANCE_NOTES.fieldApiName],
                    order: step[schema.SCRIPT_STEP_ORDER.fieldApiName],
                    url: '/' + step.Id
                });
            });
            result.sort((a, b) => a.order - b.order);
        }

        return result;
    }

    _prepareScript(result, scriptItem, steps) {
        result.push({
            id: uniqueKey('script'),
            scriptRecordId: scriptItem.Id,
            scriptRecordUrl: '/' + scriptItem.Id,
            testReference: scriptItem.Name,
            testTitle: scriptItem[schema.SCRIPT_TITLE.fieldApiName],
            testPrerequisites: scriptItem[schema.SCRIPT_PREREQUISITES.fieldApiName],
            testExpectedResult: scriptItem[schema.SCRIPT_EXPECTED_RESULT.fieldApiName],
            testRisk: scriptItem[schema.SCRIPT_RISK.fieldApiName],
            project: scriptItem[schema.SCRIPT_PROJECT.fieldApiName],
            suiteOrder: scriptItem[`${namespace}Test_Suite_Scripts__r`]
                ? scriptItem[`${namespace}Test_Suite_Scripts__r`][0][schema.SUITE_SCRIPT_ORDER.fieldApiName]
                : '',
            suiteScriptId: scriptItem[`${namespace}Test_Suite_Scripts__r`] ? scriptItem[`${namespace}Test_Suite_Scripts__r`][0].Id : null,
            steps: steps,
            cssClass: this._cssVisibleFormElement
        });

        return result;
    }

    async _getScriptDetails(scriptId) {
        const response = await getSelectedScriptDetailsFor({ scriptId, testId: this.recordId });
        return this._convertData(response);
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _lookupSearch(self, queryConfig) {
        return lookupSearch(queryConfig);
    }

    _showErrorOnLookup(scriptId, error) {
        const scriptLookup = this.template.querySelector(`c-lookup[data-scriptid="${scriptId}"]`);
        if (scriptLookup) {
            scriptLookup.errors = [{ id: uniqueKey('lookup-error'), message: reduceErrors(error) }];
        }
    }

    _cleanErrorOnLookup(scriptId) {
        const scriptLookup = this.template.querySelector(`c-lookup[data-scriptid="${scriptId}"]`);
        if (scriptLookup) {
            scriptLookup.errors = [];
        }
    }
}