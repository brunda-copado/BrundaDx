import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/copadocoreUtils';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { publish, MessageContext } from 'lightning/messageService';

import { showToastSuccess } from 'c/copadocoreToastNotification';

import addSelectedUserStories from '@salesforce/apex/UserStoryBundleUserStoriesTableCtrl.addSelectedUserStories';
import { getColumnsConfiguration, getUpgradedColumnConfiguration, getRowsData, getSortedData, loadMoreData } from 'c/datatableService';

import { label, schema } from './constants';

const fields = [schema.PACKAGE_VERSION_STATUS_FIELD];

export default class UserStoryBundleUserStoriesContainer extends LightningElement {
    @api recordId;
    showSpinner;

    label = label;
    schema = schema;

    communicationId = 'packageversionRecordPageAlerts';

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

    _fieldset = 'Bundle';
    _recordsOffset = 0;
    _recordSize = 11;
    _isLoadingInProgress = false;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields })
    packageVersion;

    get hasData() {
        return (this.isSearchInProgress && this.filteredData && this.filteredData.length) || (this.data && this.data.length) ? true : false;
    }

    get removeSelectedDisabled() {
        return this.selectedRows.length === 0;
    }

    get hideCheckBoxOnLockStatus() {
        return this.selectedRows.length === 0 && this.packageVersionStatus === 'Locked';
    }

    get disableAddRowsButton() {
        return this.packageVersionStatus === 'Locked';
    }

    get packageVersionStatus() {
        return getFieldValue(this.packageVersion.data, schema.PACKAGE_VERSION_STATUS_FIELD);
    }

    get subtitle() {
        let rowCount = this.data ? this.data.length : 0;
        let result = rowCount;

        result += rowCount === 1 ? ' item' : ' items';

        return result;
    }

    get userStoryName() {
        return schema.USER_STORY_FIELD.fieldApiName.replace('__c', '__r.Name');
    }

    async connectedCallback() {
        this.showSpinner = true;
        this.resetTable();
    }

    handleRemoveUserStoryBundleUserStories() {
        const removeSelectedPopup = this.template.querySelector('c-user-story-bundle-user-stories-removal-modal');
        if (removeSelectedPopup) {
            removeSelectedPopup.userStoryBundleBundleStoryIds = this._selectedIds();
            removeSelectedPopup.show();
        }
    }

    handleAddUserStoryBundleUserStories() {
        const addUserStoriesPopup = this.template.querySelector('c-user-story-bundle-add-user-stories-modal');

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
        this.resetTable();
        this.template.querySelector('lightning-datatable').selectedRows = [];
        this.selectedRows = [];
        const addUserStoriesPopup = this.template.querySelector('c-user-story-bundle-add-user-stories-modal');

        if (addUserStoriesPopup) {
            addUserStoriesPopup.resetTable();
        }
    }

    async handleAddUserStories(event) {
        this.showSpinner = true;

        const addUserStoriesPopup = this.template.querySelector('c-user-story-bundle-add-user-stories-modal');

        if (addUserStoriesPopup) {
            addUserStoriesPopup.hide();
        }

        try {
            await addSelectedUserStories({ packageVersionId: this.recordId, userStoryIds: event.detail.userStoryIds });
            await this.resetTable();

            showToastSuccess(this, { message: label.User_Stories_Added_Message });

            if (addUserStoriesPopup) {
                addUserStoriesPopup.resetTable();
            }
        } catch (error) {
            this.showSpinner = false;
            const errorMessage = reduceErrors(error);
            this.messageAlert(errorMessage, 'error', true);
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
            this.messageAlert(errorMessage, 'error', true);
        }
    }

    async _getRowsData() {
        let rows;

        try {
            const queryConfig = {
                fieldSetName: this._fieldset,
                objectApiName: schema.BUNDLED_STORY.objectApiName,
                relationshipFieldApi: schema.PACKAGE_VERSION_FIELD.fieldApiName,
                recordId: this.recordId,
                orderBy: this.userStoryName + ' DESC',
                numberOfRecordsLimit: 10000,
                recordsOffset: 0
            };

            rows = await getRowsData(this, queryConfig);
        } catch (error) {
            const errorMessage = label.Fetch_Data_Error + ': ' + reduceErrors(error);
            this.messageAlert(errorMessage, 'error', true);
        }

        return rows;
    }

    async _getColumnsConfig() {
        let columns;

        try {
            const columnsConfiguration = {
                objectApiName: schema.BUNDLED_STORY.objectApiName,
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
                const errorMessage = label.Fetch_Columns_Config_Error;

                this.messageAlert(errorMessage, 'error', true);
            }
        } catch (error) {
            const errorMessage = label.Fetch_Columns_Config_Error + ': ' + reduceErrors(error);

            this.messageAlert(errorMessage, 'error', true);
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

        this.selectedRows.forEach(row => {
            result.push(row.Id);
        });

        return result;
    }
}