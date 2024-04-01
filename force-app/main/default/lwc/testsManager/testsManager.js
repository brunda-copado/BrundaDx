import { LightningElement, api, wire, track } from 'lwc';

import { publish, MessageContext } from 'lightning/messageService';
import { subscribe, onError, unsubscribe } from 'lightning/empApi';
import { namespace, cloneData, reduceErrors } from 'c/copadocoreUtils';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { loadMoreData } from 'c/datatableService';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LOCALE from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import runTestsOf from '@salesforce/apex/TestsManagerCtrl.runTestsOf';
import runTest from '@salesforce/apex/TestsManagerCtrl.runTest';
import getTests from '@salesforce/apex/TestsManagerCtrl.getTests';
import { label, schema, columns } from './constants';

export default class TestsManager extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api showNewButton;
    @api showRunAllTestButton;
    @api showRefreshIcon;
    @api showSearch;
    @api showFilter;
    @api showRowActions;

    @track filteredData = [];
    @track data = [];
    @track openmodal = false;

    isLoading = false;
    columns = [];
    searchValue = '';
    label = label;
    schema = schema;
    iconName = 'standard:work_order_item';
    resultChannelSubscription = null;
    userstoryId;
    makeRequired = false;

    _areTestsDeletable = false;

    @wire(getObjectInfo, { objectApiName: schema.TEST })
    wiredData({ data }) {
        if (data) {
            this._areTestsDeletable = data.deletable;
        }
    }

    @wire(MessageContext)
    messageContext;

    _interval;

    get tableHeight() {
        return this.filteredData.length >= 10 ? 'height: 400px' : '';
    }

    get hasNoData() {
        return this.filteredData.length <= 0 && !this.isLoading ? true : false;
    }

    get testAreNotExecutable() {
        return this.data.length > 0 && this.data.some(test => !this._isAutomaticallyExecutable(test));
    }

    get inputFieldClass() {
        return this.makeRequired ? 'validate' : '';
    }

    get infoAlert() {
        if (this.testAreNotExecutable) {
            return label.TestAreNotExecutable;
        }
        switch (this.objectApiName) {
            case schema.USER_STORY.objectApiName:
                return label.User_Story_Tests_Information;
            case schema.PROMOTION.objectApiName:
                return label.Promotion_Tests_Information;
            default:
                return '';
        }
    }

    // PUBLIC

    async connectedCallback() {
        try {
            columns.forEach(element => {
                if (element.key.includes(this.objectApiName)) {
                    this.columns.push(element.value);
                }
            });

            this.isLoading = true;
            await this._getData();
            this._addActionColumn();
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

    async handleRunAll() {
        try {
            this._resetData();
            this.isLoading = true;
            await runTestsOf({ parentId: this.recordId });
            await this._getData();
        } catch (err) {
            this._publishError(err);
        }
        this.isLoading = false;
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

    handleNewTest() {
        this.openmodal = true;
    }

    closeModal() {
        this.openmodal = false;
    }

    handleSuccess() {
        showToastSuccess(this, { message: label.TestCreatedSuccessfully });
        this.closeModal();
        this._getData();
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        if (this._validateInputs()) {
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
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
        onError(error => {
            console.error('Received error from server: ', JSON.stringify(error));
        });
    }

    subscribeToEvents() {
        const messageCallback = receivedMessage => {
            const parsedMessage = JSON.parse(JSON.stringify(receivedMessage));
            const payloadField = (!!namespace ? namespace : '') + 'Payload__c';
            const payloadData = parsedMessage.data.payload[payloadField];

            if (payloadData.includes('resultId')) {
                const eventPayload = this._convertData(JSON.parse(payloadData).data)[0];

                let dataBackup = cloneData(this.filteredData);

                const index = dataBackup.findIndex(item => item.id === eventPayload.testId);
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

        subscribe('/event/' + (!!namespace ? namespace : '') + 'Event__e', -1, messageCallback.bind(this)).then(response => {
            this.resultChannelSubscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.stepChannelSubscription, response => {
            console.info('unsubscribe() response: ', JSON.stringify(response));
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.value;
        const testId = event.detail.row.id;
        switch (actionName) {
            case 'run':
                this._handleRun(testId);
                break;
            case 'delete':
                this._handleDeleteRecord(testId);
                break;
            default:
        }
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

    _addActionColumn() {
        const index = this.columns.findIndex(item => item.type === 'action');
        if (index === -1 && this.showRowActions) {
            this.columns.push({
                type: 'action',
                fixedWidth: 30,
                hideDefaultActions: true,
                typeAttributes: {
                    rowActions: this._getRowActions.bind(this),
                    id: { fieldName: 'id' }
                }
            });
            this.columns = [...this.columns];
        }
    }

    async _handleRun(testId) {
        try {
            await runTest({ testId: testId });
            await this._getData();
        } catch (err) {
            this._publishError(err);
        }
    }

    _handleDeleteRecord(testId) {
        const deletePopup = this.template.querySelector('c-related-list-delete-popup');
        deletePopup.recordId = testId;
        deletePopup.sobjectLabel = 'Test';
        deletePopup.show();
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
        this.filteredData = this._searchTextInData(this.data, this.searchValue);
        this.data.forEach(test => {
            if (!test.isReadyToRun && !test.isExtensionActive) {
                test.message = label.TestNotReadyInactiveExtensionConfigMessage;
            } else if (!test.isReadyToRun) {
                test.message = label.TestNotReadyMessage;
            } else if (!test.isExtensionActive) {
                test.message = label.InactiveExtensionConfigMessage;
            }
        });
    }

    _getRowActions(row, doneCallback) {
        const actions = [];

        actions.unshift({ id: 'item-1', label: label.Run, value: 'run', disabled: !this._isAutomaticallyExecutable(row) });
        actions.push({ id: 'item-2', label: label.Delete, value: 'delete', disabled: !this._areTestsDeletable });

        doneCallback(actions);
    }

    _isAutomaticallyExecutable(test) {
        return test.isReadyToRun && test.isExtensionActive && test.testTool !== 'Manual Tests';
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

        result = dataRows.filter(eachRow => {
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

    _formatDate(dateValue) {
        let result;

        if (dateValue) {
            const formattedDate = new Date(dateValue).toLocaleString(LOCALE, { timeZone: TIME_ZONE });
            result = 'DAY/MONTH/YEAR HOUR:MIN AMPM';
            let ampm = 'AM';

            const date = formattedDate.split(',')[0];
            const time = formattedDate.split(',')[1];

            let dateSplit = date.split('/');
            let timeSplit = time.split(' ');

            let clock = timeSplit[1].split(':');
            let hours = clock[0];

            if (hours >= 12) {
                ampm = 'PM';
                hours = hours % 12 ? hours % 12 : 12;
            } else if (timeSplit.length > 2 && timeSplit[2].charAt(0).toLowerCase() === 'p') {
                // Potential values : 'pm', 'p. m.', 'PM'
                ampm = 'PM';
            }

            result = result
                .replace('DAY', dateSplit[0].toString().padStart(2, '0'))
                .replace('MONTH', dateSplit[1].toString().padStart(2, '0'))
                .replace('YEAR', dateSplit[2])
                .replace('HOUR', hours.toString().padStart(2, '0'))
                .replace('MIN', clock[1].toString().padStart(2, '0'))
                .replace('AMPM', ampm);
        }

        return result;
    }

    _validateInputs() {
        var isValid = true;
        var inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(function (input) {
            if (!input.value) {
                isValid = false;
                input.reportValidity();
            }
        });
        return isValid;
    }
}