import { datePeriods, customFilterOption, booleanOptions } from './constants';

export function createFilter(order) {
    return {
        id: getUniqueKey('filter'),
        order: order,
        fieldName: '',
        fieldType: 'STRING',
        inputType: 'text',
        operators: [],
        operatorCode: '',
        isCustom: false,
        isDatepicker: false,
        isBoolean: false,
        dateOption: '',
        inputValue: '',
        value: '',
        showValue: true,
        isValid: true
    };
}

export function reorder(filters) {
    filters.forEach((filter, index) => {
        filter.order = index + 1;
    });
}

export function getFilter(filters, id) {
    const index = filters.findIndex((filter) => filter.id === id);
    return filters[index];
}

export function getField(fields, name) {
    const index = fields.findIndex((field) => field.name === name);
    return fields[index];
}

export function getUniqueKey(key) {
    return `${key}_` + Math.random().toString(36).substr(2, 9);
}

export function getInputType(fieldType) {
    switch (fieldType) {
        case 'DATETIME':
            return 'datetime';
        case 'DATE':
            return 'date';
        case 'PERCENT':
        case 'DOUBLE':
        case 'INTEGER':
        case 'INT':
        case 'CURRENCY':
            return 'number';
        default:
            return 'text';
    }
}

export function getInputFormatter(fieldType) {
    switch (fieldType) {
        case 'PERCENT':
            return 'percent';
        case 'CURRENCY':
            return 'currency';
        default:
            return '';
    }
}

//This determines default values for filters.
export function getDefaultValue(fieldType) {
    switch (fieldType) {
        case 'DATETIME':
        case 'DATE':
        case 'PERCENT':
        case 'DOUBLE':
        case 'INTEGER':
        case 'INT':
        case 'CURRENCY':
            return null;
        case 'BOOLEAN':
            return booleanOptions[0].value;
        default:
            return '';
    }
}

export function isDatepicker(fieldType) {
    return fieldType === 'DATETIME' || fieldType === 'DATE';
}

export function isBoolean(fieldType) {
    return fieldType === 'BOOLEAN';
}

export function getShowValue(fieldType) {
    return isDatepicker(fieldType) || isBoolean(fieldType) ? false : true;
}

export function isRangeDate(dateOption) {
    return dateOption.indexOf(':n') !== -1;
}

export function isPeriodDate(dateOption) {
    return datePeriods.indexOf(dateOption) !== -1;
}

export function isCustomDate(dateOption) {
    return dateOption === 'customDate';
}

export function convertToDataFilters(filters) {
    return filters
        .filter((filter) => {
            return filter.order && filter.fieldName && filter.fieldType;
        })
        .map((filter) => ({
            order: filter.order,
            fieldName: filter.fieldName,
            fieldType: filter.fieldType,
            fieldLabel: filter.fieldLabel,
            operatorCode: filter.operatorCode,
            value: filter.value
        }));
}

export function convertDataFilters(fields, dataFilters) {
    return dataFilters
        .filter((dataFilter) => {
            return dataFilter.order && dataFilter.fieldName && dataFilter.fieldType;
        })
        .map((dataFilter) => {
            let id = getUniqueKey('filter');
            let order = dataFilter.order;
            let fieldName = dataFilter.fieldName;
            let fieldType = dataFilter.fieldType;
            let operators = [];
            let operatorCode = dataFilter.operatorCode;
            let inputValue = dataFilter.value;
            let value = dataFilter.value;
            let inputType = 'text';
            let inputFormatter = getInputFormatter(dataFilter.fieldType);
            let isCustom = dataFilter.fieldName === customFilterOption.value;
            let datePickerValue = isDatepicker(dataFilter.fieldType);
            let dateOption = '';
            let booleanValue = isBoolean(dataFilter.fieldType);
            let showValue = false;
            let isValid = true;
            if (!isCustom) {
                const field = getField(fields, dataFilter.fieldName);
                if (field) {
                    fieldType = field.type;
                    if (field.type !== dataFilter.fieldType) {
                        isValid = false;
                        inputFormatter = getInputFormatter(field.type);
                        datePickerValue = isDatepicker(field.type);
                        booleanValue = isBoolean(field.type);
                    }
                    operators = field.operators.map(({ label, code }) => ({ label: label, value: code }));
                    if (datePickerValue) {
                        if (dataFilter.value) {
                            if (dataFilter.value.match(/:([0-9]+)$/)) {
                                dateOption = dataFilter.value.replace(/:[0-9]+$/, ':n');
                            } else if (isPeriodDate(dataFilter.value)) {
                                dateOption = dataFilter.value;
                            } else {
                                dateOption = 'customDate';
                            }
                        } else {
                            dateOption = 'customDate';
                        }
                    }
                    const rangeValue = isRangeDate(dateOption);
                    inputType = datePickerValue && rangeValue ? 'text' : getInputType(fieldType);
                    inputValue = datePickerValue && rangeValue ? dataFilter.value.match(/:([0-9]+)$/)[1] : dataFilter.value;
                    showValue = isPeriodDate(dateOption) || booleanValue ? false : true;
                } else {
                    isValid = false;
                }
            }
            return {
                id: id,
                order: order,
                fieldName: fieldName,
                fieldType: fieldType,
                operators: operators,
                operatorCode: operatorCode,
                inputValue: inputValue,
                value: value,
                inputType: inputType,
                inputFormatter: inputFormatter,
                isCustom: isCustom,
                isDatepicker: datePickerValue,
                dateOption: dateOption,
                isBoolean: booleanValue,
                showValue: showValue,
                isValid: isValid
            };
        });
}