import { REPLACE_PROPERTIES } from './constants';

export const sortByExternalIdAndRequired = (fields, sortConfiguration) =>
    fields.sort((field1, field2) => {
        if (field1.externalId && !field2.externalId) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (!field1.externalId && field2.externalId) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;

        if (field1.required && !field2.required) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (!field1.required && field2.required) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;

        if (field1.label.toLowerCase() < field2.label.toLowerCase()) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (field1.label.toLowerCase() > field2.label.toLowerCase()) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;
    });

export const sortByUseAsExternalId = (fields, sortConfiguration) =>
    fields.sort((field1, field2) => {
        if (field1.externalId && !field2.externalId) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (!field1.externalId && field2.externalId) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;

        if (field1.externalId && field2.externalId && !field1.isSelected && field2.isSelected)
            return sortConfiguration.sortDirection === 'asc' ? -1 : 1;
        if (field1.externalId && field2.externalId && field1.isSelected && !field2.isSelected)
            return sortConfiguration.sortDirection === 'asc' ? 1 : -1;

        if (field1.useAsExternalId && !field2.useAsExternalId) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (!field1.useAsExternalId && field2.useAsExternalId) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;

        if (field1.label.toLowerCase() < field2.label.toLowerCase()) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (field1.label.toLowerCase() > field2.label.toLowerCase()) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;
    });

export const sortByContentUpdate = (fields, sortConfiguration) =>
    fields.sort((field1, field2) => {
        if (!field1.isSelected && field2.isSelected) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;
        if (field1.isSelected && !field2.isSelected) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;

        if (field1.fieldContentUpdate > field2.fieldContentUpdate) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (field1.fieldContentUpdate < field2.fieldContentUpdate) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;

        if (field1.label.toLowerCase() < field2.label.toLowerCase()) return sortConfiguration.sortDirection === 'asc' ? 1 : -1;
        if (field1.label.toLowerCase() > field2.label.toLowerCase()) return sortConfiguration.sortDirection === 'asc' ? -1 : 1;
    });

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