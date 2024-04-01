import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { publish, MessageContext } from 'lightning/messageService';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors, formatLabel } from 'c/copadocoreUtils';

import getData from '@salesforce/apex/AutomationRuleEvaluationScopeCtrl.getData';
import isAutomationRuleAccessible from '@salesforce/apex/AutomationRuleEvaluationScopeCtrl.isAutomationRuleAccessible';

import { label, schema, fields, scopeModeOptions, ENVIRONMENTS_VALUE, STAGES_VALUE, MAX_SELECTED } from './constants';
import { createStageOptions, createEnvironmentOptions, createEnvironmentOptionsForStages, isTriggerValidationError } from './utils';

export default class AutomationRuleEvaluationScope extends LightningElement {
    @api recordId;

    label = label;
    scopeModeOptions = scopeModeOptions;

    readOnly = true;
    isLoading = true;
    isAccessible = false;

    scopeMode = STAGES_VALUE;

    stageLabel;
    stageHelpText;
    environmentLabel;
    environmentHelpText;
    excludedEnvironmentsLabel;
    excludedEnvironmentsHelpText;

    stageOptions = [];
    environmentOptions = [];
    selectedStageOptions = [];
    selectedEnvironmentOptions = [];

    _wiredData;
    _currentStages;
    _currentEnvironments;
    _currentExcludedEnvironments;
    _stagesById;
    _environmentsById;
    _userHasPermission = false;
    @track _automationRule = {};

    get triggerScopeLabel() {
        return formatLabel(label.TRIGGER_SCOPE_LABEL, [
            this._automationRule[schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName],
            this._automationRule[schema.AUTOMATION_RULE_SOURCE_ACTION_STATUS.fieldApiName]
        ]);
    }

    get showIllustration() {
        return this.nothingConfigured && !this.isEditMode;
    }

    get showCurrentConfiguration() {
        return !this.showIllustration && !this.isEditMode;
    }

    get showEditButton() {
        return this.showCurrentConfiguration && !this.nothingConfigured && this._userHasPermission && !this.active;
    }

    get showConfigureScopeButton() {
        return this.showIllustration && this.nothingConfigured && this._userHasPermission && !this.active;
    }

    get isEditMode() {
        return !this.readOnly;
    }

    get isStageScopeMode() {
        return this.scopeMode === STAGES_VALUE;
    }

    get isScopeSelected() {
        return !!this.scopeMode;
    }

    get excludedEnvironmentOptions() {
        return this.environmentOptions.filter(option => this.selectedEnvironmentOptions.indexOf(option.value) === -1);
    }

    get minimumSelectedEnvironments() {
        return this.isStageScopeMode ? Math.min(0, this.environmentOptions.length - MAX_SELECTED) : 0;
    }

    get maximumSelectedEnvironments() {
        return !this.isStageScopeMode ? MAX_SELECTED : 999;
    }

    get nothingConfigured() {
        return !this._currentStages && !this._currentEnvironments;
    }

    get environmentDisabled() {
        return this.isStageScopeMode && this.selectedStageOptions.length === 0;
    }

    get currentStageNames() {
        if (!this._currentStages) {
            return '';
        }
        return this._currentStages
            .split(',')
            .map(stageId => {
                return this._stagesById[stageId] ? this._stagesById[stageId].stage[schema.STAGE_DISPLAY_NAME.fieldApiName] : stageId;
            })
            .join(', ');
    }

    get currentEnvironmentNames() {
        if (!this._currentEnvironments) {
            return '';
        }
        return this._currentEnvironments
            .split(',')
            .map(environmentId => {
                return this._environmentsById[environmentId] ? this._environmentsById[environmentId].Name : environmentId;
            })
            .join(', ');
    }

    get currentExcludedEnvironmentNames() {
        if (!this._currentExcludedEnvironments) {
            return '';
        }
        return this._currentExcludedEnvironments
            .split(',')
            .map(environmentId => {
                return this._environmentsById[environmentId] ? this._environmentsById[environmentId].Name : environmentId;
            })
            .join(', ');
    }

    get active() {
        return this._automationRule[schema.AUTOMATION_RULE_ACTIVE.fieldApiName];
    }

    get automationRuleIsConfigured() {
        return (
            this._automationRule[schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName] &&
            this._automationRule[schema.AUTOMATION_RULE_AUTOMATION_CONNECTOR.fieldApiName]
        );
    }

    async connectedCallback() {
        try {
            this.isAccessible = await isAutomationRuleAccessible();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this.messageAlert(errorMessage, 'error');
        }
    }

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    getFieldValues({ data }) {
        if (data) {
            fields.forEach(field => {
                this._automationRule[field.fieldApiName] = getFieldValue(data, field);
            });
        }
    }

    @wire(getData, { recordId: '$recordId' })
    getData(result) {
        this._wiredData = result;
        const { data, error } = result;
        if (data) {
            this._loadData(data);
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            this.messageAlert(errorMessage, 'error');
        }
        this.isLoading = false;
    }

    @wire(getObjectInfo, { objectApiName: schema.AUTOMATION_RULE_OBJECT })
    getAutomationRuleInfo(result) {
        const { data, error } = result;
        if (data) {
            const automationRuleStage = data.fields[schema.AUTOMATION_RULE_STAGE.fieldApiName];
            const automationRuleEnvironment = data.fields[schema.AUTOMATION_RULE_ENVIRONMENT.fieldApiName];
            const automationRuleExcludedEnvironment = data.fields[schema.AUTOMATION_RULE_EXCLUDED_ENVIRONMENTS.fieldApiName];

            this.stageLabel = automationRuleStage ? automationRuleStage.label : '';
            this.stageHelpText = automationRuleStage ? automationRuleStage.inlineHelpText : '';
            this.environmentLabel = automationRuleEnvironment ? automationRuleEnvironment.label : '';
            this.environmentHelpText = automationRuleEnvironment ? automationRuleEnvironment.inlineHelpText : '';
            this.excludedEnvironmentsLabel = automationRuleExcludedEnvironment ? automationRuleExcludedEnvironment.label : '';
            this.excludedEnvironmentsHelpText = automationRuleExcludedEnvironment ? automationRuleExcludedEnvironment.inlineHelpText : '';
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            this.messageAlert(errorMessage, 'error');
        }
    }

    handleEdit() {
        if (!this.automationRuleIsConfigured) {
            this.template.querySelector('c-copadocore-modal').show();
            return;
        }
        this.readOnly = false;
    }

    handleChangeScopeMode(event) {
        this._changeScope(event.target.value);
    }

    handleChangeSelectedStages(event) {
        this.selectedStageOptions = event.detail.value;
        let environmentOptionsForStages = createEnvironmentOptionsForStages(this.selectedStageOptions, this._stagesById);
        this._setEnvironmentOptions(environmentOptionsForStages);
    }

    handleChangeSelectedEnvironments(event) {
        this.selectedEnvironmentOptions = event.detail.value;
    }

    handleClickClear() {
        const event = { detail: { value: [] } };
        this.handleChangeSelectedEnvironments(event);
        this.handleChangeSelectedStages(event);
    }

    handleCancel() {
        this.readOnly = true;
        this._loadData(this._wiredData.data);
    }

    async handleSave() {
        this.isLoading = true;

        try {
            const record = this._getUpdatedRecord();
            await updateRecord(record);
            await refreshApex(this._wiredData);
            this.readOnly = true;
        } catch (error) {
            let errorMessage = reduceErrors(error);
            const validationErrorMessage = isTriggerValidationError(error);
            if (validationErrorMessage) {
                errorMessage = validationErrorMessage;
            }
            showToastError(this, { message: errorMessage });
        }

        this.isLoading = false;
    }

    // PRIVATE

    _loadData(data) {
        this._currentStages = data.currentStages;
        this._currentEnvironments = data.currentEnvironments;
        this._currentExcludedEnvironments = data.currentExcludedEnvironments;
        this._stagesById = data.stagesById;
        this._environmentsById = data.environmentsById;
        this._userHasPermission = data.userHasPermission;

        this._changeScope(this._currentEnvironments ? ENVIRONMENTS_VALUE : STAGES_VALUE);
    }

    _getUpdatedRecord() {
        const stageFieldValue = this.isStageScopeMode && this.selectedStageOptions.length > 0 ? this.selectedStageOptions.join(',') : null;
        const environmentFieldValue =
            !this.isStageScopeMode && this.selectedEnvironmentOptions.length > 0 ? this.selectedEnvironmentOptions.join(',') : null;
        const excludedEnvironmentFieldValue =
            this.isStageScopeMode && this.excludedEnvironmentOptions.length > 0
                ? this.excludedEnvironmentOptions.map(option => option.value).join(',')
                : null;

        const record = {
            fields: {
                Id: this.recordId,
                [schema.AUTOMATION_RULE_STAGE.fieldApiName]: stageFieldValue,
                [schema.AUTOMATION_RULE_ENVIRONMENT.fieldApiName]: environmentFieldValue,
                [schema.AUTOMATION_RULE_EXCLUDED_ENVIRONMENTS.fieldApiName]: excludedEnvironmentFieldValue
            }
        };
        return record;
    }

    _changeScope(scope) {
        this.scopeMode = scope;
        this._createOptions();
    }

    _createOptions() {
        this.stageOptions = [];
        this.selectedStageOptions = [];
        this.environmentOptions = [];
        this.selectedEnvironmentOptions = [];

        this.stageOptions = createStageOptions(this._stagesById);
        this.selectedStageOptions = this._currentStages ? this._currentStages.split(',') : [];

        switch (this.scopeMode) {
            case STAGES_VALUE: {
                if (this.selectedStageOptions.length > 0) {
                    let environmentOptionsForStages = createEnvironmentOptionsForStages(this.selectedStageOptions, this._stagesById);
                    this._setEnvironmentOptions(environmentOptionsForStages);
                }
                break;
            }
            case ENVIRONMENTS_VALUE:
                this.environmentOptions = createEnvironmentOptions(this._environmentsById);
                this.selectedEnvironmentOptions = this._currentEnvironments ? this._currentEnvironments.split(',') : [];
                break;
            default:
                break;
        }
    }

    _setEnvironmentOptions(environmentOptionsForStages) {
        const excludedEnvironments = this.excludedEnvironmentOptions
            .map(option => option.value)
            .concat(this._currentExcludedEnvironments ? this._currentExcludedEnvironments.split(',') : []);
        this.environmentOptions = environmentOptionsForStages;
        this.selectedEnvironmentOptions = environmentOptionsForStages
            .filter(option => excludedEnvironments.indexOf(option.value) === -1)
            .map(option => option.value);
    }

    messageAlert(message, variant) {
        const dismissible = true;
        const communicationId = 'automationRulePageAlerts';
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    handleCloseModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }
}