import { LightningElement, api } from 'lwc';

import retrieveData from '@salesforce/apex/RunManualTestsController.retrieveTestRuns';
import saveData from '@salesforce/apex/RunManualTestsController.saveTestRuns';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors, namespace } from 'c/copadocoreUtils';

import standardModal from '@salesforce/resourceUrl/StandardModal';
import testExecutionModal from '@salesforce/resourceUrl/ManualTestExecutionModal';
import testExecutionModalWithError from '@salesforce/resourceUrl/ManualTestExecutionModalError';
import { loadStyle } from 'lightning/platformResourceLoader';

import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { labels, schema } from './constants';

const RESULT_LENGTH = 32767;
const VARIANT_BRAND = 'brand';
const VARIANT_NEUTRAL = 'neutral';

export default class RunManualTest extends LightningElement {
    @api recordId;
    @api availableActions = [];

    isScriptListEmpty;
    testScripts = [];

    labels = labels;
    resultLength = RESULT_LENGTH;
    variantBrand = VARIANT_BRAND;
    variantNeutral = VARIANT_NEUTRAL;
    isLoading = false;
    isTestScriptWithoutSteps;
    saveDisabled;

    async connectedCallback() {
        this.isLoading = true;

        this.testScripts = await this._getData();
        this._runValidations(this.testScripts);
        await this._setStyles(this.isTestScriptWithoutSteps);

        this.isLoading = false;
    }

    async disconnectedCallback() {
        await loadStyle(this, standardModal);
    }

    // PUBLIC

    handleCancel() {
        if (this.availableActions.find(action => action === 'FINISH')) {
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        }
    }

    handleSubmit() {
        if (this._areStepsExecuted()) {
            this._save();
        } else {
            showToastError(this, { message: labels.EXECUTE_STEPS_VALIDATION_ERROR });
        }
    }

    actualResultFieldChangeHandler(event) {
        const scriptIndex = this._getScriptIndex(event);
        const stepIndex = this._getStepIndex(event, scriptIndex);
        this.testScripts[scriptIndex].testRunSteps[stepIndex].actualResult = event.target.value;
    }

    statusFieldChangeHandler(event) {
        event.target.variant = event.target.variant === this.variantBrand ? this.variantNeutral : this.variantBrand;
        this._updateStepStatus(event);

        let childElements = event.target.parentNode.childNodes;
        childElements.forEach(element => {
            if (element.label !== event.target.label) {
                element.variant = this.variantNeutral;
            }
        });
    }

    // PRIVATE

    async _setStyles(isError) {
        const styleToLoad = isError ? testExecutionModalWithError : testExecutionModal;
        await loadStyle(this, styleToLoad);

        if (isError) {
            this.template.querySelector("div[data-name=runModal]").style.height = '200px';
        }
    }

    _runValidations(testScripts) {
        this.isScriptListEmpty = testScripts.length === 0 ? true : false;
        this.isTestScriptWithoutSteps = testScripts.some((testScript) => (!testScript.testRunSteps || testScript.testRunSteps.length === 0));

        this.saveDisabled = this.isScriptListEmpty || this.isTestScriptWithoutSteps;
    }

    async _save() {
        this.isLoading = true;
        try {
            await saveData({ testRunRows: JSON.stringify(this._shapeDataToSave()), recordId: this.recordId });
            this.isLoading = false;
            showToastSuccess(this, { message: labels.SAVE_SUCCESS });
            if (this.availableActions.find(action => action === 'FINISH')) {
                const navigateFinishEvent = new FlowNavigationFinishEvent();
                this.dispatchEvent(navigateFinishEvent);
            }
        } catch (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    _areStepsExecuted() {
        let result = false;

        this.testScripts.forEach(item => {
            item.testRunSteps.forEach(step => {
                if (step.status !== '') {
                    result = true;
                }
            });
        });

        return result;
    }

    _shapeDataToSave() {
        let result = [];
        this.testScripts.forEach(item => {
            item.testRunSteps.forEach(step => {
                result.push({
                    scriptId: item.id,
                    scriptStepId: step.stepId,
                    status: step.status,
                    actualResult: step.actualResult,
                    testRunId: item.testRunId,
                    testRunStepId: step.testRunStepId
                });
            });
        });
        return result;
    }

    _convertData(data) {
        let result = [];
        let scriptSteps = [];

        data.forEach(scriptItem => {
            const steps = this._prepareSteps(scriptSteps, scriptItem.testScript, scriptItem.testRunSteps);
            result = this._prepareScript(result, scriptItem, steps);
        });
        result.sort((a, b) => a.suiteOrder - b.suiteOrder);
        return result;
    }

    _prepareSteps(scriptSteps, scriptItem, testRunSteps) {
        scriptSteps = scriptItem[`${namespace}Script_Steps__r`];
        const result = [];

        if (scriptSteps) {
            scriptSteps.forEach(step => {
                const runStep = this._getTestRunStepFor(testRunSteps, step.Id);
                const runStepStatus = this._adjustTestRunStepStatus(runStep);

                result.push({
                    stepId: step.Id,
                    url: '/' + step.Id,
                    stepName: step.Name,
                    actionDescription: step[schema.SCRIPT_STEP_ACTION_DESCRIPTION.fieldApiName],
                    expectedResult: step[schema.SCRIPT_STEP_EXPECTED_RESULT.fieldApiName],
                    guidanceNotes: step[schema.SCRIPT_STEP_GUIDANCE_NOTES.fieldApiName],
                    order: step[schema.SCRIPT_STEP_ORDER.fieldApiName],
                    passedStatusVariant: runStepStatus === 'Passed' ? this.variantBrand : this.variantNeutral,
                    failedStatusVariant: runStepStatus === 'Failed' ? this.variantBrand : this.variantNeutral,
                    testRunStepId: runStep ? runStep.Id : null,
                    status: this._adjustTestRunStepStatus(runStep),
                    actualResult: runStep[schema.RUN_STEP_ACTUAL_RESULT.fieldApiName] ? runStep[schema.RUN_STEP_ACTUAL_RESULT.fieldApiName] : ''
                });
            });
            result.sort((a, b) => a.order - b.order);
        }
        return result;
    }

    _getTestRunStepFor(testRunSteps, stepId) {
        return testRunSteps.find(item => item[schema.RUN_STEP_SCRIPT_STEP.fieldApiName] === stepId);
    }

    _adjustTestRunStepStatus(runStep) {
        return !runStep[schema.RUN_STEP_STATUS.fieldApiName]
            ? ''
            : runStep[schema.RUN_STEP_STATUS.fieldApiName] === 'Passed with comments'
            ? 'Passed'
            : runStep[schema.RUN_STEP_STATUS.fieldApiName];
    }

    _prepareScript(result, scriptItem, steps) {
        result.push({
            id: scriptItem.testScript.Id,
            name: scriptItem.testScript.Name,
            title: scriptItem.testScript[schema.SCRIPT_TITLE.fieldApiName],
            testRunId: scriptItem.testRunId ? scriptItem.testRunId : null,
            testRunSteps: steps,
            suiteOrder: scriptItem.testScript[`${namespace}Test_Suite_Scripts__r`]
                ? scriptItem.testScript[`${namespace}Test_Suite_Scripts__r`][0][schema.SUITE_SCRIPT_ORDER.fieldApiName]
                : ''
        });

        return result;
    }

    async _getData() {
        let result = [];
        try {
            const response = await retrieveData({ recordId: this.recordId });
            result = this._convertData(response);
        } catch (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
        return result;
    }

    _updateStepStatus(event) {
        const scriptIndex = this._getScriptIndex(event);
        const stepIndex = this._getStepIndex(event, scriptIndex);

        if (event.target.label === labels.FAILED) {
            this.testScripts[scriptIndex].testRunSteps[stepIndex].failedStatusVariant = event.target.variant;
            this.testScripts[scriptIndex].testRunSteps[stepIndex].status = labels.FAILED;
        } else {
            this.testScripts[scriptIndex].testRunSteps[stepIndex].passedStatusVariant = event.target.variant;
            this.testScripts[scriptIndex].testRunSteps[stepIndex].status = labels.PASSED;
        }
    }

    _getScriptIndex(event) {
        const scriptId = event.target.dataset.scriptid;
        const scriptIndex = this.testScripts.findIndex(item => item.id === scriptId);
        return scriptIndex;
    }

    _getStepIndex(event, scriptIndex) {
        const stepId = event.target.dataset.stepid;
        const stepIndex = this.testScripts[scriptIndex].testRunSteps.findIndex(item => item.stepId === stepId);
        return stepIndex;
    }
}