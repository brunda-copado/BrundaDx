import { LightningElement, api, wire } from 'lwc';

import { reduceErrors } from 'c/copadocoreUtils';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import alertMessage from '@salesforce/messageChannel/CopadoAlert__c';
import { showToastError } from 'c/copadocoreToastNotification';
import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';
import { getColumnsConfiguration, getUpgradedColumnConfiguration, getRowsData, loadMoreData, getSortedData } from 'c/datatableService';

import userStoryIds from '@salesforce/apex/PromotionUserStoryMetadatasHandler.getUserStoryIds';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

import { label, constants, schema } from './constants';

export default class PromotionUserStoryMetadatasContainer extends NavigationMixin(LightningElement) {
    @api recordId;
    @api fieldset = schema.FIELD_SET_NAME;

    communicationId = 'promotionRecordPageAlerts';

    label = label;
    schema = schema;

    orderBy = constants.ORDER_BY;
    keyField = constants.KEY_FIELD;
    defaultSortDirection = constants.DEFAULT_SORT_DIRECTION;
    sortDirection = constants.DEFAULT_SORT_DIRECTION;
    sortedBy = constants.DEFAULT_SORT_FIELD;
    relationshipField = schema.USER_STORY_METADATA_USER_STORY_FIELD;

    showSpinner;
    fileData = [];
    allRows = [];
    rows = [];
    columns = [];
    data = [];
    filteredData = [];
    selectedRows = [];
    searchValue = '';
    searchDataCount = 0;
    isSearchInProgress = false;

    _recordsOffset = 0;
    _recordSize = constants.NUMBER_OF_RECORDS_LIMIT;
    _isLoadingInProgress = false;
    _hasMoreData = true;
    _versionId;

    get rowsCount() {
        return this.data && this.data.length ? this.data.length + (this._hasMoreData ? '+' : '') : '0';
    }

    get hasData() {
        return this.isSearchInProgress || (this.data && this.data.length) ? true : false;
    }

    get title() {
        return constants.RELATED_LIST_NAME + ' (' + this.rowsCount + ')';
    }

    get items() {
        return this.hasData ? this.rowsCount + ' ' + label.ITEMS : '';
    }

    get removeSelectedDisabled() {
        return this.selectedRows.length === 0;
    }

    @wire(CurrentPageReference) pageRef;

    @wire(MessageContext)
    messageContext;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: schema.RESULT_DOC_RELATIONSHIP,
        fields: [
            `${schema.LATEST_PUBLISHED_VERSION_FIELD.objectApiName}.${schema.LATEST_PUBLISHED_VERSION_FIELD.fieldApiName}`,
            `${schema.TITLE_FIELD.objectApiName}.${schema.TITLE_FIELD.fieldApiName}`
        ]
    })
    documentLinksInfo({ error, data }) {
        if (data) {
            if (data.records?.length) {
                let ignoredChangeDoc = data.records.find(doc => getFieldValue(doc, schema.TITLE_FIELD).includes(constants.IGNORED_CHANGES_FILE_NAME));
                if (ignoredChangeDoc) {
                    this._versionId = getFieldValue(ignoredChangeDoc, schema.LATEST_PUBLISHED_VERSION_FIELD);
                }
            }
        } else if (error) {
            showToastError(this, { message: constants.FETCH_DATA_ERROR + ': ' + reduceErrors(error) });
        }
    }

    @wire(getRecord, { recordId: '$_versionId', fields: [schema.VERSION_DATA_FIELD, schema.CONTENT_SIZE_FIELD] })
    wiredVersion({ data, error }) {
        if (data) {
            const size = getFieldValue(data, schema.CONTENT_SIZE_FIELD);
            if (size < constants.MAX_FILE_SIZE_SUPPORTED) {
                const ldata = getFieldValue(data, schema.VERSION_DATA_FIELD);
                this.fileData = this.b64DecodeUnicode(ldata);
            } else {
                showToastError(this, { message: constants.FETCH_DATA_ERROR + ': ' + constants.IGNORED_CHANGES_FILE_NAME });
            }
        } else {
            showToastError(this, { message: constants.FETCH_DATA_ERROR + ': ' + reduceErrors(error) });
        }
    }

    b64DecodeUnicode(str) {
        return decodeURIComponent(
            atob(str)
                .split('')
                .map(function (c) {
                    return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
                })
                .join('')
        );
    }

    connectedCallback() {
        this.showSpinner = true;
        this._fetchRelatedListConfiguration();

        // subscribe to userStoryAddedEvent event
        registerListener('userStoryAddedEvent', this.handleRefreshData, this);
        // subscribe to userStoryRemovedEvent event
        registerListener('userStoryRemovedEvent', this.handleRefreshData, this);
    }

    disconnectedCallback() {
        // unsubscribe from userStoryAddedEvent and userStoryRemovedEvent event
        unregisterAllListeners(this);
    }

    handleApplySearch(event) {
        this._hasMoreData = true;
        const searchObj = event.detail;
        this.searchValue = searchObj.searchTerm;
        this.data = [];
        this._recordsOffset = 0;
        this.filteredData = searchObj.searchedData;
        this.searchDataCount = searchObj.searchDataCount;
        this.isSearchInProgress = true;
        this._applySort({ name: this.sortedBy, sortDirection: this.sortDirection });
    }

    handleClearSearch() {
        this._hasMoreData = true;
        this._recordsOffset = 0;
        this.allRows = [];
        this.data = [];
        this.filteredData = [];
        this.searchValue = '';
        this.isSearchInProgress = false;
        this.searchDataCount = 0;
        this.allRows = [...this.rows];
        this._applySort({ name: this.sortedBy, sortDirection: this.sortDirection });
    }

    handleDefaultFilter(event) {
        this._hasMoreData = true;
        this._recordsOffset = 0;
        this.allRows = [];
        this.data = [];
        this.filteredData = [];
        this.searchValue = '';
        this.isSearchInProgress = false;
        this.searchDataCount = 0;
        const searchObj = event.detail;
        this.rows = searchObj.searchedData;
        this.allRows = [...this.rows];
        this._applySort({ name: this.sortedBy, sortDirection: this.sortDirection });
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this._applySort({ name: sortedBy, sortDirection: sortDirection });
    }

    handleLoadMoreData(event) {
        this._isLoadingInProgress = true;
        let rows = this.allRows;
        if (this.isSearchInProgress) {
            rows = this.filteredData;
        }
        this._loadMore(event, rows);
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    handleReviewConflict() {
        let pageUrl = '/apex/' + schema.NAMESPACE + 'ResolveConflicts?promotionId=' + this.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: pageUrl
            }
        });
    }

    handleRemoveChanges() {
        const removeSelectedPopup = this.template.querySelector('c-promotion-user-story-metadatas-removal-modal');

        if (removeSelectedPopup) {
            removeSelectedPopup.changes = this.selectedRows;
            removeSelectedPopup.rowsCount = this.data.length === this.allRows.length ? this.data.length : this.allRows.length;
            removeSelectedPopup.show();
        }
    }

    handleRefreshData() {
        this.showSpinner = true;
        this._fetchDataRows();
    }

    async handleRefresh() {
        this.showSpinner = true;
        this.selectedRows.forEach(item => {
            this.data = this.data.filter(record => record.Id !== item.Id);
            this.allRows = this.allRows.filter(record => record.Id !== item.Id);
        });
        this.template.querySelector('lightning-datatable').selectedRows = [];
        this.selectedRows.length = 0;
        this.showSpinner = false;
    }

    // PRIVATE

    _prepareData(rows) {
        const data = rows.slice(0, this._recordSize);
        this.data = JSON.parse(JSON.stringify(data));
        this._recordsOffset = this.data.length;
    }

    _applySort(fieldConfiguration) {
        if (this.data && this.data) {
            let cloneData = [];

            if (this.isSearchInProgress) {
                cloneData = this.filteredData;
                this.filteredData = [];
            } else {
                cloneData = this.allRows;
                this.allRows = [];
            }
            this.data = [];
            const sortedData = getSortedData(this.columns, cloneData, fieldConfiguration);
            if (this.isSearchInProgress) {
                this.filteredData = JSON.parse(JSON.stringify(sortedData));
            } else {
                this.allRows = JSON.parse(JSON.stringify(sortedData));
            }
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

    async _fetchRelatedListConfiguration() {
        try {
            this._fetchColumnConfigurations();
        } catch (error) {
            console.error(error);
            const errorMessage = reduceErrors(error);
            this._handleError(constants.RELATED_LIST_ERROR + ': ' + errorMessage);
        }
    }

    async _fetchColumnConfigurations() {
        try {
            const columnsConfiguration = {
                objectApiName: schema.USER_STORY_METADATA,
                fieldSetName: this.fieldset,
                hideDefaultColumnsActions: constants.HIDE_DEFAULT_COLUMNS_ACTION,
                sortable: constants.SORTABLE,
                editable: constants.ENABLE_INLINE_EDITING,
                searchable: constants.SEARCHABLE,
                filterable: constants.FILTERABLE
            };
            const data = await getColumnsConfiguration(this, columnsConfiguration);
            if (data && data.length) {
                const columnConfigs = getUpgradedColumnConfiguration(data, [], false);
                this.columns = columnConfigs;
                this._fetchDataRows();
            } else {
                this._handleError(String.format(constants.NO_COLUMN_CONFIG_ERROR, this.fieldset));
            }
        } catch (error) {
            this.showSpinner = false;
            console.error(error);
            const errorMessage = reduceErrors(error);
            this._handleError(constants.FETCH_COLUMN_CONFIG_ERROR + ': ' + errorMessage);
        }
    }

    async _fetchDataRows() {
        try {
            const promotionId = this.recordId;
            let usIds = await userStoryIds({ promotionId });
            this.rows = [];
            this.allRows = [];
            if (usIds.length !== 0) {
                const queryConfig = {
                    fieldSetName: this.fieldset,
                    objectApiName: schema.USER_STORY_METADATA,
                    relationshipFieldApi: schema.USER_STORY_METADATA_USER_STORY_FIELD.fieldApiName,
                    recordIds: usIds,
                    orderBy: this.orderBy,
                    numberOfRecordsLimit: 10000,
                    recordsOffset: 0
                };
                this.queryConfig = queryConfig;
                const data = await getRowsData(this, queryConfig);

                if (data) {
                    this.rows = this._removeIgnoredChanges(data);
                    this.allRows = JSON.parse(JSON.stringify(this.rows));
                }
            }
            this._prepareData(this.allRows);
            this.showSpinner = false;
        } catch (error) {
            this.showSpinner = false;
            console.error(error);
            const errorMessage = reduceErrors(error);
            this._handleError(constants.FETCH_DATA_ERROR + ': ' + errorMessage);
        }
    }

    _removeIgnoredChanges(data) {
        let result = data;
        if (this.fileData.length) {
            let fileMetadata = JSON.parse(this.fileData);
            fileMetadata.forEach(metadata => {
                result = result.filter(
                    record =>
                        record[schema.USER_STORY_METADATA_API_NAME_FIELD.fieldApiName] !== metadata.n ||
                        record[schema.USER_STORY_METADATA_TYPE_FIELD.fieldApiName] !== metadata.t ||
                        record[schema.USER_STORY_METADATA_ACTION_FIELD.fieldApiName] !== metadata.a ||
                        record[schema.USER_STORY_METADATA_USER_STORY_FIELD.fieldApiName.replace('__c', '__r')][
                            schema.USER_STORY_NAME_FIELD.fieldApiName
                        ] !== metadata.u
                );
            });
        }
        return result;
    }

    _handleError(message) {
        this._publishFlexiPageAlert(this._prepareAlert(message, constants.ERROR_VARIANT, true));
    }

    _publishFlexiPageAlert(alert) {
        publish(this.messageContext, alertMessage, alert);
    }

    _prepareAlert(message, variant, isDismissible) {
        return {
            message: message,
            variant: variant,
            dismissible: isDismissible,
            communicationId: this.communicationId
        };
    }
}