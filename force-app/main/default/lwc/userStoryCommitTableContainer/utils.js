import { DXCommitTable } from './DXCommitTable';

export const parseUserStoryMetadata = (records) => {
    // extension
    return new DXCommitTable().parseUserStoryMetadata(records);
};

export const createSelectedResult = (row) => {
    // extension
    return new DXCommitTable().createSelectedResult(row);
};

export const getColumns = () => {
    // extension
    return new DXCommitTable().getColumns();
};

export const getDefaultSortedByFieldName = () => {
    // extension
    return new DXCommitTable().getDefaultSortedByFieldName();
};

export const prepareRows = (userStoryId, data, keyField) => {
    // extension
    return data.map((element) => {
        let result = { ...element, ReadOnlyMode: true, OperationOptions: new DXCommitTable().getOperationOptions(element) };
        // Note: keyfield should be fixed (i.e. Id) and the component feeding the table should make sure each element has that property and it is unique, so probably this will not be needed
        result[keyField] = new DXCommitTable().getRowId(userStoryId, element);
        return result;
    });
};

export const combineRows = (existingRows, newRows, keyField) => {
    const allNewRows = newRows.filter((row) => existingRows.some((existingRow) => row[keyField] === existingRow[keyField]) === false);
    return [...existingRows, ...allNewRows];
};

export const createDraftValue = (rowId, property, value, keyField) => {
    let newDraftValue = {};
    newDraftValue[keyField] = rowId;
    newDraftValue[property] = value;
    return newDraftValue;
};

export const upsertDraftValue = (draftValues, newDraftValue, keyField) => {
    const draftIndex = draftValues.findIndex((drafValue) => drafValue[keyField] === newDraftValue[keyField]);
    if (draftIndex !== -1) {
        const updatedDraftValue = { ...draftValues[draftIndex], ...newDraftValue };
        draftValues[draftIndex] = updatedDraftValue;
    } else {
        draftValues.push(newDraftValue);
    }
    return draftValues;
};