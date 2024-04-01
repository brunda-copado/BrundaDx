import { LightningElement, api } from 'lwc';

import getJobExecutionIds from '@salesforce/apex/PromotionJobExecutionsCtrl.getJobExecutionIds';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import { getColumnsConfiguration, getUpgradedColumnConfiguration, getRowsData, loadMoreData, getSortedData } from 'c/datatableService';
import { label, schema, constants } from './constants';

export default class PromotionJobExecutions extends LightningElement {
    @api recordId;
    @api fieldset;

    // TEMPLATE
    showSpinner = true;
    keyField = constants.KEY_FIELD;
    columns = [];
    data = [];
    iconName = constants.ICON_NAME;
    rows = [];
    defaultSortDirection = constants.DEFAULT_SORT_DIRECTION;
    sortDirection = constants.DEFAULT_SORT_DIRECTION;
    sortedBy = constants.DEFAULT_SORT_FIELD;

    // PRIVATE
    _isLoadingInProgress = false;
    _hasMoreData = true;
    _recordsOffset = 0;
    _recordSize = 20;
    _recordTypeName;

    get relatedListTitle() {
        return label.JOB_EXECUTIONS;
    }

    get title() {
        return this.relatedListTitle + ' (' + this.rowsCount + ')';
    }

    get hasData() {
        return this.data && this.data.length ? true : false;
    }

    get items() {
        return this.hasData ? this.rowsCount + ' ' + label.ITEMS : '';
    }

    get rowsCount() {
        return this.data && this.data.length ? this.data.length + (this._hasMoreData ? '+' : '') : '0';
    }

    async connectedCallback() {
        await this._fetchColumnConfigurations();
        await this._fetchDataRows();
        this.allRows = JSON.parse(JSON.stringify(this.rows));
        this._prepareData(this.allRows);
        this.showSpinner = false;
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this._applySort({ name: sortedBy, sortDirection: sortDirection });
    }

    handleLoadMoreData(event) {
        this._isLoadingInProgress = true;
        let rows = this.allRows;
        this._loadMore(event, rows);
    }

    async _fetchColumnConfigurations() {
        try {
            const columnsConfiguration = {
                objectApiName: schema.JOB_EXECUTION.objectApiName,
                fieldSetName: this.fieldset,
                hideDefaultColumnsActions: constants.HIDE_DEFAULT_COLUMNS_ACTION,
                sortable: constants.SORTABLE,
                editable: constants.ENABLE_INLINE_EDITING,
                searchable: constants.SEARCHABLE,
                filterable: constants.FILTERABLE
            };
            const data = await getColumnsConfiguration(this, columnsConfiguration);
            if (data && data.length) {
                this.columns = getUpgradedColumnConfiguration(data, [], false);
            } else {
                showToastError(this, { message: String.format(label.NO_COLUMN_CONFIG_ERROR, this.fieldset) });
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async _fetchDataRows() {
        try {
            const jobExecutionIds = await getJobExecutionIds({ promotionId: this.recordId });
            if (jobExecutionIds.length !== 0) {
                const queryConfig = {
                    fieldSetName: this.fieldset,
                    objectApiName: schema.JOB_EXECUTION.objectApiName,
                    relationshipFieldApi: schema.ID_FIELD.fieldApiName,
                    recordIds: jobExecutionIds,
                    orderBy: constants.ORDER_BY,
                    numberOfRecordsLimit: constants.NUMBER_OF_RECORDS_LIMIT,
                    recordsOffset: 0
                };
                const data = await getRowsData(this, queryConfig);
                if (data) {
                    this.rows = data;
                }
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: label.FETCH_DATA_ERROR + ': ' + errorMessage });
        }
    }

    _prepareData(rows) {
        const data = rows.slice(0, this._recordSize);
        this.data = JSON.parse(JSON.stringify(data));
        this._recordsOffset = this.data.length;
    }

    _applySort(fieldConfiguration) {
        if (this.data && this.data) {
            let cloneData = [];

            cloneData = this.allRows;
            this.allRows = [];
            this.data = [];
            const sortedData = getSortedData(this.columns, cloneData, fieldConfiguration);
            this.allRows = JSON.parse(JSON.stringify(sortedData));
            this._prepareData(sortedData);
        }
        this.sortDirection = fieldConfiguration.sortDirection;
        this.sortedBy = fieldConfiguration.name;
    }

    async _loadMore(event, row) {
        try {
            if (!this._isLoadingInProgress) {
                return;
            }
            const configuration = {
                recordsOffset: this._recordsOffset,
                recordSize: this._recordSize
            };
            if (this._recordsOffset < row.length) {
                const moreData = await loadMoreData(event, row, configuration);
                if (moreData && moreData.length && this._isLoadingInProgress) {
                    this.data = JSON.parse(JSON.stringify(moreData));
                    this._recordsOffset = this.data.length;
                    this._isLoadingInProgress = false;
                    if (this._recordsOffset === row.length) {
                        this._hasMoreData = false;
                    }
                }
            } else {
                this._hasMoreData = false;
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }
}