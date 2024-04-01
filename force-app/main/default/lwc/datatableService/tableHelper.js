import { columnsConfiguration, rowsData, update, relatedListConfiguration } from './tableHelperUtils';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { showToastSuccess } from 'c/copadocoreToastNotification';
import DataProcessor from './dataProcessor';

import Records_Updated_Successfully from '@salesforce/label/c.Records_Updated_Successfully';

// PUBLIC

export const getColumnsConfiguration = async (self, configuration) => {
    return await columnsConfiguration(self, configuration);
}

export const getRowsData = async (self, queryConfiguration) => {
    let data = await rowsData(self, queryConfiguration);
    if (data) {
        data = new DataProcessor(data).execute();
    }
    return data;
}

export const handleSave = async (self, event) => {
    const records = event.detail.draftValues;
    const result = await update(self, { records });
    // If it is null (because apex method returns void) or any other value,
    // it means that updateRecords is successful
    if (result !== undefined) {
        showToastSuccess(self, {
            title: Records_Updated_Successfully
        });

        const notifyChangeIds = records.map((row) => ({ recordId: row.Id }));
        getRecordNotifyChange(notifyChangeIds);
        return true;
    }
    return false;
}

export const getMoreData = async (event, allRows, configuration) => {
    // event.target is null after await so we save it in a variable
    const _table = event.target;
    _table.isLoading = true;
    let data;
    if (allRows) {
        if (configuration.recordsOffset < allRows.length) {
            data = _sliceRowsIntoData(allRows, configuration.recordsOffset, configuration.recordSize);
        } else {
            _table.enableInfiniteLoading = false;
        }
    }
    _table.isLoading = false;
    if (data) {
        data = new DataProcessor(data).execute();
    }
    return data;
}

export const getRelatedListConfiguration = async (self, recordId, childObject) => {
    const configuration = await relatedListConfiguration(self, {
        parentId: recordId,
        fromObject: childObject.apiName,
        relationshipField: childObject.relationshipField
    });

    if (configuration) {
        const result = {
            iconName: configuration.iconName,
            childListName: configuration.childListName,
            sobjectLabel: configuration.sobjectLabel,
            sobjectLabelPlural: configuration.sobjectLabelPlural
        };
        return result;
    }
    return null;
}

// PRIVATE

function _sliceRowsIntoData(allRows, recordsOffset, recordSize) {
    recordsOffset += recordSize;
    return allRows.slice(0, recordsOffset);
}