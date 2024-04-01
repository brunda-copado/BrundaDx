/* eslint-disable guard-for-in */
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';
import { showToastSuccess } from 'c/copadocoreToastNotification';
import { handleAsyncError, removeSpecialChars } from 'c/copadocoreUtils';

import { update, sortBy } from './utils';

import TableHelper from './tableHelper';
import ColumnsProcessor from './columnsProcessor';
import DataProcessor from './dataProcessor';

import Update_Record_Error_Title from '@salesforce/label/c.Update_Record_Error_Title';
import Records_Updated_Successfully from '@salesforce/label/c.Records_Updated_Successfully';
import Loading from '@salesforce/label/c.LOADING';
import VIEW from '@salesforce/label/c.VIEW';
import EDIT from '@salesforce/label/c.EDIT';
import DELETE from '@salesforce/label/c.DELETE';

/*eslint no-extend-native: ["error", { "exceptions": ["Array"] }]*/
Array.prototype.move = function (from, to) {
    this.splice(to, 0, this.splice(from, 1)[0]);
    return this;
};

const actions = [
    { label: VIEW, name: 'view' },
    { label: EDIT, name: 'edit' },
    { label: DELETE, name: 'delete' }
];

export default class CopadocoreDynamicDatatable extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    label = {
        Update_Record_Error_Title,
        Records_Updated_Successfully,
        Loading
    };

    // Required
    @api recordId;
    @api relatedList;
    @api fieldset;

    // Optional
    @api lookUpObjectApi; // (Not used if tableInfo is provided)
    @api orderBy = 'Id ASC NULLS LAST, CreatedDate'; // (Not used if tableInfo is provided)
    @api recordSize = 6;
    @api heightStyle = 'auto';

    // Optional, datatable specific
    @api showRowNumberColumn;
    @api hideCheckboxColumn; // (Not used if tableInfo is provided)
    @api resizeColumnDisabled;
    @api enableInfiniteLoading;

    // Optional, columns specific
    @api hideDefaultColumnsActions;
    @api searchable;
    @api sortable;
    @api enableInlineEditing;

    // Optional, not available for manual input
    @api actions = actions;
    @api implementsDragAndDrop;
    @api customHandleSave;

    columns = [];
    data = [];
    draftValues = [];

    sortedDirection = 'asc';
    sortedBy;

    showSpinner;

    _recordsOffset = 0;
    _allRows;
    _allRowsSearchApplied;
    _rowsToSlice = '_allRows';
    // Assigned the first time that "loadMoreData" is called
    _table;
    _searchTerm = '';

    /**
     * Deprecated: cannot be removed due to managed package
     */
    @api height = '750';
    @api showFilter;
    @api showSearch;

    // If provided, other required attributes will be ignored
    _tableInfo;
    @api get tableInfo() {
        return this._tableInfo;
    }

    set tableInfo(value) {
        this._tableInfo = value;
        if (value) {
            this._recordsOffset = 0;
            this.data = [];
            this.draftValues = [];
            this._applyTableInfo();
        }
    }

    get tableHelper() {
        return new TableHelper(this)
            .objectApiName(this.relatedList)
            .fieldSetName(this.fieldset)
            .hideDefaultColumnsActions(this.hideDefaultColumnsActions)
            .sortable(this.sortable)
            .editable(this.enableInlineEditing)
            .searchable(this.searchable)
            .relationshipField(this.lookUpObjectApi)
            .parentId(this.recordId)
            .orderBy(this.orderBy)
            .recordsLimit(this.numberOfRecords + 1)
            .recordsOffset(this._recordsOffset);
    }

    @api get tableComponent() {
        return this.template.querySelector('c-copadocore-datatable-extended') || this.template.querySelector('lightning-datatable');
    }

    get containerStyle() {
        return `height: ${this.heightStyle};`;
    }

    get isDraggable() {
        return this.implementsDragAndDrop || this.tableInfo?.implementsDragAndDrop;
    }

    // If this.recordSize is received from the parent, we need to parse it from string to number: Number(this.recordSize)
    get numberOfRecords() {
        return Number(this.recordSize);
    }

    async connectedCallback() {
        // Retrieve table information in connectedCallback instead of wired methods
        // to be able to set properly the showSpinner value and because we also need
        // to retrieve data imperatively for "onloadmore" event
        this.showSpinner = true;
        if (this.recordId) {
            await this._setTableInformation();
        }
        this.showSpinner = false;

        registerListener('dropRowEvent', this._switchRowsAfterDrag, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    // API EXPOSED

    @api handleRefresh() {
        this._setData();
    }

    @api
    handleSearch(searchTerm) {
        this._searchTerm = removeSpecialChars(searchTerm.toLowerCase());
        this._applySearch();
    }

    // PUBLIC

    handleRowSelection(event) {
        this.dispatchEvent(new CustomEvent('rowselection', event));
    }

    handleHeaderAction(event) {
        this.dispatchEvent(new CustomEvent('headeraction', event));
    }

    handleRowAction(event) {
        // Deep cloned to avoid sending a reference
        event.detail.tableRows = JSON.parse(JSON.stringify(this.data));
        this.dispatchEvent(new CustomEvent('rowaction', event));
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];
        // This is to properly order lookup columns from a user perspective
        // Not using replace('Link', '') because matching the whole word is safer
        cloneData.sort(sortBy(sortedBy.replace('LinkName', 'Name'), sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortedDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    async loadMoreData(event) {
        // event.target is null after await so we save it in a variable
        this._table = event.target;
        this._table.isLoading = true;

        if (this.tableInfo) {
            if (this._recordsOffset < this[this._rowsToSlice].length) {
                this._sliceRowsIntoData();
            } else {
                this._table.enableInfiniteLoading = false;
            }
        } else {
            const data = await this.tableHelper.getRowsData();

            if (data?.length > 0) {
                const retrievedRowsEvent = new CustomEvent('retrievedrows', {
                    detail: {
                        numberOfRecordsRetrieved: data.length
                    }
                });
                this.dispatchEvent(retrievedRowsEvent);

                if (data.length > this.numberOfRecords) {
                    data.pop();
                }

                const processedData = new DataProcessor(data).execute();
                this.data = [...this.data, ...processedData];
                this._allRows = [...this._allRows, ...processedData];
                this._applySearch(true);
                this._recordsOffset += this.numberOfRecords;
            } else {
                this._table.enableInfiniteLoading = false;
            }
        }

        this._table.isLoading = false;
    }

    async handleSave(event) {
        this.draftValues = [];

        if (this.customHandleSave) {
            this.dispatchEvent(new CustomEvent('inlineeditsave', event));
        } else {
            this.showSpinner = true;

            const safeUpdateRecords = handleAsyncError(update, {
                title: this.label.Update_Record_Error_Title
            });

            const records = event.detail.draftValues;
            const result = await safeUpdateRecords(this, { records });
            // If it is null (because apex method returns void) or any other value,
            // it means that updateRecords is successful
            if (result !== undefined) {
                showToastSuccess(this, {
                    title: this.label.Records_Updated_Successfully
                });

                if (!this.tableInfo) {
                    await this._setData();
                }

                this.dispatchEvent(new CustomEvent('recordsupdated'));

                const notifyChangeIds = records.map((row) => ({ recordId: row.Id }));

                getRecordNotifyChange(notifyChangeIds);
            }
            this.showSpinner = false;
        }
    }

    // PRIVATE

    _applyTableInfo() {
        this.columns = JSON.parse(
            JSON.stringify(new ColumnsProcessor(this.tableInfo.columns, this.tableInfo.actions, this.tableInfo.implementsDragAndDrop).execute())
        );

        if (this.tableInfo.rows) {
            this._allRows = new DataProcessor(this.tableInfo.rows).execute();
            this._sliceRowsIntoData();
            this._applySearch(true);
        }

        if (this._table) {
            this._table.enableInfiniteLoading = true;
        }
    }

    _sliceRowsIntoData() {
        this._recordsOffset += this.numberOfRecords;
        const currentDataLength = this.data.length;
        this.data = this[this._rowsToSlice].slice(0, this._recordsOffset);
        const retrievedRowsEvent = new CustomEvent('retrievedrows', {
            detail: {
                numberOfRecordsRetrieved: this[this._rowsToSlice].slice(currentDataLength, this._recordsOffset + 1).length
            }
        });
        this.dispatchEvent(retrievedRowsEvent);
    }

    async _applySearch(avoidRefresh) {
        this.showSpinner = true;

        if (avoidRefresh && this._searchTerm === '') {
            this._rowsToSlice = '_allRows';
            const searchAppliedEvent = new CustomEvent('searchapplied', {
                detail: {
                    tableRows: JSON.parse(JSON.stringify(this._allRows)),
                    withoutChanges: true
                }
            });
            this.dispatchEvent(searchAppliedEvent);
        } else if (this._searchTerm === '') {
            this._rowsToSlice = '_allRows';
            if (this.tableInfo) {
                if (this._table) {
                    this._table.enableInfiniteLoading = true;
                }
                this._recordsOffset = 0;
                this.data.length = 0;
                this._sliceRowsIntoData();
                const searchAppliedEvent = new CustomEvent('searchapplied', {
                    detail: {
                        tableRows: JSON.parse(JSON.stringify(this._allRows)),
                        numberOfRecordsRetrieved: this._allRows.slice(0, this.data.length + 1).length,
                        isRefresh: true
                    }
                });
                this.dispatchEvent(searchAppliedEvent);
            } else {
                await this._setData();
            }
        } else if (this._searchTerm.length >= 2) {
            const rows = [];

            this._allRows.forEach((row) => {
                for (const field in row) {
                    const col = this.columns.find((column) => column.fieldName === field);
                    if (col?.searchable) {
                        const urlLabelField = col?.typeAttributes?.label?.fieldName;
                        const matchUrlLabel = removeSpecialChars(row[urlLabelField]?.toLowerCase())?.includes(this._searchTerm);
                        const matchFieldValue =
                            !field.includes('LinkName') && removeSpecialChars((row[field] + '').toLowerCase())?.includes(this._searchTerm);
                        if (matchUrlLabel || matchFieldValue) {
                            rows.push(row);
                            break;
                        }
                    }
                }
            });

            /**
             * TODO: Improve this. Add lazy loading too when recordId
             */
            let searchAppliedEvent;
            if (this.recordId) {
                this.data = rows;
                searchAppliedEvent = new CustomEvent('searchapplied', {
                    detail: {
                        tableRows: JSON.parse(JSON.stringify(this.data)),
                        numberOfRecordsRetrieved: this.data.length
                    }
                });
            } else {
                this._allRowsSearchApplied = rows;
                this._rowsToSlice = '_allRowsSearchApplied';
                this._recordsOffset = 0;
                this.data.length = 0;
                this._sliceRowsIntoData();
                searchAppliedEvent = new CustomEvent('searchapplied', {
                    detail: {
                        tableRows: JSON.parse(JSON.stringify(this._allRowsSearchApplied)),
                        numberOfRecordsRetrieved: this._allRowsSearchApplied.slice(0, this.data.length + 1).length,
                        isRefresh: true
                    }
                });
            }
            this.dispatchEvent(searchAppliedEvent);
        }

        this.showSpinner = false;
    }

    async _setTableInformation() {
        await Promise.all([this._setColumns(), this._setData()]);
    }

    async _setColumns() {
        const columns = await this.tableHelper.getColumnsConfig();
        this.columns = new ColumnsProcessor(columns, this.actions, this.implementsDragAndDrop).execute();
    }

    async _setData() {
        // Reset in case we are refreshing the data
        this._recordsOffset = 0;
        const data = await this.tableHelper.getRowsData();

        if (data) {
            const retrievedRowsEvent = new CustomEvent('retrievedrows', {
                detail: {
                    numberOfRecordsRetrieved: data.length
                }
            });
            this.dispatchEvent(retrievedRowsEvent);

            if (data.length > this.numberOfRecords) {
                data.pop();
            }

            this.data = new DataProcessor(data).execute();
            this._allRows = [...this.data];
            this._applySearch(true);
            this._recordsOffset += this.numberOfRecords;
        }

        if (this._table) {
            this._table.enableInfiniteLoading = true;
        }
    }

    _switchRowsAfterDrag(detail) {
        const draggingBeginsAt = detail.draggingBeginsAt;
        const draggingEndsAt = detail.draggingEndsAt;

        if (draggingBeginsAt === draggingEndsAt) {
            return;
        }

        this.data = this.data.move(draggingBeginsAt, draggingEndsAt);

        const dropRowEvent = new CustomEvent('droprow', {
            // Deep cloned to avoid sending a reference
            detail: { tableRows: JSON.parse(JSON.stringify(this.data)) }
        });
        this.dispatchEvent(dropRowEvent);
    }
}