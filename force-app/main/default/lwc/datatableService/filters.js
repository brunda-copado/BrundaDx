const AVAILABLE_FILTER_TYPE = ['input', 'range', 'boolean', 'list', 'text', 'multi-select'];
const INCLUDES = 'includes';
const EQUALS = 'equals';
const ALL = 'All';
const LIST = 'list';
const MULTI_SELECT = 'multi-select';

// PUBLIC

export const getFilters = async (columns, data) => {
    const filterableColumns = _getFilterableColumns(columns);
    const result = [];
    filterableColumns.forEach(column => {
        const config = _getColumnFilterConfig(column, data);
        if (config) {
            result.push(config);
        }
    });
    return result;
};

export const getFilteredData = async (filterByField, data) => {
    if (!data || !filterByField) return;

    const result = [];
    data.map(eachRow => {
        let isValidRow = true;
        const row = Object.assign({}, eachRow);
        filterByField = _removeEmptyFilter(filterByField);
        filterByField.forEach(eachFilter => {
            const fieldName = eachFilter.fieldName;
            const isArrayType = Array.isArray(eachFilter.searchTerm);
            const fieldValue = !isArrayType && eachFilter.searchTerm ? (eachFilter.searchTerm + '').trim().toLowerCase() : '';
            const fieldValues =
                isArrayType && eachFilter.searchTerm && eachFilter.searchTerm.length ? eachFilter.searchTerm.map(option => option.toLowerCase()) : [];
            const minFieldValue = eachFilter.filterRangeMin ? (eachFilter.filterRangeMin + '').trim() : '';
            const maxFieldValue = eachFilter.filterRangeMax ? (eachFilter.filterRangeMax + '').trim() : '';
            const selectedOption = eachFilter.selectedOption ? eachFilter.selectedOption.toLowerCase() : INCLUDES;

            if (isArrayType) {
                if (!_isWithinValidSelection(row, { name: fieldName, selectedOption: selectedOption, value: fieldValues })) {
                    isValidRow = false;
                }
            } else if (fieldValue) {
                if (!_isValidRow(row, { name: fieldName, selectedOption: selectedOption, value: fieldValue })) {
                    isValidRow = false;
                }
            } else {
                if (
                    !_isWithinValidRange(row, { name: fieldName, selectedOption: selectedOption, minValue: minFieldValue, maxValue: maxFieldValue })
                ) {
                    isValidRow = false;
                }
            }
        });
        if (isValidRow) {
            result.push(row);
        }
    });
    return result;
};

// PRIVATE

function _getFilterableColumns(columns) {
    const result = [];
    columns.forEach(column => {
        if (column.filterable && column.filtertype) {
            result.push(column);
        }
    });
    return result;
}

function _getColumnFilterConfig(column, data) {
    const result = {};
    if (column.filtertype && AVAILABLE_FILTER_TYPE.indexOf(column.filtertype) > -1) {
        result.filtertype = column.filtertype;
        result.filterOperation = column.filterOperation;
        result.type = column.type;
        result.columnname = column.type === 'url' ? column.typeAttributes.label.fieldName : column.fieldName;
        result.values = [];
        if (result.filtertype.toLowerCase() === LIST || result.filtertype.toLowerCase() === MULTI_SELECT) {
            result.values = JSON.parse(_getFilterValues(data, column.fieldName));
        }
        const options = [];
        if (result.values && result.values.length) {
            result.values = result.values.sort();
            options.push({ label: ALL, value: '' });
            result.values.forEach(value => {
                options.push({ label: value, value: value });
            });
        }
        result.options = options;
        result.label = column.label;
        return result;
    } else {
        return null;
    }
}

function _getFilterValues(data, column) {
    const result = [];
    data.forEach(eachRow => {
        if (result.indexOf(eachRow[column]) < 0) {
            const row = Object.assign({}, eachRow);
            const columnValue = row[column];
            if (columnValue && (columnValue + '').trim()) {
                result.push(columnValue);
            }
        }
    });
    // NOTE: Lookup component requires values to be in JSON format
    return JSON.stringify(result);
}

function _removeEmptyFilter(filterByField) {
    const result = new Map();
    filterByField.forEach(eachFilter => {
        const fieldName = eachFilter.fieldName;
        if (_hasFilterValue(eachFilter)) {
            result.set(fieldName, eachFilter);
        }
    });
    return result;
}

function _hasFilterValue(eachFilter) {
    const fieldValue = eachFilter.searchTerm ? (eachFilter.searchTerm + '').trim() : '';
    const minFieldValue = eachFilter.filterRangeMin ? (eachFilter.filterRangeMin + '').trim() : '';
    const maxFieldValue = eachFilter.filterRangeMax ? (eachFilter.filterRangeMax + '').trim() : '';
    if (fieldValue || minFieldValue || maxFieldValue) {
        return true;
    }
    return false;
}

function _isWithinValidSelection(row, field) {
    const value = row[field.name];
    const isValidValue = value !== undefined && value !== null;
    const lowercaseValue = (value + '').toLowerCase();
    return isValidValue && field.value.includes(lowercaseValue);
}

function _isValidRow(row, field) {
    const value = row[field.name];
    const isValidValue = value !== undefined && value !== null;
    const lowercaseValue = (value + '').toLowerCase();
    const operatorIsEquals = field.selectedOption === EQUALS;
    return isValidValue && _matchesOperation(operatorIsEquals, lowercaseValue, field.value);
}

function _matchesOperation(operatorIsEquals, a, b) {
    let result;
    if (operatorIsEquals) {
        result = a === b;
    } else {
        result = a.includes(b);
    }
    return result;
}

function _isWithinValidRange(row, field) {
    const value = row[field.name];
    const isValidValue = value !== undefined && value !== null;
    return isValidValue && _matchesRange(field.minValue, value, field.maxValue);
}

function _matchesRange(min, a, max) {
    let result;
    if (min && max) {
        result = min <= a && a <= max;
    } else if (min) {
        result = min <= a;
    } else if (max) {
        result = a <= max;
    }
    return result;
}