import { LightningElement, api, wire, track } from 'lwc';

import { publish, MessageContext } from 'lightning/messageService';
import { subscribe, onError, unsubscribe } from 'lightning/empApi';
import { namespace, cloneData, reduceErrors } from 'c/copadocoreUtils';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { loadMoreData } from 'c/datatableService';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import getTests from '@salesforce/apex/LatestTestsRunsController.getTests';
import { label, schema, columns } from './constants';

export default class LatestTestsRuns extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api showRefreshIcon;
    @api showSearch = false;
    @api showFilter = false;

    @track filteredData = [];
    @track data = [];
    parameterObject;
    testIds = [];

    isLoading = false;
    columns = [];
    searchValue = '';
    label = label;
    schema = schema;
    iconName = 'standard:work_order_item';
    resultChannelSubscription = null;
    userstoryId;
    makeRequired = false;

    @wire(MessageContext)
    messageContext;

    _interval;

    get tableHeight() {
        return this.filteredData.length >= 10 ? 'height: 400px' : '';
    }

    get hasNoData() {
        return this.filteredData.length <= 0 && !this.isLoading ? true : false;
    }

    // PUBLIC

    async connectedCallback() {
        try {
            columns.forEach((element) => {
                if (element.key.includes(this.objectApiName)) {
                    this.columns.push(element.value);
                }
            });

            this.isLoading = true;
            await this._getData();
        } catch (err) {
            this._publishError(err);
        }
        this.isLoading = false;
        this.subscribeToEvents();
        this.registerErrorListener();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    refreshSearchedData(event) {
        const searchObj = event.detail;
        this.searchValue = searchObj.searchTerm;
        this.filteredData = searchObj.searchedData;
    }

    handleClearSearch() {
        this.searchValue = '';
        this.filteredData = [...this.data];
    }

    handleSuccess() {
        showToastSuccess(this, { message: label.TestCreatedSuccessfully });
        this.closeModal();
        this._getData();
    }

    populateDefaults() {
        if (this.objectApiName === schema.USER_STORY.objectApiName) {
            this.userstoryId = this.recordId;
            this.makeRequired = true;
        }
    }

    async handleRefresh() {
        this.isLoading = true;
        await this._getData();
        this.isLoading = false;
    }

    registerErrorListener() {
        onError((error) => {
            console.error('Received error from server: ', JSON.stringify(error));
        });
    }

    subscribeToEvents() {
        const messageCallback = (receivedMessage) => {
            const parsedMessage = JSON.parse(JSON.stringify(receivedMessage));
            const payloadField = (!!namespace ? namespace : '') + 'Payload__c';
            const payloadData = parsedMessage.data.payload[payloadField];

            if (payloadData.includes('resultId')) {
                const eventPayload = this._convertData(JSON.parse(payloadData).data)[0];

                let dataBackup = cloneData(this.filteredData);

                const index = dataBackup.findIndex((item) => item.id === eventPayload.testId);
                if (index >= 0) {
                    dataBackup[index].status = eventPayload.status;
                    dataBackup[index].runDate = eventPayload.runDate;
                    dataBackup[index].resultUrl = eventPayload.resultUrl;
                    dataBackup[index].result = eventPayload.result;
                    this.filteredData = [];
                    this.filteredData = dataBackup;
                }
            }
        };

        subscribe('/event/' + (!!namespace ? namespace : '') + 'Event__e', -1, messageCallback.bind(this)).then((response) => {
            this.resultChannelSubscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.stepChannelSubscription, (response) => {
            console.info('unsubscribe() response: ', JSON.stringify(response));
        });
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

    _publishError(err) {
        const errorAlert = {
            message: err.message || err.body.message,
            variant: 'error',
            dismissible: true,
            communicationId: this._getCommunicationId()
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, errorAlert);
    }

    _resetData() {
        this.filteredData = [];
        this.data = [];
    }

    async _getData() {
        this.data = await getTests({ parentId: this.recordId });
        this.filteredData = this.data;
    }

    _getCommunicationId() {
        switch (this.objectApiName) {
            case schema.USER_STORY.objectApiName:
                return 'userStoryAlerts';
            default:
                return '';
        }
    }

    _searchTextInData(dataRows, searchText) {
        let result = [];

        result = dataRows.filter((eachRow) => {
            return Object.values(eachRow).some(function (value) {
                return value.toLowerCase().includes(searchText.toLowerCase());
            });
        });

        return result;
    }

    _convertData(data) {
        let result = [];

        result.push({
            runDate: this._formatDate(data.runDate),
            result: data.name,
            resultUrl: '/' + data.resultId,
            status: data.status,
            testId: data.test
        });

        return result;
    }

    _formatDate(value) {
        let date = new Date(value);
        return Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    }
}