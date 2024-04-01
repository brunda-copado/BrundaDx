const ALL = 'All';
const LIST = 'list';

// PUBLIC

export const getColumnOptions = async (columns, data) => {
    const result = [];
    const listColumns = _getListColumns(columns);

    if (!data || !listColumns) {
        return columns;
    }

    const optionsByColumn = _getOptionsByColumn(listColumns, data);

    columns.forEach((eachColumn) => {
        const column = Object.assign({}, eachColumn);
        const isListTypeColumn = column.typeAttributes && column.typeAttributes.type && column.typeAttributes.type.toLowerCase() === LIST;
        if (isListTypeColumn && column.searchable) {
            const options = optionsByColumn.get(column.fieldName);
            const columnTypeAttributes = Object.assign({}, column.typeAttributes);
            columnTypeAttributes.options = options;
            column.typeAttributes = columnTypeAttributes;
        }
        result.push(column);
    });
    return result;
}

// PRIVATE

function _getListColumns(columns) {
    const result = [];
    columns.forEach((eachColumn) => {
        const column = Object.assign({}, eachColumn);
        const isListTypeColumn = column.typeAttributes && column.typeAttributes.type && column.typeAttributes.type.toLowerCase() === LIST;
        if (isListTypeColumn && column.searchable) {
            result.push(column.fieldName);
        }
    });
    return result;
}

function _getOptionsByColumn(fieldNames, data) {
    const result = new Map();
    _getOptionValuesByFieldName(data, fieldNames).forEach((optionsByFieldName, field) => {
        const options = [];
        optionsByFieldName.forEach((option) => {
            options.push(option);
        });
        result.set(field, options);
    });
    return result;
}

function _getOptionValuesByFieldName(data, fieldNames) {
    const result = new Map();
    fieldNames.forEach((fieldName) => {
        const optionByValue = new Map();
        optionByValue.set('', { label: ALL, value: '' });
        result.set(fieldName, optionByValue);
    });
    data.map((eachRow) => {
        const row = Object.assign({}, eachRow);
        fieldNames.forEach((fieldName) => {
            const optionByValue = result.get(fieldName);
            const fieldHasValue = row[fieldName] != null && row[fieldName] !== '';
            const fieldValueNotAdded = Object.keys(optionByValue).indexOf(row[fieldName]) < 0;
            if (fieldHasValue && fieldValueNotAdded) {
                const fieldValue = row[fieldName];
                optionByValue.set(fieldValue, { label: fieldValue, value: fieldValue });
            }
            result.set(fieldName, optionByValue);
        });
    });
    return result;
}