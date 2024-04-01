import { dataReducer as dataReducerUtil } from './redux.js';
import { getColumnOptions } from './columnOptions.js';
import { getFilters, getFilteredData as getFilteredDataUtil } from './filters';
import { applySearch } from './search.js';
import { sortRows } from './sort.js';
import ColumnsProcessor from './columnsProcessor';
import {
    getColumnsConfiguration as getColumnsConfigurationUtil,
    getRowsData as getRowsDataUtil,
    handleSave,
    getMoreData,
    getRelatedListConfiguration as getRelatedListConfigurationUtil
} from './tableHelper';

export function dataReducer(rawData, columns, fieldsToKeep) {
    return dataReducerUtil(rawData, columns, fieldsToKeep);
}

export function getColumnsWithOptions(columns, data) {
    return getColumnOptions(columns, data);
}

export function getFiltersByColumns(columns, data) {
    return getFilters(columns, data);
}

export function getFilteredData(filterByField, data) {
    return getFilteredDataUtil(filterByField, data);
}

export function getSearchedData(columns, data, searchTerm) {
    return applySearch(columns, data, searchTerm);
}

export function getSortedData(columns, data, field) {
    const fieldConfiguration = {
        name: field.name,
        sortDirection: field.sortDirection
    };
    return sortRows(columns, data, fieldConfiguration);
}

export function getColumnsConfiguration(self, columns) {
    const columnsConfiguration = {
        objectApiName: columns.objectApiName,
        fieldSetName: columns.fieldSetName,
        hideDefaultColumnsActions: columns.hideDefaultColumnsActions,
        sortable: columns.sortable,
        editable: columns.editable,
        searchable: columns.searchable,
        filterable: columns.filterable
    };
    return getColumnsConfigurationUtil(self, columnsConfiguration);
}

export function getRowsData(self, query) {
    const queryConfiguration = {
        selectFieldSet: query.fieldSetName,
        fromObject: query.objectApiName,
        relationshipField: query.relationshipFieldApi,
        parentId: query.recordId,
        parentIds: query.recordIds,
        orderBy: query.orderBy,
        recordsLimit: query.numberOfRecordsLimit,
        recordsOffset: query.recordsOffset
    };
    return getRowsDataUtil(self, queryConfiguration);
}

export function getUpgradedColumnConfiguration(columns, actions, implementsDragAndDrop) {
    return JSON.parse(JSON.stringify(new ColumnsProcessor(columns, actions, implementsDragAndDrop).execute()));
}

export function saveRecords(self, event) {
    return handleSave(self, event);
}

export function loadMoreData(event, allRows, configuration) {
    const loadMoreConfiguration = {
        recordsOffset: configuration.recordsOffset,
        recordSize: configuration.recordSize
    };
    return getMoreData(event, allRows, loadMoreConfiguration);
}

export function getRelatedListConfiguration(self, recordId, childObject) {
    const childObjectConfiguration = {
        apiName: childObject.apiName,
        relationshipField: childObject.relationshipField
    };
    return getRelatedListConfigurationUtil(self, recordId, childObjectConfiguration);
}