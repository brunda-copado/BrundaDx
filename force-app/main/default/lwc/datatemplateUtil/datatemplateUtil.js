import { publish } from 'lightning/messageService';
import { compare, generateMessages } from './utils';

export const CLONE_ALERT_ID = 'clone';
export const EXPORT_ALERT_ID = 'export';
export const ACTIVATE_ALERT_ID = 'activate';
export const DEACTIVATE_ALERT_ID = 'deActivate';
export const INVALIDCREDENTIAL_ALERT_ID = 'invalidCredential';
export const DATATEMPLATE_COMMUNICATION_ID = 'DataTemplateAlerts';
export const RECORD_MATCHING_COMMUNICATION_ID = 'RecordMatchingFormulaAlerts'
export const RECORD_MATCHING_FORMULA_ID = 'templateRecordMatching';
export const INACTIVE_RELATED_TEMPLATE_ERROR_ID = 'inactiveRelatedTemplateAlert';
export const ACTION_ALERT_IDS = [CLONE_ALERT_ID, EXPORT_ALERT_ID, ACTIVATE_ALERT_ID, DEACTIVATE_ALERT_ID, INVALIDCREDENTIAL_ALERT_ID];

export function clearAllActionAlerts(messageContext, channel, communicationId) {
    for (const alertID of ACTION_ALERT_IDS) {
        publish(messageContext, channel, createAlert(undefined, undefined, true, communicationId, alertID, 'remove'));
    }
}

export function createAlert(message, variant, dismissible, communicationId, alertId, operation) {
    return {
        message: message,
        variant: variant,
        dismissible: dismissible,
        communicationId: communicationId,
        id: alertId,
        operation: operation
    };
}

export function compareRefreshedSchema(oldSchema, newSchema) {
    let result = {};
    const mainObject = newSchema.dataTemplate.templateMainObject;
    const newFields = Object.values(newSchema.selectableFieldsMap);
    const oldFields = Object.values(oldSchema.selectableFieldsMap);
    const newChildObjects = Object.values(newSchema.selectableChildRelationsMap);
    const oldChildObjects = Object.values(oldSchema.selectableChildRelationsMap);

    const fieldsAdded = compare(newFields, oldFields, 'name');
    const fieldsRemoved = compare(oldFields, newFields, 'name');
    const childobjectsAdded = compare(newChildObjects, oldChildObjects, 'childSObject');
    const childobjectsRemoved = compare(oldChildObjects, newChildObjects, 'childSObject');

    result = generateMessages(fieldsAdded, fieldsRemoved, childobjectsAdded, childobjectsRemoved, mainObject);

    return result;
}

export function formatLabel(customLabel, ...formattingArguments) {
    if (typeof customLabel !== 'string') return customLabel;
    return customLabel.replace(/{(\d+)}/gm, (match, index) => (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
}