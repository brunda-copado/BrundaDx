// PUBLIC

export function dataReducer(rawData, columns, fieldsToKeep) {
    if (!rawData || !columns) return;
    
    let fieldNames = [];
    const fields = Object.keys(rawData[0]);

    if (fieldsToKeep) {
        fieldNames = [...fieldNames, ...fieldsToKeep];
    }

    columns.forEach((column) => {
        fieldNames.push(column.fieldName);
    });

    return _removeExtraDataColumn(fields, fieldNames, rawData);
}

export function searchableDataReducer(rawData, columns) {
    if (!rawData || !columns) return;

    const omitColumns = _getNotSearchableColumns(columns);
    return rawData.map((eachRow) => {
        const row = Object.assign({}, eachRow);
        omitColumns.forEach((field) => {
            delete row[field];
        });
        return row;
    });
}

// PRIVATE
function _removeExtraDataColumn(fields, fieldNamesToKeep, rawData) {
    const omitColumns = [];
    
    fields.forEach((field) => {
        if (fieldNamesToKeep.indexOf(field) < 0) {
            omitColumns.push(field);
        }
    });
    
    return rawData.map((eachRow) => {
        const row = Object.assign({}, eachRow);
        omitColumns.forEach((field) => {
            delete row[field];
        });
        return row;
    });
}

function _getNotSearchableColumns(columns) {
    const result = [];
    for (const column of columns) {
        if (!column.searchable) {
            result.push(column.fieldName);
        }
    }
    return result;
}