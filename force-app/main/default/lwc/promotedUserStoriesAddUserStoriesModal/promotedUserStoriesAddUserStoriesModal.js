/* eslint-disable guard-for-in */
import { LightningElement, api, wire } from 'lwc';

import { reduceErrors } from 'c/copadocoreUtils';
import { publish, MessageContext } from 'lightning/messageService';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/copadoCorePubsub';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import availableUserStories from '@salesforce/apex/PromotedUserStoriesDatatableController.availableUserStories';
import addSelectedUserStoriesToPromotion from '@salesforce/apex/PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion';
import validateSelectedUserStoriesToPromotion from '@salesforce/apex/PromotedUserStoriesDatatableController.validateSelectedUserStoriesToPromotion';
import { getColumnsConfiguration, getUpgradedColumnConfiguration, getSortedData, loadMoreData } from 'c/datatableService';

import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { label, schema } from './constants';

export default class PromotedUserStoriesAddUserStoriesModal extends LightningElement {
    @api promotionId;
    showSpinner;

    communicationId = 'promotionRecordPageAlerts';
    modalCommunicationId = 'modalAlerts';
    validationErrorMessage = '';
    showInfoMessage = true;
    showValidationError = false;

    label = label;
    allData = [];
    allRows = [];
    selectedRows = [];
    data = [];
    filteredData = [];
    columns = [];
    isSearchInProgress = false;
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy = 'Name';
    illustrationObj = {
        name: 'custom:lake_mountain',
        title: this.label.Add_User_Stories_Empty_Illustration_Title,
        body: this.label.Add_User_Stories_Empty_Illustration_Body
    };

    _fieldset = 'Promotion_Related_List_Datatable';
    _recordsOffset = 0;
    _recordSize = 25;
    _isLoadingInProgress = false;

    @wire(CurrentPageReference) pageRef;

    @wire(MessageContext)
    messageContext;

    get hasData() {
        return this.isSearchInProgress || (this.data && this.data.length) ? true : false;
    }

    get saveButtonDisabled() {
        return this.selectedRows.length === 0;
    }

    get subtitle() {
        return this.data ? this.data.length + ' ' + this.label.Items : '';
    }

    get infoMessage() {
        return this.showInfoMessage ? this.label.Add_User_Stories_Info_Message : '';
    }

    get illustration() {
        return this.data && this.data.length === 0 && !this.isSearchInProgress ? this.illustrationObj : {};
    }

    async connectedCallback() {
        this.resetTable();
    }

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
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

    handleCancel() {
        this.hide();
        this._reset();
    }

    handleSave() {
        this.showSpinner = true;
        const userStoryIds = this._selectedIds();
        this._validateUserStories(userStoryIds);
    }

    @api async resetTable() {
        this.showSpinner = true;
        await this._setTableInformation();
        this.showSpinner = false;
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
            rows = await availableUserStories({ promotionId: this.promotionId, selectFieldSet: this._fieldset });
            if (rows.length > 0) {
                rows = this._processData(rows);
            }
        } catch (error) {
            this.messageAlert(label.Fetch_Data_Error + ' ' + reduceErrors(error), 'error', true);
        }

        return rows;
    }

    async _getColumnsConfig() {
        let columns;

        try {
            const columnsConfiguration = {
                objectApiName: schema.USER_STORY.objectApiName,
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
            rowsCopy.push(Object.assign(row, this._urlFields(row)));
        }

        this.allRows = this.allData = rowsCopy;
        this.columns = columns;
        this._prepareData(this.allRows);
    }

    _urlFields(row) {
        let developerReference = schema.DEVELOPER_FIELD.fieldApiName.replace('__c', '__r');
        let developerName = developerReference.replace('__r', '__r.Name');
        let developerLinkName = developerReference.replace('__r', '__r.LinkName');
        let urlFields = { LinkName: '/' + row.Id };
        urlFields[developerName] = row[developerReference] ? row[developerReference].Name : '';
        urlFields[developerLinkName] = row[schema.DEVELOPER_FIELD.fieldApiName] ? '/' + row[schema.DEVELOPER_FIELD.fieldApiName] : '';

        return urlFields;
    }

    _selectedIds() {
        let result = [];

        this.selectedRows.forEach((row) => {
            result.push(row.Id);
        });

        return result;
    }

    _processData(records, path, ancestor) {
        const result = [];
        records.forEach((row) => {
            const record = JSON.parse(JSON.stringify(row));
            record.LinkName = '/' + record.Id;
            for (const propertyName in record) {
                const propertyValue = record[propertyName];
                if (typeof propertyValue === 'object') {
                    const newValue = propertyValue.Id ? '/' + propertyValue.Id : null;
                    this._flattenStructure(record, propertyName + '.', propertyValue);
                    if (newValue !== null) {
                        record[propertyName + '.LinkName'] = newValue;
                        const currentPath = path ? path + propertyName + '.' : propertyName + '.';
                        if (ancestor) {
                            ancestor[currentPath + 'LinkName'] = newValue;
                        }
                        this._processData([propertyValue], currentPath, record);
                    }
                }
            }
            result.push(record);
        });
        return result;
    }

    _flattenStructure(topObject, prefix, toBeFlattened) {
        for (const propertyName in toBeFlattened) {
            const propertyValue = toBeFlattened[propertyName];
            if (typeof propertyValue === 'object') {
                this._flattenStructure(topObject, prefix + propertyName + '.', propertyValue);
            } else {
                topObject[prefix + propertyName] = propertyValue;
            }
        }
    }

    async _validateUserStories(userStoryIds) {
        try {
            await validateSelectedUserStoriesToPromotion({ promotionId: this.promotionId, userStoryIds: userStoryIds });
            this._addUserStoriesToPromotion(userStoryIds);
        } catch (error) {
            this.validationErrorMessage = reduceErrors(error);
            this.showValidationError = true;
            this.showInfoMessage = false;
        }
        this.showSpinner = false;
    }

    async _addUserStoriesToPromotion(userStoryIds) {
        this.hide();
        try {
            await addSelectedUserStoriesToPromotion({ promotionId: this.promotionId, userStoryIds: userStoryIds });
            showToastSuccess(this, { message: label.User_stories_added_successfully });
        } catch (error) {
            this.messageAlert(reduceErrors(error), 'error', true);
        }

        this.dispatchEvent(new CustomEvent('adduserstories'));
        fireEvent(this.pageRef, 'userStoryAddedEvent', this);
        this._reset();
    }

    _reset() {
        this.selectedRows = [];
        this.showValidationError = false;
        this.showInfoMessage = true;
        this.validationErrorMessage = '';
        this.handleClearSearch();
    }
}