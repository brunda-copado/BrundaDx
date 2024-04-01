import { LightningElement, api, wire } from 'lwc';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { NavigationMixin } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';

import alertMessage from '@salesforce/messageChannel/CopadoAlert__c';

import { label, constants, schema } from './constants';
import { loadMoreData, getSortedData, saveRecords } from 'c/datatableService';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

import getKanbanBoardUrl from '@salesforce/apex/SprintWallUserStoriesCtrl.getKanbanBoardUrl';

export default class SprintWallUserStories extends NavigationMixin(LightningElement) {
    @api rows = [];
    @api columns = [];
    @api fieldset;
    @api recordLimit;
    @api recordId;
    @api relatedListConfig;
    @api childObjectApiName;
    @api queryConfig;

    allRows = [];
    selectedRows = [];
    draftValues = [];
    label = label;

    iconName;
    keyField = constants.KEY_FIELD;
    defaultSortDirection = constants.DEFAULT_SORT_DIRECTION;
    sortDirection = constants.DEFAULT_SORT_DIRECTION;
    sortedBy = constants.DEFAULT_SORT_FIELD;
    relationshipField = schema.SPRINT_FIELD;

    data = [];
    filteredData = [];
    searchValue = '';
    searchDataCount = 0;
    isSearchInProgress = false;
    showSpinner = false;

    _childListName;
    _sobjectLabelPlural;
    _recordsOffset = 0;
    _recordSize = constants.NUMBER_OF_RECORDS_LIMIT;
    _isLoadingInProgress = false;
    _hasMoreData = true;

    get rowsCount() {
        return this.data && this.data.length ? this.data.length + (this._hasMoreData ? '+' : '') : '0';
    }

    get hasData() {
        return this.isSearchInProgress || (this.data && this.data.length) ? true : false;
    }

    get title() {
        return this._sobjectLabelPlural + ' (' + this.rowsCount + ')';
    }

    get selectedRowCount() {
        return this.selectedRows ? this.selectedRows.length : 0;
    }

    get selectedRowItems() {
        return this.selectedRowCount + ' ' + (this.selectedRowCount === 1 ? label.ITEM_SELECTED : label.ITEMS_SELECTED);
    }

    get rowItems() {
        return this.rowsCount + ' ' + (this.rowsCount === '1' ? label.ITEM : label.ITEMS);
    }

    get items() {
        return this.hasData ? (this.selectedRowCount ? this.selectedRowItems : this.rowItems) : '';
    }

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        if (this.relatedListConfig) {
            this.iconName = this.relatedListConfig.iconName;
            this._childListName = this.relatedListConfig.childListName;
            this._sobjectLabel = this.relatedListConfig.sobjectLabel;
            this._sobjectLabelPlural = this.relatedListConfig.sobjectLabelPlural;
        }
        this.allRows = JSON.parse(JSON.stringify(this.rows));
        this._prepareData(this.allRows);
    }

    // TEMPLATE

    handleRefresh() {
        this.dispatchEvent(new CustomEvent('refreshdata'));
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

    handleViewInKanban(event) {
        this.showSpinner = true;
        this._prepareKanbanUrl();
    }

    handleEditStories(event) {
        if (this.selectedRows && this.selectedRows.length) {
            const editStoriesPopup = this.template.querySelector('c-sprint-wall-edit-stories-popup');
            editStoriesPopup.selectedRows = this.selectedRows;
            editStoriesPopup.show();
        } else {
            this._handleError(constants.SELECT_ATLEAST_ONE_RECORD_ERROR);
        }
    }

    handleNew(event) {
        const actionName = constants.NEW_BUTTON_NAME;
        this._handleDefaultActions(actionName, null);
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this._applySort({ name: sortedBy, sortDirection: sortDirection });
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this._handleDefaultActions(actionName, row);
    }

    handleLoadMoreData(event) {
        this._isLoadingInProgress = true;
        let rows = this.allRows;
        if (this.isSearchInProgress) {
            rows = this.filteredData;
        }
        this._loadMore(event, rows);
    }

    handleSave(event) {
        this._save(event);
    }

    handleViewAll(event) {
        const actionName = constants.VIEW_ALL_BUTTON_NAME;
        this._handleDefaultActions(actionName, null);
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

    async _prepareKanbanUrl() {
        try {
            const data = await getKanbanBoardUrl({ sprintRecordId: this.recordId });
            this.showSpinner = false;
            if (data && data.url && data.url.length) {
                this._handleDefaultActions(constants.VIEW_IN_KANBAN_BUTTON_NAME, data.url);
            } else if (data && data.alerts && data.alerts.length) {
                this._handleAlerts(data.alerts);
            }
        } catch (error) {
            this.showSpinner = false;
            const errorMessage = reduceErrors(error);
            this._handleError(errorMessage);
        }
    }

    _handleDefaultActions(actionName, row) {
        switch (actionName) {
            case constants.VIEW_BUTTON_NAME:
                this._navigateToRecordPage(row, constants.VIEW_BUTTON_NAME);
                break;
            case constants.EDIT_BUTTON_NAME:
                this._navigateToRecordPage(row, constants.EDIT_BUTTON_NAME);
                break;
            case constants.DELETE_BUTTON_NAME:
                this._handleDeleteRecord(row);
                break;
            case constants.VIEW_IN_KANBAN_BUTTON_NAME:
                this._navigateToWebPage(row);
                break;
            case constants.NEW_BUTTON_NAME:
                this._navigateToNewRecordPage();
                break;
            case constants.VIEW_ALL_BUTTON_NAME:
                this._navigateToRelatedListViewAll();
                break;
            default:
        }
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
                    if (this._recordsOffset == row.length) {
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

    async _save(event) {
        try {
            const result = await saveRecords(this, event);
            if (result) {
                this.handleRefresh();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this._handleError(constants.UPDATE_RECORD_ERROR_TITLE + ': ' + errorMessage);
        }
    }

    _navigateToWebPage(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        },
        true
      );
    }

    _navigateToRecordPage(row, actionName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: actionName
            }
        });
    }

    _handleDeleteRecord(row) {
        const deletePopup = this.template.querySelector('c-related-list-delete-popup');
        deletePopup.recordId = row.Id;
        deletePopup.sobjectLabel = this._sobjectLabel;
        deletePopup.show();
    }

    _navigateToNewRecordPage() {
        let defaultValues;
        if (this.recordId && this.relationshipField) {
            defaultValues = encodeDefaultFieldValues({
                [this.relationshipField]: this.recordId
            });
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.childObjectApiName,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                useRecordTypeCheck: 1
            }
        });
    }

    _navigateToRelatedListViewAll() {
        if (this.recordId && this._childListName) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordRelationshipPage',
                attributes: {
                    recordId: this.recordId,
                    relationshipApiName: this._childListName,
                    actionName: 'view'
                }
            });
        }
    }

    _handleError(message) {
        this._publishFlexiPageAlert(this._prepareAlert(message, constants.ERROR_VARIANT, true));
    }

    _handleAlerts(alerts) {
        alerts.forEach((alert) => ({
            ...alert, 
            communicationId: constants.SPRINT_WALL_ALERT_COMMUNICATION_ID
        }));
        this._publishFlexiPageAlert(alerts);
    }

    _publishFlexiPageAlert(alerts) {
        publish(this.messageContext, alertMessage, alerts);
    }

    _prepareAlert(message, variant, isDismissible) {
        return {
            message: message,
            variant: variant,
            dismissible: isDismissible,
            communicationId: constants.SPRINT_WALL_ALERT_COMMUNICATION_ID
        };
    }
}