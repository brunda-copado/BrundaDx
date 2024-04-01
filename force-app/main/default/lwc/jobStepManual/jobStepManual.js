import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';

import { showToastError } from 'c/copadocoreToastNotification';
import { autoFormValidation, handleAsyncError, reduceErrors } from 'c/copadocoreUtils';

import search from '@salesforce/apex/CustomLookupComponentHelper.search';
import getStagesAndEnvironments from '@salesforce/apex/ScopeCtrl.getData';

import {
    constant,
    label,
    schema,
    performAtOptions,
    scopeModeOptions,
    PERFORM_AT_OPTION_VALUES,
    SCOPE_MODE_OPTION_VALUES,
    PARAMETERS
} from './constants';

export default class JobStepManual extends LightningElement {
    label = label;
    schema = schema;
    constant = constant;

    @api recordId;
    @api readOnly;
    @api editParameterValuesOnly;
    @api set configJson(value) {
        this._configJson = value;
    }
    get configJson() {
        return this._configJson;
    }
    _configJson;
    @api set isReadOnly(value) {
        this._readOnly = value;
    }
    get isReadOnly() {
        return this._readOnly;
    }
    _readOnly;

    _parentObjectApiName;
    _parentRecordId;
    _jobTemplateFieldValue;
    _jobExecutionFieldValue;

    selectedUserId;
    userName;
    performAtOptions = performAtOptions;
    performAtValue = [];
    taskDescription;
    taskComment;
    executionSequence;
    disableForBackPromotions = false;
    scopeMode = SCOPE_MODE_OPTION_VALUES.STAGES_VALUE;
    scopeModeOptions = scopeModeOptions;
    environmentOptions = [];
    selectedEnvironments = [];
    stageOptions = [];
    selectedStages = [];

    _stagesById;
    _environmentsById;
    _wiredStep;

    get isJobTemplate() {
        return this._parentObjectApiName === schema.JOB_TEMPLATE_OBJECT.objectApiName || !!this._jobTemplateFieldValue;
    }

    get isJobExecution() {
        return this._parentObjectApiName === schema.JOB_EXECUTION_OBJECT.objectApiName || !!this._jobExecutionFieldValue;
    }

    get showDisableOption() {
        return !this.isJobTemplate;
    }

    get completeInSourceChecked() {
        return this.performAtValue.includes(PERFORM_AT_OPTION_VALUES.SOURCE);
    }

    get completeInDestinationChecked() {
        return this.performAtValue.includes(PERFORM_AT_OPTION_VALUES.DESTINATION);
    }

    get hasParameters() {
        return this.parameters?.length > 0;
    }

    get fullEditMode() {
        return !this.isReadOnly && !this.editParameterValuesOnly;
    }

    get userDetailLink() {
        return '/' + this.selectedUserId;
    }

    get isStageScopeMode() {
        return this.scopeMode === SCOPE_MODE_OPTION_VALUES.STAGES_VALUE;
    }

    get isEnvironmentScopeMode() {
        return this.scopeMode === SCOPE_MODE_OPTION_VALUES.ENVIRONMENTS_VALUE;
    }

    get selectedEnvironmentNames() {
        if (!this.selectedEnvironments || !this._environmentsById) {
            return '';
        }
        return this.selectedEnvironments
            .map(environmentId => {
                return this._environmentsById[environmentId] ? this._environmentsById[environmentId].Name : environmentId;
            })
            .join(', ');
    }

    get selectedStageNames() {
        if (!this.selectedStages || !this._stagesById) {
            return '';
        }
        return this.selectedStages
            .map(stageId => {
                return this._stagesById[stageId] ? this._stagesById[stageId].stage[schema.STAGE_DISPLAY_NAME.fieldApiName] : stageId;
            })
            .join(', ');
    }

    @api
    getAutoFormValidation() {
        if (!this.selectedUserId) {
            return false;
        }
        return autoFormValidation(this.template, this);
    }

    @api
    getConfig() {
        return this._generateDataJsonFieldValue();
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            schema.DATA_JSON_FIELD,
            schema.JOBSTEP_JOB_TEMPLATE_FIELD,
            schema.JOBSTEP_JOB_EXECUTION_FIELD,
            schema.RESULT_DATA_JSON_FIELD,
            schema.JOBSTEP_EXECUTION_SEQUENCE_FIELD
        ]
    })
    wiredStep(value) {
        this._wiredStep = value;
        const { data, error } = value;

        if (data) {
            this._configJson = getFieldValue(data, schema.DATA_JSON_FIELD);
            this.taskComment = getFieldValue(data, schema.RESULT_DATA_JSON_FIELD);
            this.executionSequence = getFieldValue(data, schema.JOBSTEP_EXECUTION_SEQUENCE_FIELD);
            this._jobTemplateFieldValue = getFieldValue(data, schema.JOBSTEP_JOB_TEMPLATE_FIELD);
            this._jobExecutionFieldValue = getFieldValue(data, schema.JOBSTEP_JOB_EXECUTION_FIELD);
            this._parseData();
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    @wire(getRecord, {
        recordId: '$selectedUserId',
        fields: [schema.NAME_FIELD, schema.EMAIL_FIELD]
    })
    wiredUser(value) {
        const { data, error } = value;
        if (data) {
            const user = {
                Id: this.selectedUserId,
                Name: getFieldValue(data, schema.NAME_FIELD),
                Email: getFieldValue(data, schema.EMAIL_FIELD)
            };

            this.userName = user.Name;
            this._initLookup(user);
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
            this.selectedFunction = undefined;
        }
    }

    @wire(CurrentPageReference)
    async getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this._parentObjectApiName = currentPageReference.attributes.objectApiName;
            this._parentRecordId = currentPageReference.attributes.recordId;
            if (this.showDisableOption) {
                const data = await getStagesAndEnvironments({ recordId: this._parentRecordId });
                this._stagesById = data.stagesById;
                this._environmentsById = data.environmentsById;
                this.scopeModeOptions =
                    Object.keys(this._stagesById).length === 0
                        ? scopeModeOptions.filter(option => option.value !== SCOPE_MODE_OPTION_VALUES.STAGES_VALUE)
                        : scopeModeOptions;
                this.scopeMode =
                    this.selectedStages.length > 0 || this.selectedEnvironments.length === 0
                        ? SCOPE_MODE_OPTION_VALUES.STAGES_VALUE
                        : SCOPE_MODE_OPTION_VALUES.ENVIRONMENTS_VALUE;
                if (!this.isReadOnly) {
                    this._createStageEnvironmentOptions();
                }
            }
        }
    }

    connectedCallback() {
        this._parseData();
    }

    disconnectedCallback() {
        refreshApex(this._wiredStep);
    }

    handleChangeUser(lookupData) {
        this.selectedUserId = lookupData.detail.length > 0 ? lookupData.detail[0] : undefined;
    }

    handleDescriptionChange(event) {
        this.taskDescription = event.target.value;
    }

    handleChangePerformAt(event) {
        this.performAtValue = event.detail.value;
    }

    handleChangeDisableForBackPromotions(event) {
        this.disableForBackPromotions = event.target.checked;
    }

    handleChangeScopeMode(event) {
        this.scopeMode = event.detail.value;
        this._createStageEnvironmentOptions();
    }

    handleChangeEnvironment(event) {
        this.selectedEnvironments = event.detail.value;
    }

    handleChangeStage(event) {
        this.selectedStages = event.detail.value;
    }

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._search, {
            title: label.Error_Searching_Records
        });

        const queryConfig = {
            searchField: 'Name',
            objectName: 'User',
            searchKey: event.detail.searchTerm,
            extraFilterType: 'ActiveUserFilter',
            filterFormattingParameters: undefined
        };

        const result = await safeSearch(this, { queryConfig, objectLabel: 'User', iconName: 'standard:user' });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }

    _parseData() {
        if (this.configJson) {
            const config = JSON.parse(this.configJson);

            if (config.instructions) {
                this.taskDescription = config.instructions;
            }
            if (config.parameters) {
                this._parseParameters(config.parameters);
            }
        }
        if (!this.selectedUserId) {
            this.selectedUserId = constant.CURRENT_USER_ID;
        }
    }

    _parseParameters(taskParameters) {
        taskParameters.forEach(parameter => {
            if (parameter.name === PARAMETERS.ASSIGNEE_ID) {
                this.selectedUserId = parameter.value;
            } else if (parameter.name === PARAMETERS.PERFORM_AT_SOURCE && parameter.value === 'true') {
                this.performAtValue = [...this.performAtValue, PERFORM_AT_OPTION_VALUES.SOURCE];
            } else if (parameter.name === PARAMETERS.PERFORM_AT_DESTINATION && parameter.value === 'true') {
                this.performAtValue = [...this.performAtValue, PERFORM_AT_OPTION_VALUES.DESTINATION];
            } else if (parameter.name === PARAMETERS.DISABLE_FOR_BACK_PROMOTIONS) {
                this.disableForBackPromotions = parameter.value === 'true';
            } else if (parameter.name === PARAMETERS.DISABLED_STAGES) {
                this.selectedStages = JSON.parse(parameter.value);
            } else if (parameter.name === PARAMETERS.DISABLED_ENVIRONMENTS) {
                this.selectedEnvironments = JSON.parse(parameter.value);
            }
        });
    }

    _initLookup(user) {
        const lookup = this.template.querySelector('c-lookup');

        if (lookup) {
            lookup.selection = [
                {
                    Id: user.Id,
                    sObjectType: 'User',
                    icon: 'standard:user',
                    title: user.Name,
                    subtitle: label.COPADO_ORG_SETUP_ORG_USERNAME + user.Email
                }
            ];
        }
    }

    _generateDataJsonFieldValue() {
        return {
            type: 'Manual',
            configJson: {
                instructions: this.taskDescription,
                parameters: [
                    { name: PARAMETERS.ASSIGNEE_ID, value: this.selectedUserId },
                    { name: PARAMETERS.ASSIGNEE_NAME, value: this.userName },
                    { name: PARAMETERS.PERFORM_AT_SOURCE, value: this.completeInSourceChecked.toString() },
                    { name: PARAMETERS.PERFORM_AT_DESTINATION, value: this.completeInDestinationChecked.toString() },
                    { name: PARAMETERS.DISABLE_FOR_BACK_PROMOTIONS, value: this.disableForBackPromotions.toString() },
                    { name: PARAMETERS.DISABLED_STAGES, value: JSON.stringify(this.selectedStages) },
                    { name: PARAMETERS.DISABLED_ENVIRONMENTS, value: JSON.stringify(this.selectedEnvironments) }
                ]
            }
        };
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _search(self, queryConfig) {
        return search(queryConfig);
    }

    _createStageEnvironmentOptions() {
        switch (this.scopeMode) {
            case SCOPE_MODE_OPTION_VALUES.STAGES_VALUE: {
                this.stageOptions = this._createStageOptions(this._stagesById);
                this.selectedStages = this.selectedStages && this.selectedStages.length > 0 ? this.selectedStages : [];
                this.environmentOptions = [];
                this.selectedEnvironments = [];
                break;
            }
            case SCOPE_MODE_OPTION_VALUES.ENVIRONMENTS_VALUE:
                this.stageOptions = [];
                this.selectedStages = [];
                this.environmentOptions = this._createEnvironmentOptions(this._environmentsById);
                this.selectedEnvironments = this.selectedEnvironments && this.selectedEnvironments.length > 0 ? this.selectedEnvironments : [];
                break;
            default:
                break;
        }
    }

    _createStageOptions(stagesById) {
        let result = [];
        for (const [id, stage] of Object.entries(stagesById)) {
            result.push({ label: stage.stage[schema.STAGE_DISPLAY_NAME.fieldApiName], value: id });
        }
        return result;
    }

    _createEnvironmentOptions(environmentsById, stageName) {
        let result = [];
        for (const [id, environment] of Object.entries(environmentsById)) {
            let environmentLabel = environment.Name;
            if (stageName) {
                environmentLabel += ' (' + stageName + ')';
            }
            result.push({ label: environmentLabel, value: id });
        }
        return result;
    }
}