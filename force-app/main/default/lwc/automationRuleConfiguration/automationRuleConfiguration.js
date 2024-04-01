import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import { namespaceClass, reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';
import { publish, MessageContext } from 'lightning/messageService';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import DYNAMIC_RENDERING_COMMUNICATION_CHANNEL from '@salesforce/messageChannel/DynamicRenderingCommunication__c';

import { labels, schema, fields, constants } from './constants';

import getAutomatedAction from '@salesforce/apex/AutomationRuleConfigureCtrl.getAutomatedAction';
import isAutomationRuleEditable from '@salesforce/apex/AutomationRuleConfigureCtrl.isAutomationRuleEditable';
import isAutomationRuleAccessible from '@salesforce/apex/AutomationRuleConfigureCtrl.isAutomationRuleAccessible';

export default class AutomationRuleConfiguration extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track automationRule = {};

    timeoutId;
    automationConnectorValues;

    readOnly = true;
    isEditable = false;
    isAccessible = false;
    isLoading = false;
    targetActionUpdatedFromBackPromotion = false;
    sourceActionMatchFilterCriteriaObject = false;

    automationConnectorLabel;
    automationConnectorHelpText;

    labels = labels;
    schema = schema;

    _getRecordResponse;
    _previousAutomationConnector;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    getAutomationRule({ data }) {
        if (data) {
            this._getRecordResponse = data;
            this._loadData();
            if (this.active) {
                this.readOnly = true;
            }
            this._selectOptions();
        }
    }

    @wire(getObjectInfo, { objectApiName: schema.AUTOMATION_RULE_OBJECT })
    getAutomationRuleInfo(result) {
        if (result.data) {
            const automationRuleAutomationConnector = result.data.fields[schema.AUTOMATION_RULE_AUTOMATION_CONNECTOR.fieldApiName];

            this.automationConnectorHelpText = automationRuleAutomationConnector ? automationRuleAutomationConnector.inlineHelpText : '';
            this.automationConnectorLabel = automationRuleAutomationConnector ? automationRuleAutomationConnector.label : '';
        }
    }

    async connectedCallback() {
        try {
            this.isAccessible = await isAutomationRuleAccessible();
            this.isEditable = await isAutomationRuleEditable();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this.messageAlert(errorMessage, 'error');
        }
    }

    get active() {
        return this.automationRule[schema.AUTOMATION_RULE_ACTIVE.fieldApiName];
    }

    get automatedAction() {
        return this.automationRule[schema.AUTOMATION_RULE_AUTOMATED_ACTION.fieldApiName];
    }

    get automationConnector() {
        return this.automationRule[schema.AUTOMATION_RULE_AUTOMATION_CONNECTOR.fieldApiName];
    }

    get automationConnectorValueLabel() {
        let result = '';
        if (this.automatedAction === labels.EXECUTE_QUALITY_GATE) {
            result = labels.QUALITY_GATE;
        } else if (this.automationConnector && this.sourceAction && this.sourceActionStatus) {
            const connectorOption = this._connectorsByActionAndStatus(this.sourceAction, this.sourceActionStatus).find(
                (item) => item.value === this.automationConnector
            );
            result = connectorOption ? connectorOption.label : '';
        }
        return result;
    }

    get cronExpression() {
        return this.automationRule[schema.AUTOMATION_RULE_CRON_EXPRESSION.fieldApiName];
    }

    get customAutomationConnector() {
        return this.automationRule[schema.AUTOMATION_RULE_CUSTOM_AUTOMATION_CONNECTOR.fieldApiName];
    }

    get execution() {
        return this.automationRule[schema.AUTOMATION_RULE_EXECUTION.fieldApiName];
    }

    get isAutomationConnectorDisabled() {
        return this.sourceAction === null || this.sourceAction.length === 0 || this.isContinuousDeliveryRule;
    }

    get isContinuousDeliveryRule() {
        return !this.isCustomConnector && this.automatedAction !== null && this.automatedAction.includes(labels.CONTINUOUS_DELIVERY);
    }

    get isCustomConnector() {
        const result = this.automationConnector === constants.CUSTOM;
        if (!result) {
            this.automationRule[schema.AUTOMATION_RULE_CUSTOM_AUTOMATION_CONNECTOR.fieldApiName] = '';
        }
        return result;
    }

    get isScheduled() {
        return this.execution === constants.SCHEDULED;
    }

    get sourceAction() {
        return this.automationRule[schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName];
    }

    get sourceActionStatus() {
        return this.automationRule[schema.AUTOMATION_RULE_SOURCE_ACTION_STATUS.fieldApiName];
    }

    get filterCriteria() {
        return this.automationRule[schema.AUTOMATION_RULE_FILTER_CRITERIA.fieldApiName];
    }

    handleChange(event) {
        this.automationRule[event.target.fieldName] = event.target.value;
        switch (event.target.fieldName) {
            case schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName:
            case schema.AUTOMATION_RULE_SOURCE_ACTION_STATUS.fieldApiName:
                this._selectOptions();
                this.automationRule[schema.AUTOMATION_RULE_AUTOMATION_CONNECTOR.fieldApiName] = '';
                this.automationRule[schema.AUTOMATION_RULE_CUSTOM_AUTOMATION_CONNECTOR.fieldApiName] = '';
                this.automationRule[schema.AUTOMATION_RULE_AUTOMATED_ACTION.fieldApiName] = '';
                break;
            case schema.AUTOMATION_RULE_CUSTOM_AUTOMATION_CONNECTOR.fieldApiName:
                clearTimeout(this.timeoutId);
                this.timeoutId = setTimeout(this._retrieveAutomationAction.bind(this), 1000);
                break;
            default:
                break;
        }
    }

    automationConnectorChange(event) {
        this._previousAutomationConnector = this.automationConnector;
        this.automationRule[schema.AUTOMATION_RULE_AUTOMATION_CONNECTOR.fieldApiName] = event.target.value;
        this._retrieveAutomationAction();
    }

    handleGenerateCronExpression(event) {
        this.automationRule[schema.AUTOMATION_RULE_CRON_EXPRESSION.fieldApiName] = event.detail;
    }

    displayError(event) {
        const errorMessage = reduceErrors(event.detail);
        showToastError(this, { message: errorMessage });
    }

    configure() {
        this.readOnly = false;
    }

    close() {
        this.readOnly = true;
        this.targetActionUpdatedFromBackPromotion = false;
        this.sourceActionMatchFilterCriteriaObject = false;
        this._previousAutomationConnector = '';
    }

    cancel() {
        this.close();
        this._loadData();
        this._resetInputFields();
    }

    handleSubmit(event) {
        event.preventDefault();
        this.fieldsToUpdate = event.detail.fields;
        this.targetActionUpdatedFromBackPromotion = this._targetActionUpdatedFromBackPromotion();
        this.sourceActionMatchFilterCriteriaObject = this._sourceActionMatchFilterCriteriaObject();

        if (!this.isScheduled) {
            this.fieldsToUpdate[schema.AUTOMATION_RULE_CRON_EXPRESSION.fieldApiName] = '';
        }
        if (this.automationConnector !== namespaceClass + constants.BACK_PROMOTION_CONNECTOR) {
            this.fieldsToUpdate[schema.AUTOMATION_RULE_CONFIG_JSON.fieldApiName] = null;
        }

        if (this.sourceActionMatchFilterCriteriaObject && !this.targetActionUpdatedFromBackPromotion) {
            this.template.querySelector('lightning-record-edit-form').submit(this.fieldsToUpdate);
            this._dynamicRenderingMessage();
        } else {
            this.template.querySelector('c-copadocore-modal').show();
        }
    }

    handleCancelModal() {
        this.template.querySelector('c-copadocore-modal').hide();
        this.cancel();
    }

    handleSaveModal() {
        if (this.targetActionUpdatedFromBackPromotion) {
            this.fieldsToUpdate[schema.AUTOMATION_RULE_CONFIG_JSON.fieldApiName] = null;
        }
        if (!this.sourceActionMatchFilterCriteriaObject) {
            this.fieldsToUpdate[schema.AUTOMATION_RULE_FILTER_CRITERIA.fieldApiName] = null;
        }

        this.template.querySelector('lightning-record-edit-form').submit(this.fieldsToUpdate);
        this.template.querySelector('c-copadocore-modal').hide();
        this._dynamicRenderingMessage();

        this.sourceActionMatchFilterCriteriaObject = false;
        this.targetActionUpdatedFromBackPromotion = false;
    }

    // PRIVATE

    async _retrieveAutomationAction() {
        this.isLoading = true;
        try {
            const connector = this.automationConnector === constants.CUSTOM ? this.customAutomationConnector : this.automationConnector;
            if (connector) {
                this.automationRule[schema.AUTOMATION_RULE_AUTOMATED_ACTION.fieldApiName] = await getAutomatedAction({ className: connector });
            } else {
                this.automationRule[schema.AUTOMATION_RULE_AUTOMATED_ACTION.fieldApiName] = '';
            }
        } catch (error) {
            this.automationRule[schema.AUTOMATION_RULE_AUTOMATED_ACTION.fieldApiName] = '';
        }
        this.isLoading = false;
    }

    _loadData() {
        fields.forEach((field) => {
            this.automationRule[field.fieldApiName] = getFieldValue(this._getRecordResponse, field);
        });
    }

    _selectOptions() {
        if (this.sourceAction && this.sourceActionStatus) {
            this.automationConnectorValues = this._connectorsByActionAndStatus(this.sourceAction, this.sourceActionStatus);
        }
    }

    _resetInputFields() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
    }

    _connectorsByActionAndStatus(sourceAction, actionStatus) {
        let result = [{ label: labels.CUSTOM_AUTOMATION_CONNECTOR, value: constants.CUSTOM }];
        switch (sourceAction) {
            case 'PromotionDeployment': {
                switch (actionStatus) {
                    case 'Successful':
                        result.push(
                            { label: labels.PROMOTION, value: namespaceClass + constants.PROMOTION_CONNECTOR },
                            { label: labels.BACK_PROMOTION, value: namespaceClass + constants.BACK_PROMOTION_CONNECTOR }
                        );
                        break;
                    default:
                        break;
                }
                break;
            }
            case 'SubmitUserStories': {
                switch (actionStatus) {
                    case 'Successful':
                        result.push({ label: labels.PROMOTION, value: namespaceClass + constants.SUBMIT_US_CONNECTOR });
                        break;
                    default:
                        break;
                }
                break;
            }
            default:
                break;
        }
        return result;
    }

    _sourceActionMatchFilterCriteriaObject() {
        if (!this.filterCriteria) {
            return true;
        }
        const mainObject = JSON.parse(this.filterCriteria).mainObject;
        switch (mainObject) {
            case schema.USER_STORY_OBJECT.objectApiName:
                return ['Commit', 'Promotion', 'PromotionDeployment', 'SubmitUserStories'].some(
                    (action) => action === this.fieldsToUpdate[schema.AUTOMATION_RULE_SOURCE_ACTION.fieldApiName]
                );
            default:
                return false;
        }
    }

    _targetActionUpdatedFromBackPromotion() {
        return (
            this._previousAutomationConnector === namespaceClass + constants.BACK_PROMOTION_CONNECTOR &&
            this._previousAutomationConnector !== this.automationConnector
        );
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

    _dynamicRenderingMessage() {
        const payload = {
            action: 'refresh'
        };

        setTimeout(() => publish(this.messageContext, DYNAMIC_RENDERING_COMMUNICATION_CHANNEL, payload), 1000);
    }
}