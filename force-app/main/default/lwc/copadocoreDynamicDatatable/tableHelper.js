import { handleAsyncError } from 'c/copadocoreUtils';

import { getColumnsConfig, getRowsData } from './utils';

import Fetch_Columns_Config_Error from '@salesforce/label/c.Fetch_Columns_Config_Error';
import Fetch_Data_Error from '@salesforce/label/c.Fetch_Data_Error';

export default class TableHelper {
    label = {
        Fetch_Columns_Config_Error,
        Fetch_Data_Error
    };

    get columnsConfiguration() {
        return {
            columnsConfiguration: {
                objectApiName: this.objectApiName,
                fieldSetName: this.fieldSetName,
                hideDefaultColumnsActions: this.hideDefaultColumnsActions,
                sortable: this.sortable,
                editable: this.editable,
                searchable: this.searchable
            }
        };
    }

    get queryConfig() {
        return {
            queryConfig: {
                selectFieldSet: this.fieldSetName,
                fromObject: this.objectApiName,
                relationshipField: this.relationshipField,
                parentId: this.parentId,
                orderBy: this.orderBy,
                recordsLimit: this.recordsLimit,
                recordsOffset: this.recordsOffset
            }
        };
    }

    constructor(parentComponentInstance) {
        this.parentComponentInstance = parentComponentInstance;
    }

    // BUILDER SETTERS

    objectApiName(objectApiName) {
        this.objectApiName = objectApiName;
        return this;
    }

    fieldSetName(fieldSetName) {
        this.fieldSetName = fieldSetName;
        return this;
    }

    hideDefaultColumnsActions(hideDefaultColumnsActions) {
        this.hideDefaultColumnsActions = hideDefaultColumnsActions;
        return this;
    }

    sortable(sortable) {
        this.sortable = sortable;
        return this;
    }

    editable(editable) {
        this.editable = editable;
        return this;
    }

    searchable(searchable) {
        this.searchable = searchable;
        return this;
    }

    relationshipField(relationshipField) {
        this.relationshipField = relationshipField;
        return this;
    }

    parentId(parentId) {
        this.parentId = parentId;
        return this;
    }

    orderBy(orderBy) {
        this.orderBy = orderBy;
        return this;
    }

    recordsLimit(recordsLimit) {
        this.recordsLimit = recordsLimit;
        return this;
    }

    recordsOffset(recordsOffset) {
        this.recordsOffset = recordsOffset;
        return this;
    }

    // PUBLIC

    async getColumnsConfig() {
        const safeFetchColumnsConfig = handleAsyncError(getColumnsConfig, {
            title: this.label.Fetch_Columns_Config_Error
        });

        return safeFetchColumnsConfig(this.parentComponentInstance, this.columnsConfiguration);
    }

    async getRowsData() {
        const safeFetchData = handleAsyncError(getRowsData, {
            title: this.label.Fetch_Data_Error
        });

        return safeFetchData(this.parentComponentInstance, this.queryConfig);
    }
}