import { LightningElement, api, wire, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import getData from '@salesforce/apex/BackPromotionAutomationScopeCtrl.getData';
import isAutomationRuleAccessible from '@salesforce/apex/BackPromotionAutomationScopeCtrl.isAutomationRuleAccessible';

import { label, schema, fields } from './constants';

export default class BackPromotionAutomationScope extends LightningElement {
    @api recordId;

    label = label;

    readOnly = true;
    isLoading = true;
    isAccessible = false;

    environmentOptions = [];
    selectedForExclusion = [];

    _recordInfo;
    _environmentsById;
    _currentExcludedEnvironments;
    _userHasPermission = false;

    @track _automationRule = {};

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

    get nothingConfigured() {
        return !this._currentExcludedEnvironments;
    }

    get currentExcludedEnvironmentNames() {
        if (!this._currentExcludedEnvironments) {
            return '';
        }
        return this._currentExcludedEnvironments
            .split(',')
            .map((environmentId) => {
                return this._environmentsById[environmentId] ? this._environmentsById[environmentId].Name : environmentId;
            })
            .join(', ');
    }

    get includedEnvironmentNames() {
        if (!this._environmentsById && !this._currentExcludedEnvironments) {
            return '';
        }

        return Object.keys(this._environmentsById)
            .filter(id => !this._currentExcludedEnvironments.includes(id))
            .map(id => (this._environmentsById[id] || {}).Name || id)
            .join(', ');
    }

    get active() {
        return this._automationRule[schema.AUTOMATION_RULE_ACTIVE.fieldApiName];
    }

    get maxNumberOfEnvironments() {
        return this._environmentsById ? Object.keys(this._environmentsById)?.length - 1 : 999;
    }

    async connectedCallback() {
        try {
            this.isAccessible = await isAutomationRuleAccessible();
            this._getRecordData();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this._messageAlert(errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    getActiveFieldValue({ data }) {
        if (data) {
            fields.forEach((field) => {
                this._automationRule[field.fieldApiName] = getFieldValue(data, field);
            });
        }
    }

    handleEdit() {
        this.readOnly = false;
        this._setEnvironmentOptions();
    }

    handleSelectionChange(event) {
        this.selectedForExclusion = event.detail.value;
    }

    handleClickClear() {
        const event = { detail: { value: [] } };
        this.handleSelectionChange(event);
    }

    handleCancel() {
        this.readOnly = true;
    }

    async handleSave() {
        this.isLoading = true;
        try {
            const record = this._getUpdatedRecord();
            await updateRecord(record);
            this._handleRefresh();
            this.readOnly = true;
        } catch (error) {
            let errorMessage = reduceErrors(error);
            const validationErrorMessage = this._isTriggerValidationError(error);
            if (validationErrorMessage) {
                errorMessage = validationErrorMessage;
            }
            showToastError(this, { message: errorMessage });
        }

        this.isLoading = false;
    }

    // PRIVATE

    async _getRecordData() {
        this._recordInfo = await getData({ recordId: this.recordId });
        if (this._recordInfo) {
            this._loadData(this._recordInfo);
        }
    }

    _handleRefresh() {
        this._getRecordData();
    }

    _loadData(data) {
        this._currentExcludedEnvironments = data.currentExcludedEnvironmentsForBp;
        this._environmentsById = data.environmentsById;
        this._userHasPermission = data.userHasPermission;
    }

    _getUpdatedRecord() {
        const record = {
            fields: {
                Id: this.recordId,
                [schema.AUTOMATION_RULE_CONFIG_JSON.fieldApiName]: this.selectedForExclusion.length > 0
                    ? this._getConfigJson()
                    : ''
            }
        };
        return record;
    }

    _getConfigJson() {
        const result = {
            excludedEnvironmentsForBackPromotion: this.selectedForExclusion,
        };

        return JSON.stringify(result, null, 4);
    }

    _setEnvironmentOptions() {
        this.environmentOptions = this._createEnvironmentOptions(this._environmentsById);
        this.selectedForExclusion = this._currentExcludedEnvironments ? this._currentExcludedEnvironments.split(',') : [];
    }

    _messageAlert(message, variant) {
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

    _createEnvironmentOptions(environmentsById) {
        let result = [];
        for (const [id, environment] of Object.entries(environmentsById)) {
            result.push({ label: environment.Name, value: id });
        }
        return result;
    };

    _isTriggerValidationError(error) {
        let validationErrorMessage;
        if (
            error.body.output.errors &&
            error.body.output.errors.length &&
            error.body.output.errors[0].errorCode === 'FIELD_CUSTOM_VALIDATION_EXCEPTION'
        ) {
            validationErrorMessage = error.body.output.errors[0].message;
        }
        return validationErrorMessage;
    };
}