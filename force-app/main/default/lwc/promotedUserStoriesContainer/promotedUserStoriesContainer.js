/* eslint-disable guard-for-in */
import { LightningElement, api, wire } from 'lwc';

import { reduceErrors } from 'c/copadocoreUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { showToastError } from 'c/copadocoreToastNotification';
import { getColumnsConfiguration, getUpgradedColumnConfiguration, getRowsData, getSortedData, loadMoreData } from 'c/datatableService';

import { label, schema, constants } from './constants';
import { refreshApex } from '@salesforce/apex';
import { getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PromotedUserStoriesContainer extends LightningElement {
    @api recordId;
    showSpinner;

    communicationId = 'promotionRecordPageAlerts';

    label = label;
    schema = schema;
    constants = constants;

    contentDocumentId;
    wiredDocumentLinksData;

    allData = [];
    allRows = [];
    selectedRows = [];
    data = [];
    filteredData = [];
    columns = [];
    isSearchInProgress = false;
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy = this.userStoryName;

    _fieldset = 'Promoted_User_Story_Datatable';
    _recordsOffset = 0;
    _recordSize = 25;
    _isLoadingInProgress = false;

    @wire(MessageContext)
    messageContext;

    @wire(CurrentPageReference) pageRef;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: schema.RESULT_DOC_RELATIONSHIP,
        fields: [
            `${schema.LATEST_PUBLISHED_VERSION_FIELD.objectApiName}.${schema.LATEST_PUBLISHED_VERSION_FIELD.fieldApiName}`,
            `${schema.TITLE_FIELD.objectApiName}.${schema.TITLE_FIELD.fieldApiName}`,
            `${schema.OWNER_ID.objectApiName}.${schema.OWNER_ID.fieldApiName}`,
            `${schema.CONTENT_DOCUMENT_ID_FIELD.objectApiName}.${schema.CONTENT_DOCUMENT_ID_FIELD.fieldApiName}`
        ]
    })
    documentLinksInfo(result) {
        this.wiredDocumentLinksData = result;
        const { data, error } = result;
        let fileId;
        if (data) {
            if (data.records?.length) {
                let ignoredChangeDoc = data.records.find((doc) =>
                    getFieldValue(doc, schema.TITLE_FIELD).includes(constants.IGNORED_CHANGES_FILE_NAME)
                );

                if (ignoredChangeDoc) {
                    if (getFieldValue(ignoredChangeDoc, schema.OWNER_ID) === constants.CURRENT_USER_ID) {
                        fileId = getFieldValue(ignoredChangeDoc, schema.CONTENT_DOCUMENT_ID_FIELD);
                    }
                }
            }
        } else if (error) {
            showToastError(this, { message: label.FETCH_DATA_ERROR + ': ' + reduceErrors(error) });
        }
        this.contentDocumentId = fileId;
    }

    get hasData() {
        return this.isSearchInProgress || (this.data && this.data.length) ? true : false;
    }

    get removeSelectedDisabled() {
        return this.selectedRows.length === 0;
    }

    get subtitle() {
        return this.hasData ? this.data.length + ' ' + label.ITEMS : '';
    }

    get title() {
        let rowsCount = this.data ? this.data.length : 0;
        return this.label.Promoted_User_Stories + ' (' + rowsCount + ')';
    }

    get userStoryName() {
        return schema.USER_STORY_FIELD.fieldApiName.replace('__c', '__r.Name');
    }

    async connectedCallback() {
        this.showSpinner = true;
        this.resetTable();
    }

    handleRemovePromotedUserStories() {
        const removeSelectedPopup = this.template.querySelector('c-promoted-user-stories-removal-modal');

        if (removeSelectedPopup) {
            removeSelectedPopup.promotedUserStoryIds = this._selectedIds();
            removeSelectedPopup.contentDocumentId = this.contentDocumentId;
            removeSelectedPopup.show();
        }
    }

    handleAddPromotedUserStories() {
        const addUserStoriesPopup = this.template.querySelector('c-promoted-user-stories-add-user-stories-modal');

        if (addUserStoriesPopup) {
            addUserStoriesPopup.show();
        }
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    handleApplySearch(event) {
        const searchObj = event.detail;
        this.data = [];
        this.filteredData = searchObj.searchedData;
        this._recordsOffset = 0;
        this.isSearchInProgress = true;
        this._prepareData(this.filteredData);
    }

    handleClearSearch() {
        this.allRows = [];
        this.data = [];
        this.filteredData = [];
        this._recordsOffset = 0;
        this.isSearchInProgress = false;
        this.allRows = [...this.allData];
        this._prepareData(this.allRows);
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this._applySort({ name: sortedBy, sortDirection: sortDirection });
    }

    handleLoadMoreData(event) {
        this._isLoadingInProgress = true;
        let rows = this.isSearchInProgress ? this.filteredData : this.allRows;
        this._loadMore(event, rows);
    }

    async resetTable() {
        await this._setTableInformation();
        this.showSpinner = false;
    }

    async handleRefresh() {
        this.showSpinner = true;
        await refreshApex(this.wiredDocumentLinksData);
        this.resetTable();
        const addUserStoriesPopup = this.template.querySelector('c-promoted-user-stories-add-user-stories-modal');
        if (addUserStoriesPopup) {
            addUserStoriesPopup.resetTable();
        }
        this.selectedRows = [];
    }

    async handleAddUserStories() {
        this.showSpinner = true;
        this.resetTable();
        const addUserStoriesPopup = this.template.querySelector('c-promoted-user-stories-add-user-stories-modal');
        if (addUserStoriesPopup) {
            addUserStoriesPopup.resetTable();
        }
    }

    messageAlert(message, variant, dismissible) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId: this.communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    // PRIVATE

    _applySort(fieldConfiguration) {
        if (this.data) {
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

    _prepareData(rows) {
        const data = rows.slice(0, this._recordSize);
        this.data = JSON.parse(JSON.stringify(data));
        this._recordsOffset = this.data.length;
    }

    async _loadMore(event, row) {
        try {
            if (!this._isLoadingInProgress) {
                return;
            }

            if (this._recordsOffset < row.length) {
                const moreData = await loadMoreData(event, row, {
                    recordsOffset: this._recordsOffset,
                    recordSize: this._recordSize
                });

                if (moreData && moreData.length && this._isLoadingInProgress) {
                    this.data = JSON.parse(JSON.stringify(moreData));
                    this._recordsOffset = this.data.length;
                    this._isLoadingInProgress = false;
                }
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async _getRowsData() {
        let rows;

        try {
            const queryConfig = {
                fieldSetName: this._fieldset,
                objectApiName: schema.PROMOTED_USER_STORY.objectApiName,
                relationshipFieldApi: schema.PROMOTION_FIELD.fieldApiName,
                recordId: this.recordId,
                orderBy: this.userStoryName + ' DESC',
                numberOfRecordsLimit: 10000,
                recordsOffset: 0
            };

            rows = await getRowsData(this, queryConfig);
        } catch (error) {
            this.messageAlert(label.Fetch_Data_Error + ' ' + reduceErrors(error), 'error', true);
        }

        return rows;
    }

    async _getColumnsConfig() {
        let columns;

        try {
            const columnsConfiguration = {
                objectApiName: schema.PROMOTED_USER_STORY.objectApiName,
                fieldSetName: this._fieldset,
                editable: false,
                hideDefaultColumnsActions: true,
                searchable: true,
                sortable: true
            };

            const data = await getColumnsConfiguration(this, columnsConfiguration);

            if (data && data.length) {
                columns = getUpgradedColumnConfiguration(data, [], false);
            } else {
                this.messageAlert(label.Fetch_Columns_Config_Error, 'error', true);
            }
        } catch (error) {
            this.messageAlert(label.Fetch_Columns_Config_Error + ' ' + reduceErrors(error), 'error', true);
        }

        return columns;
    }

    async _setTableInformation() {
        const [columns, rows] = await Promise.all([this._getColumnsConfig(), this._getRowsData()]);

        if (!(columns && rows)) {
            return;
        }

        const rowsCopy = [];

        for (const row of rows) {
            rowsCopy.push(Object.assign(row));
        }

        this.allRows = this.allData = rowsCopy;
        this.columns = columns;
        this._prepareData(this.allRows);
    }

    _selectedIds() {
        let result = [];

        this.selectedRows.forEach((row) => {
            result.push(row.Id);
        });

        return result;
    }
}