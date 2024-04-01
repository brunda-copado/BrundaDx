import { label, schema, AND, OR } from './constants';

export function getSymbolForConditionLogic(conditionLogic) {
    switch (conditionLogic) {
        case AND:
            return '&&';
        case OR:
            return '||';
        default:
            return '';
    }
}

// NOTE: simplified way of handling types, user is reponsible for providing correct values in the input field.
// For more advanced behavior (similar to Data Templates filters), we will need more time
// As a workaround, custom where condition is available
export function getWhereCondition(field, operator, value, dataType) {
    switch (operator) {
        case 'equals':
            switch (dataType) {
                case 'String':
                case 'Picklist':
                case 'Reference':
                    return value === 'null' ? field + ' = ' + value + '' : field + " = '" + value + "'";
                default:
                    return field + ' = ' + value + '';
            }
        case 'notEquals':
            switch (dataType) {
                case 'String':
                case 'Picklist':
                case 'Reference':
                    return value === 'null' ? field + ' != ' + value + '' : field + " = '" + value + "'";
                default:
                    return field + ' != ' + value + '';
            }
        case 'contains':
            switch (dataType) {
                case 'Reference':
                    return value === 'null' ? getReferenceNameField(field) + " LIKE '%%'" : getReferenceNameField(field) + " LIKE '%" + value + "%'";
                default:
                    return field + " LIKE '%" + value + "%'";
            }

        case 'notContains':
            switch (dataType) {
                case 'Reference':
                    return value === 'null'
                        ? '(NOT ' + getReferenceNameField(field) + " LIKE '%%')"
                        : '(NOT ' + getReferenceNameField(field) + " LIKE '%" + value + "%')";
                default:
                    return '(NOT ' + field + " LIKE '%" + value + "%')";
            }
        case 'greaterThan':
            return field + ' > ' + value;
        case 'greaterOrEqual':
            return field + ' >= ' + value;
        case 'lessThan':
            return field + ' < ' + value;
        case 'lessOrEqual':
            return field + ' <= ' + value;
        default:
            return '';
    }
}

export function reorder(conditions) {
    conditions.forEach((item, index) => {
        item.conditionNumber = index + 1;
    });
}

export function getOperatorOptionsByFieldType(fieldType) {
    switch (fieldType) {
        case 'Double':
        case 'Percent':
        case 'Date':
        case 'DateTime':
            return [
                { label: label.EQUALS, value: 'equals' },
                { label: label.DOES_NOT_EQUAL, value: 'notEquals' },
                { label: label.GREATER_THAN, value: 'greaterThan' },
                { label: label.GREATER_OR_EQUAL, value: 'greaterOrEqual' },
                { label: label.LESS_THAN, value: 'lessThan' },
                { label: label.LESS_OR_EQUAL, value: 'lessOrEqual' }
            ];
        case 'Boolean':
            return [
                { label: label.EQUALS, value: 'equals' },
                { label: label.DOES_NOT_EQUAL, value: 'notEquals' }
            ];
        case 'String':
        case 'Picklist':
        default:
            return [
                { label: label.EQUALS, value: 'equals' },
                { label: label.DOES_NOT_EQUAL, value: 'notEquals' },
                { label: label.CONTAINS, value: 'contains' },
                { label: label.DOES_NOT_CONTAIN, value: 'notContains' }
            ];
    }
}
export function getInputTypeByFieldType(fieldType) {
    switch (fieldType) {
        case 'Double':
        case 'Percent':
            return 'number';
        case 'Date':
            return 'date';
        case 'DateTime':
            return 'datetime';
        case 'Boolean':
            return 'checkbox';
        case 'Reference':
            return 'reference';
        default:
            return 'text';
    }
}

export function getInputVariantByFieldType(fieldType) {
    switch (fieldType) {
        case 'Boolean':
        case 'DateTime':
            return 'label-hidden';
        default:
            return '';
    }
}

export function getInputClassByFieldType(fieldType) {
    switch (fieldType) {
        case 'DateTime':
            return '';
        default:
            return 'slds-m-bottom_xx-small';
    }
}

export function getInputLayoutClassByFieldType(inputType) {
    switch (inputType) {
        case 'checkbox':
            return 'slds-p-left_medium slds-m-top_large slds-m-bottom_large';
        default:
            return 'slds-p-left_medium';
    }
}

export function getDefaultValueByFieldType(fieldType) {
    switch (fieldType) {
        case 'Boolean':
            return 'false';
        default:
            return 'null';
    }
}

function getReferenceNameField(field) {
    return field.replace('__c', '__r.Name');
}