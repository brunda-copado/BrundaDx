import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, isEmpEnabled } from 'lightning/empApi';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { loadMoreData } from 'c/datatableService';

import validateGitConnection from '@salesforce/apex/GitRepositoryController.validateGitConnection';
import refreshBranches from '@salesforce/apex/GitRepoController.refreshBranches';
import fetchBranches from '@salesforce/apex/GitRepoController.fetchBranches';
import deleteGitBranches from '@salesforce/apex/GitRepoController.areGitBranchesDeleted';
import createCopadoNotificationPushTopic from '@salesforce/apex/GitRepoController.createCopadoNotificationPushTopic';

import { label, schema, columns } from './constants';

export default class GitRepositoryBranches extends LightningElement {
    @api recordId;

    @track filteredData = [];
    @track data = [];

    COPADO_NOTIFICATION_TOPIC = '/topic/CopadoNotifications';
    iconName = 'standard:branch_merge';
    columns = columns;
    schema = schema;
    label = label;

    showSearch = false;
    showRowActions = false;
    showFilter = false;
    isLoading = false;

    sortedBy;
    showRefresh;
    showDeleteBranches;

    spinnerMessage = '';
    searchValue = '';
    sortDirection = 'asc';

    _gitRepository;
    _gitRepositoryId;
    _gitRepositoryBranchBaseURL;
    _refreshBranchesInitiated;
    _deleteBranchesInitiated;

    get rowsCount() {
        return this.filteredData && this.filteredData.length ? this.filteredData.length : '0';
    }

    get items() {
        return this.hasData ? this.rowsCount + ' ' + label.ITEMS : '';
    }

    get hasData() {
        return this.data && this.data.length ? true : false;
    }

    get tableHeight() {
        return this.filteredData.length >= 20 ? 'height: 25rem' : '';
    }

    get hasNoData() {
        return this.filteredData.length <= 0 && !this.isLoading ? true : false;
    }

    //WIRE
    @wire(getRecord, { recordId: '$recordId', fields: [schema.NAME_FIELD, schema.BRANCH_BASE_URL_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this._gitRepository = data;
            this._gitRepositoryId = data.id;
            this._gitRepositoryBranchBaseURL = getFieldValue(data, schema.BRANCH_BASE_URL_FIELD);
        } else if (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    async connectedCallback() {
        this.isLoading = true;
        this._isEmpEnabled();
        await this.isAuthenticated();
    }

    disconnectedCallback() {
        this._unsubscribeEmpApi();
    }

    //PUBLIC

    async handleRefreshBranches() {
        try {
            this.isLoading = true;
            this._refreshBranchesInitiated = true;
            this.setSpinnerMessage(label.REFRESHING_BRANCHES_MESSAGE);
            await this._createCopadoNotificationPushTopic();
            this._subscribeToCopadoNotifications(null);
            refreshBranches({ repoId: this.recordId });
        } catch (error) {
            this.isLoading = false;
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    async handleDeleteBranches() {
        const deletedBranches = {
            gitBranches: []
        };
        try {
            this.isLoading = true;
            this._deleteBranchesInitiated = true;
            this.setSpinnerMessage(label.DELETING_BRANCHES_MESSAGE);
            const selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();

            if (selectedRecords.length > 0) {
                await this._createCopadoNotificationPushTopic();
                selectedRecords.forEach(record => {
                    deletedBranches.gitBranches.push(record.name);
                });
                this._subscribeToCopadoNotifications(deletedBranches);
            } else {
                this.isLoading = false;
                showToastError(this, { message: label.SELECT_ATLEAST_ONE_BRANCH });
            }
        } catch (error) {
            this.isLoading = false;
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.filteredData];

        cloneData.sort(this._sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.filteredData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleLoadMoreData(event) {
        this._isLoadingInProgress = true;
        let rows = this.allRows;
        if (this.isSearchInProgress) {
            rows = this.filteredData;
        }
        this._loadMore(event, rows);
    }

    // PRIVATE

    setSpinnerMessage(spinnerMessage) {
        this.spinnerMessage = spinnerMessage;
    }

    async _isEmpEnabled() {
        this.isEmpEnabled = await isEmpEnabled();
    }

    async _createCopadoNotificationPushTopic() {
        try {
            const result = await createCopadoNotificationPushTopic();
            if (!result.isSuccess) {
                this._handlePushTopicCleanup(result);
            }
        } catch (error) {
            this._handlePushTopicCleanup(error);
        }
    }

    _subscribeToCopadoNotifications(selectedBranches) {
        const _subscribeCallback = response => {
            this._notificationCallback(response);
        };
        subscribe(this.COPADO_NOTIFICATION_TOPIC, -1, _subscribeCallback)
            .then(response => {
                this._subscription = response;
                if (this._deleteBranchesInitiated) {
                    this._executeDeleteBranches(selectedBranches);
                }
            })
            .catch(error => {
                this._handlePushTopicCleanup(error);
            });
    }

    _unsubscribeEmpApi() {
        if (this._subscription) {
            unsubscribe(this._subscription, () => {
                this._subscription = null;
            });
        }
    }

    _notificationCallback(response) {
        if (
            this._subscription &&
            (response?.data?.sobject?.[schema.COPADO_NOTIFICATION_PARENT_ID.fieldApiName] === this.recordId || this._refreshBranchesInitiated)
        ) {
            if (response?.data?.sobject?.[schema.COPADO_NOTIFICATION_IS_FINISHED.fieldApiName]) {
                this._handlePushTopicFinished(response?.data?.sobject?.[schema.COPADO_NOTIFICATION_IS_SUCCESS.fieldApiName]);
            } else {
                this.setSpinnerMessage(response?.data?.sobject?.[schema.COPADO_NOTIFICATION_STATUS.fieldApiName]);
            }
        }
    }

    _handlePushTopicFinished(isSuccess) {
        this.template.querySelector('lightning-datatable').selectedRows = [];
        this.isLoading = false;
        if (this._refreshBranchesInitiated) {
            this._fetchBranches();
        }
        if (isSuccess !== undefined && !isSuccess) {
            showToastError(
                this,
                this._deleteBranchesInitiated
                    ? { message: label.GIT_BRANCH_DELETE_ERROR_MESSAGE }
                    : { message: label.GIT_BRANCH_REFRESH_ERROR_MESSAGE }
            );
        } else {
            showToastSuccess(
                this,
                this._deleteBranchesInitiated
                    ? { message: label.SUCCESS_BRANCH_DELETE_RETRIEVE_MESSAGE.replace('{0}', label.DELETED) }
                    : { message: label.SUCCESS_BRANCH_DELETE_RETRIEVE_MESSAGE.replace('{0}', label.RETRIEVED) }
            );
        }

        if (this._deleteBranchesInitiated) {
            this.handleRefreshBranches();
            this._deleteBranchesInitiated = false;
        }
        this._unsubscribeEmpApi();
    }

    _handlePushTopicCleanup(message) {
        showToastError(this, { message: reduceErrors(message) });
        this._unsubscribeEmpApi();
        this.setSpinnerMessage(null);
    }

    async isAuthenticated() {
        let result;
        validateGitConnection({ repositoryId: this.recordId })
            .then(val => {
                result = JSON.parse(val);
                if (result.success) {
                    this.handleRefreshBranches();
                    this.showDeleteBranches = true;
                    this.showRefresh = true;
                } else {
                    this.isLoading = false;
                }
            })
            .catch(error => {
                this.isLoading = false;
                showToastError(this, { message: reduceErrors(error) });
                return false;
            });
        return result;
    }

    async _fetchBranches() {
        try {
            let branchesJSON = await fetchBranches({ repoId: this.recordId });
            this.data = this._convertData(branchesJSON);
            this.filteredData = this.data;
            this._refreshBranchesInitiated = false;
        } catch (error) {
            this.isLoading = false;
            console.error(error);
        }
    }

    _convertData(branchesJSON) {
        const branchList = [];
        const branches = JSON.parse(branchesJSON);
        branches.forEach(branchJSON => {
            branchList.push({
                name: branchJSON.name,
                GitDirectory: this._gitRepositoryBranchBaseURL + branchJSON.name,
                LastModifiedDate: this._formatDate(parseInt(branchJSON.lastUpdate, 10))
            });
        });
        return branchList;
    }

    _formatDate(dateValue) {
        let result;

        if (dateValue) {
            result = new Date(dateValue);
        }
        return result != null ? result : '';
    }

    async _executeDeleteBranches(deletedBranches) {
        if (this.recordId && deletedBranches) {
            await deleteGitBranches({ gitRepoId: this.recordId, deleteGitBranches: JSON.stringify(deletedBranches) });
        }
    }

    _sortBy(field, reverse) {
        const key = columnObject => {
            return columnObject[field];
        };

        return (currentRowValue, nextRowValue) => {
            currentRowValue = key(currentRowValue) ? key(currentRowValue) : '';
            nextRowValue = key(nextRowValue) ? key(nextRowValue) : '';
            return reverse * ((currentRowValue > nextRowValue) - (nextRowValue > currentRowValue));
        };
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
            if (row && this._recordsOffset < row.length) {
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