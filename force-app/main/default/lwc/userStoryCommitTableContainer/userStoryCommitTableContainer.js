import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { MessageContext, subscribe, publish } from 'lightning/messageService';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { namespace, reduceErrors } from 'c/copadocoreUtils';
import { getSortedData } from 'c/datatableService';
import { flushPromises } from 'c/copadocoreUtils';

import { label } from './constants';
import {
    combineRows,
    createSelectedResult,
    parseUserStoryMetadata,
    prepareRows,
    getColumns,
    getDefaultSortedByFieldName,
    createDraftValue,
    upsertDraftValue
} from './utils';

import getUserStoryMetadata from '@salesforce/apex/UserStoryCommitCtrl.getUserStoryMetadata';

import COMMIT_PAGE_COMMUNICATION_CHANNEL from '@salesforce/messageChannel/CommitPageCommunication__c';

const MIN_HEIGHT_TABLE = 25;

export default class UserStoryCommitTableContainer extends LightningElement {

    label = label;
    recordId;
    isLoading = false;

    // table
    keyField = 'Id'; // TODO: extensions should make sure this property exists in the data
    get columns() {
        return getColumns();
    }
    get tableRows() {
        return this.currentSelectedEnabled
            ? this.allRows.filter((row) => this.selectedRows.some((selectedRowId) => selectedRowId === row[this.keyField]))
            : this.rows;
    }

    rows = [];
    get availableRows() {
        return this.searchTerm
            ? this.activeFilter
                ? this._intersect(this.searchedRows, this.filteredRows)
                : this.searchedRows
            : this.activeFilter
            ? this.filteredRows
            : this.allRows;
    }
    filteredRows = [];
    searchedRows = [];
    allRows = [];

    previousSelectionRows = [];
    selectedRows = [];

    // sorting
    defaultSortDirection = 'asc';
    sortDirection = 'desc';
    get sortedBy() {
        if (!this._sortedBy) {
            return getDefaultSortedByFieldName();
        }
        return this._sortedBy;
    }
    set sortedBy(value) {
        this._sortedBy = value;
    }
    _sortedBy;

    // searching
    searchTerm = '';

    // filtering
    activeFilter = false;
    _filteredBy = []; // array of fieldƒ names

    // lazy loading
    _table;
    _batchSize = 50;
    _rowOffset = 0;
    _hasMoreData = false;

    // edit mode
    draftValues = [];

    // dynamic height
    _nonFreeHeight;
    _tableStartsAt;

    // current selections
    currentSelectedEnabled = false;

    get tableTitle() {
        return label.FILES;
    }

    get tableInfo() {
        return this.numberOfItemsLabel + ' · ' + this.numberOfSelectedLabel + ' · ' + this.sortedByLabel + this.filteredByLabel;
    }

    get numberOfItemsLabel() {
        return this.rows.length + (this.rows.length < this.availableRows.length ? '+' : '') + ' ' + label.ITEMS;
    }

    get numberOfSelectedLabel() {
        return this.selectedRows.length + ' ' + label.SELECTED;
    }

    get sortedByLabel() {
        return label.SORTED_BY + ' ' + this.sortedByColumnLabel;
    }

    get filteredByLabel() {
        return this._filteredBy.length > 0 && this._filteredBy.length <= 3
            ? ' · ' + label.FILTERED_BY + ' ' + this.filteredByColumnLabel
            : this._filteredBy.length > 3
            ? ' · ' + label.MORE_THAN_3_FILTERS_APPLIED
            : '';
    }

    get sortedByColumnLabel() {
        const column = this.columns.find((tableColumn) => tableColumn.fieldName === this.sortedBy);
        return column ? column.label : this.sortedBy;
    }

    get filteredByColumnLabel() {
        const columns = this.columns.filter((tableColumn) => this._filteredBy.includes(tableColumn.fieldName));
        return columns ? columns.map((column) => column.label).join(', ') : '';
    }

    get previousSelectionsToggleDisabled() {
        return !this.previousSelectionRows || this.previousSelectionRows.length === 0;
    }

    get previousSelectionsHelpText() {
        return this.previousSelectionsToggleDisabled ? label.PREVIOUS_SELECTIONS_HELP_TEXT_DISABLED : label.PREVIOUS_SELECTIONS_HELP_TEXT;
    }

    get noItems() {
        return this.rows.length === 0;
    }

    get heightStyle() {
        return `height: calc(100vh - ${this._nonFreeHeight}px);min-height: calc(100vh - ${MIN_HEIGHT_TABLE}rem);`;
    }

    @wire(MessageContext)
    _context;

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        if (pageReference && pageReference.state) {
            const parameterName = `${namespace || 'c__'}recordId`;
            this.recordId = pageReference.state[parameterName];
            // Note: if same app page is used but the US is different, reset all inputs
            this._resetInputs();
        }
    }

    @wire(getUserStoryMetadata, { recordId: '$recordId' })
    getPreviousSelections({ data, error }) {
        if (data) {
            let metadataRows = parseUserStoryMetadata(data);
            metadataRows = prepareRows(this.recordId, metadataRows, this.keyField);
            this.previousSelectionRows = [...metadataRows];
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

   connectedCallback() {
        this._subscribeToMessageService();
    }

    renderedCallback() {
        this._calculateNonFreeHeight();
        window.addEventListener('resize', () => {
            this._calculateNonFreeHeight();
        });
    }

    // TEMPLATE

    handleTogglePreviousSelections() {
        this._performWithProgress(async () => {
            try {
                const checked = Array.from(this.template.querySelectorAll('[data-element="previous-selections-toggle"]')).some(
                    (element) => element.checked
                );
                if (checked) {
                    await this._addMetadataRowsToTable(this.previousSelectionRows);
                    this._addMetadataToSelectedRows(this.previousSelectionRows);
                } else {
                    this._removeMetadataFromSelectedRows(this.previousSelectionRows);
                }
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleToggleCurrentSelections() {
        this._performWithProgress(() => {
            try {
                this.currentSelectedEnabled = Array.from(this.template.querySelectorAll('[data-element="current-selections-toggle"]')).some(
                    (element) => element.checked
                );
                if (this.currentSelectedEnabled) {
                    this._hasMoreData = false;
                } else {
                    this._hasMoreData = this._rowOffset < this.availableRows.length;
                }
                // Note: without this the table is not re-rendering the select checkbox
                this.selectedRows = [...this.selectedRows];
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleSort(event) {
        this._performWithProgress(() => {
            try {
                this.sortDirection = event.detail.sortDirection;
                this.sortedBy = event.detail.fieldName;
                // Note: sort all lists to be in sync
                this.allRows = this._applySort(this.allRows, { name: this.sortedBy, sortDirection: this.sortDirection });
                this.searchedRows = this._applySort(this.searchedRows, { name: this.sortedBy, sortDirection: this.sortDirection });
                this.filteredRows = this._applySort(this.filteredRows, { name: this.sortedBy, sortDirection: this.sortDirection });
                this._refreshRows(false);
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleClearSearch() {
        this._performWithProgress(() => {
            try {
                this._clearSearch();
                this._refreshRows(false);
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleApplySearch(event) {
        this._performWithProgress(() => {
            try {
                const searchObj = event.detail;
                this.searchTerm = searchObj.searchTerm;
                this.searchedRows = [...searchObj.searchedData];
                this._refreshRows(false);
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleClearFilter() {
        this._performWithProgress(() => {
            try {
                this._clearFilters();
                this._refreshRows(false);
                showToastSuccess(this, { message: label.FILTER_TABLE_UPDATED });
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleApplyFilter(event) {
        this._performWithProgress(() => {
            try {
                this.activeFilter = true;
                const filterObj = event.detail;
                this._filteredBy = filterObj.filterFields;
                this.filteredRows = [...filterObj.searchedData];
                this._refreshRows(false);
                showToastSuccess(this, { message: label.FILTER_TABLE_UPDATED });
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleRowSelection(event) {
        const selectedIds = new Set(event.detail.selectedRows.map((row) => row[this.keyField]));
        const currentIds = new Set(this.tableRows.map((row) => row[this.keyField]));

        let idsToBeSelected = new Set(this.selectedRows);

        selectedIds.forEach((id) => idsToBeSelected.add(id));

        currentIds.forEach((id) => {
            if (idsToBeSelected.has(id) && !selectedIds.has(id)) {
                idsToBeSelected.delete(id);
            }
        });

        this.selectedRows = [...idsToBeSelected];
        this._setSelectedCount();
    }

    handleLoadMore(event) {
        try {
            if (!this._hasMoreData) {
                return;
            }
            this._table = event.target;

            if (this._table) {
                this._table.isLoading = true;
            }
            // workaround to show spinner
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this._loadMore();
                if (this._table) {
                    this._table.isLoading = false;
                }
            });
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleSave(event) {
        this._performWithProgress(() => {
            try {
                this._saveDrafValuesInAllLists(event.detail.draftValues);
                this._updateFilters();
                this._resetChanges();

            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    handleCancel() {
        this._resetChanges();
    }

    handleChangeDraftValue(event) {
        const rowId = event.detail.rowId;
        const property = event.detail.property;
        const value = event.detail.value;

        const newDraftValue = createDraftValue(rowId, property, value, this.keyField);
        const existingDraftValues = [...this.draftValues];
        this.draftValues = this._updateDraftValue(existingDraftValues, newDraftValue);

        this._setReadOnlyMode();
    }

    handleEditColumn(event) {
        const rowId = event.detail.rowId;
        const property = event.detail.property;
        const value = event.detail.value;

        const originalRowIndex = this.rows.findIndex((originalRow) => originalRow[this.keyField] === rowId);
        const originalRowWithUpdates = { ...this.rows[originalRowIndex], ReadOnlyMode: false };
        this.rows.splice(originalRowIndex, 1, originalRowWithUpdates);

        // Note: custom column needs to show the cancel in order to return to view mode
        const newDraftValue = createDraftValue(rowId, property, value, this.keyField);
        const existingDraftValues = [...this.draftValues];
        this.draftValues = this._updateDraftValue(existingDraftValues, newDraftValue);
    }

    handleCancelMultiEdit() {
        this._resetChanges();
    }

    handleChangeMultiDraftValue(event) {
        const rowId = event.detail.rowId;
        const property = event.detail.property;
        const value = event.detail.value;
        const updateSelected = event.detail.updateSelected;

        if (updateSelected) {
            let existingDraftValues = [...this.draftValues];
            this.selectedRows.forEach((selectedRowId) => {
                const newDraftValue = createDraftValue(selectedRowId, property, value, this.keyField);
                existingDraftValues = this._updateDraftValue(existingDraftValues, newDraftValue);
            });
            this.draftValues = existingDraftValues;
        } else {
            const newDraftValue = createDraftValue(rowId, property, value, this.keyField);
            const existingDraftValues = [...this.draftValues];
            this.draftValues = this._updateDraftValue(existingDraftValues, newDraftValue);
        }

        this._setReadOnlyMode();
    }

    // PRIVATE

    _subscribeToMessageService() {
        subscribe(this._context, COMMIT_PAGE_COMMUNICATION_CHANNEL, (message) => this._handleCommitPageCommunicationMessage(message));
    }

    _handleCommitPageCommunicationMessage(message) {
        this._performWithProgress(() => {
            try {
                switch (message.type) {
                    case 'request':
                        this._handleRequestMessage(message);
                        break;
                    // extension
                    case 'retrievedChanges':
                    case 'pulledChanges':
                        this._handleChangesMessage(message);
                        break;
                    case 'toggleSelectedFiles':
                        this.template.querySelector('[data-element="current-selections-toggle"]').checked = true;
                        this.handleToggleCurrentSelections();
                        break;
                    default:
                }
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        });
    }

    _handleRequestMessage() {
        const selectedChanges = this._getSelectedChanges();
        const payload = {
            type: 'changes',
            value: selectedChanges
        };
        publish(this._context, COMMIT_PAGE_COMMUNICATION_CHANNEL, payload);
    }

    async _handleChangesMessage(message) {
        const metadatas = message.value;
        const metadataRows = prepareRows(this.recordId, metadatas, this.keyField);
        await this._addMetadataRowsToTable(metadataRows);
        if(message?.preselect) {
            this._addMetadataToSelectedRows(metadataRows);
        }
    }

    async _addMetadataRowsToTable(metadataRows) {
        const combinedRows = combineRows(this.allRows, metadataRows, this.keyField);
        await this._setRows(combinedRows);
    }

    _removeMetadataRowsFromTable(metadataRows) {
        const difference = this.allRows.filter(
            (row) => metadataRows.some((metadataRow) => row[this.keyField] === metadataRow[this.keyField]) === false
        );
        this._setRows(difference);
    }

    _addMetadataToSelectedRows(rows) {
        const newSelections = rows.map((element) => element[this.keyField]);
        this.selectedRows = [...this.selectedRows, ...newSelections];
    }

    _removeMetadataFromSelectedRows(rows) {
        const newSelections = this.selectedRows.filter((rowId) => rows.some((metadataRow) => rowId === metadataRow[this.keyField]) === false);
        this.selectedRows = [...newSelections];
    }

    async _setRows(rows) {
        const sortedData = this._applySort(rows, { name: this.sortedBy, sortDirection: this.sortDirection });
        this.allRows = [...sortedData];
        // Note: setting rows in child components (search, filters) takes time, so we need to wait to ensure those components work with the latest value
        await flushPromises();
        this._clearSearch();
        this._clearFilters();
        this.rows = [...this.availableRows].slice(0, this._rowOffset + this._batchSize);
        this._rowOffset = this.rows.length;
        this._hasMoreData = this._rowOffset < this.availableRows.length;
    }

    _clearSearch() {
        this.searchTerm = '';
        this.searchedRows = [];

        const tableContainer = this.template.querySelector('c-datatable-container');
        if (tableContainer) {
            tableContainer.clearSearch();
        }
    }

    _clearFilters() {
        this.activeFilter = false;
        this.filteredRows = [];
        this._filteredBy = [];

        const tableContainer = this.template.querySelector('c-datatable-container');
        if (tableContainer) {
            tableContainer.clearFilters();
        }
    }

    _getSelectedChanges() {
        return this.selectedRows.map((metadataId) => {
            const selectedRow = this.allRows.find((row) => metadataId === row[this.keyField]);
            let result = {};
            if (selectedRow) {
                result = createSelectedResult(selectedRow);
            }
            return result;
        });
    }

    _applySort(rows, sortConfiguration) {
        return rows && rows.length ? getSortedData(this.columns, rows, sortConfiguration) : rows;
    }

    _loadMore() {
        if (this._rowOffset < this.availableRows.length) {
            this._refreshRows(true);
        } else {
            this._hasMoreData = false;
        }
    }

    _refreshRows(loadMore) {
        const size = loadMore || this._rowOffset === 0 ? this._rowOffset + this._batchSize : this._rowOffset;
        const moreData = this.availableRows.slice(0, size);
        this.rows = [...moreData];
        // Note: without this the table is not re-rendering the select checkbox
        this.selectedRows = [...this.selectedRows];
        this._rowOffset = this.rows.length;
        this._hasMoreData = this._rowOffset < this.availableRows.length;
    }

    _updateFilters() {
        const tableContainerElem = this.template.querySelector('c-datatable-container');
        tableContainerElem.rows = this.allRows;
        tableContainerElem.clearFilters();
    }

    _saveDrafValuesInAllLists(draftValues) {
        this._saveDraftValues(draftValues, this.allRows);
        this._saveDraftValues(draftValues, this.searchedRows);
        this._saveDraftValues(draftValues, this.filteredRows);
        this._saveDraftValues(draftValues, this.rows);
    }

    _saveDraftValues(draftValues, rows) {
        draftValues.forEach((updatedRow) => {
            const originalRowIndex = rows.findIndex((originalRow) => originalRow[this.keyField] === updatedRow[this.keyField]);
            const originalRowWithUpdates = { ...rows[originalRowIndex], ...updatedRow };
            rows.splice(originalRowIndex, 1, originalRowWithUpdates);
        });
        return rows;
    }

    // this will return the list of updated draft values, but not set the list on the table or the global array to improve performance
    _updateDraftValue(draftValues, newDraftValue) {
        const table = this.template.querySelector('c-user-story-commit-table');
        if (table) {
            table.draftValues.forEach((draftValue) => {
                draftValues = upsertDraftValue(draftValues, draftValue, this.keyField);
            });
        }
        draftValues = upsertDraftValue(draftValues, newDraftValue, this.keyField);
        if (table) {
            table.draftValues = draftValues;
        }
        return draftValues;
    }

    _resetChanges() {
        this.draftValues = [];
        this._setReadOnlyMode();
    }

    _setReadOnlyMode() {
        this.allRows = this.allRows.map((row) => {
            return { ...row, ReadOnlyMode: true };
        });
        this.searchedRows = this.searchedRows.map((row) => {
            return { ...row, ReadOnlyMode: true };
        });
        this.filteredRows = this.filteredRows.map((row) => {
            return { ...row, ReadOnlyMode: true };
        });
        this.rows = this.rows.map((row) => {
            return { ...row, ReadOnlyMode: true };
        });
    }

    _setSelectedCount() {
        const selectedCount = this.selectedRows.length;
        this.allRows.forEach((row) => {
            row.SelectedCount = selectedCount;
        });
        this.searchedRows.forEach((row) => {
            row.SelectedCount = selectedCount;
        });
        this.filteredRows.forEach((row) => {
            row.SelectedCount = selectedCount;
        });
        this.rows.forEach((row) => {
            row.SelectedCount = selectedCount;
        });
    }

    _resetInputs() {
        this.rows = [];
        this.allRows = [];
        this.searchedRows = [];
        this.filteredRows = [];
        this.previousSelectionRows = [];
        this.selectedRows = [];

        this.template.querySelectorAll('[data-element="previous-selections-toggle"]').forEach((element) => {
            if (element) {
                element.checked = false;
            }
        });

        this.defaultSortDirection = 'asc';
        this.sortDirection = 'desc';
        this._sortedBy = null;

        this.searchTerm = '';

        this._filteredBy = [];
        this.activeFilter = false;

        this._table = null;
        this._batchSize = 50;
        this._rowOffset = 0;
        this._hasMoreData = false;

        this.draftValues = [];
    }

    _calculateNonFreeHeight() {
        const margin = 20;
        this._tableStartsAt = this.template.querySelector('div[data-id*="table-container"]')?.getBoundingClientRect()?.top || 0;
        this._nonFreeHeight = this._tableStartsAt + margin;
    }

    _intersect(searchedRows, filteredRows) {
        return searchedRows.filter(
            (searchedRow) => filteredRows.some((filteredRow) => searchedRow[this.keyField] === filteredRow[this.keyField]) === true
        );
    }

    _performWithProgress(process) {
        this.isLoading = true;
        // workaround to show spinner
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if (process) {
                process();
            }
            this.isLoading = false;
        }, 0);
    }
}