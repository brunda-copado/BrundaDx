import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService';
import DATA_TEMPLATE_REFRESH from '@salesforce/messageChannel/dataTemplateRefresh__c';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { label, schema, FIELDS } from './constants';
import { compareRefreshedSchema } from 'c/datatemplateUtil';

import getDescribeObject from '@salesforce/apex/DataTemplateMainObjectTableCtrl.getDescribeObject';
import getDataTemplateFilters from '@salesforce/apex/DataTemplateObjectFiltersCtrl.getDataTemplateFilters';
import updateDataTemplateFilters from '@salesforce/apex/DataTemplateObjectFiltersCtrl.updateDataTemplateFilters';
import getTemplateDetail from '@salesforce/apex/DataTemplateMainObjectTableCtrl.getTemplateDetail';
import refreshFields from '@salesforce/apex/DataTemplateMainObjectTableCtrl.refreshFields';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import deActivateTemplate from '@salesforce/apex/DataTemplateDeactivateCtrl.deActivateTemplate';
export default class DataTemplateObjectFilters extends LightningElement {
    @wire(MessageContext)
    messageContext;

    @api recordId;
    @api validCredential;

    label = label;
    schema = schema;
    fields = FIELDS;
    view = 'filter';
    fieldsDescribe;
    defaultFilters;
    defaultFilterLogic;

    _templateDetail;

    editMode = false;
    showSpinner = false;
    subscription = null;

    @wire(getRecord, { recordId: '$recordId', fields: [FIELDS.DATA_TEMPLATE_ACTIVE] })
    getTemplateDetail({ data, error }) {
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } else if (data) {
            this.dataTemplate = data;
        }
    }

    get readOnlyMode() {
        return !this.editMode;
    }

    async connectedCallback() {
        try {
            this.showSpinner = true;
            await this._loadData();
            this._subscribeToRefreshMessageChannel();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    disconnectedCallback() {
        this._unsubscribeToRefreshMessageChannel();
    }

    handleClickEdit(event) {
        let templateStatus = getFieldValue(this.dataTemplate, FIELDS.DATA_TEMPLATE_ACTIVE);
        if (templateStatus) {
            this.template.querySelector('c-copadocore-modal').show();
        } else {
            this.editMode = true;
        }
    }

    async handleClickRefresh(event) {
        try {
            this.showSpinner = true;
            const existingTemplateDetail = JSON.parse(JSON.stringify(this._templateDetail));
            await refreshFields({ recordId: this.recordId });
            await this._loadData();
            const newTemplateDetail = JSON.parse(JSON.stringify(this._templateDetail));
            const result = compareRefreshedSchema(existingTemplateDetail, newTemplateDetail);
            this._processRefreshInformation(result);
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleClickCancel(event) {
        this.editMode = false;

        const dataFilters = this.template.querySelector('c-data-filters');
        dataFilters.resetFilters();

        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
    }

    async handleSubmit(event) {
        try {
            event.preventDefault();
            this.showSpinner = true;

            const fields = event.detail.fields;
            let batchSize = fields[this.fields.BATCH_SIZE.fieldApiName];
            batchSize = batchSize ? parseInt(batchSize) : null;
            let recordLimit = fields[this.fields.MAX_RECORD_LIMIT.fieldApiName];
            recordLimit = recordLimit ? parseInt(recordLimit) : null;
            this.template.querySelector('lightning-record-edit-form').submit(fields);

            const dataFilters = this.template.querySelector('c-data-filters');
            let filters;
            let filterLogic;
            if (dataFilters) {
                filters = dataFilters.filters;
                filterLogic = dataFilters.filterLogic;
            }
            await updateDataTemplateFilters({
                recordId: this.recordId,
                filters: filters,
                filterLogic: filterLogic,
                batchSize: batchSize,
                recordLimit: recordLimit
            });
            this.defaultFilters = filters;
            this.defaultFilterLogic = filterLogic;
            this.editMode = false;
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async _loadData() {
        await this._getDataFilterInputs();
        await this._getFields();
        await this._getTemplateDetail();
    }

    async _getTemplateDetail() {
        const result = await getTemplateDetail({ recordId: this.recordId });
        this._templateDetail = JSON.parse(result);
    }

    async _getDataFilterInputs() {
        const result = await getDataTemplateFilters({ recordId: this.recordId });
        this.defaultFilterLogic = result.filterLogic;
        this.defaultFilters = result.filters;
    }

    async _getFields() {
        this.fieldsDescribe = await getDescribeObject({ recordId: this.recordId });
    }

    async handleClickDeactivate(event) {
        try {
            this.showSpinner = true;
            this.handleEditCancel();
            const message = await deActivateTemplate({ recordId: this.recordId });
            if (message) {
                this._publishOnMessageChannel(message, 'error', 'add');
            } else {
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.editMode = true;
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleEditCancel() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    _processRefreshInformation(result) {
        if (result.add || result.remove) {
            this._publishRefreshMessage();
            const refreshdEvent = new CustomEvent('refreshdetail', { detail: result });
            this.dispatchEvent(refreshdEvent);
        } else {
            showToastSuccess(this, { message: label.SCHEMA_REFRESHED });
        }
    }

    _publishRefreshMessage() {
        const message = { source: this.view };
        publish(this.messageContext, DATA_TEMPLATE_REFRESH, message);
    }

    _subscribeToRefreshMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, DATA_TEMPLATE_REFRESH, (message) => this._handleRefreshMessage(message), {
                scope: APPLICATION_SCOPE
            });
        }
    }

    _unsubscribeToRefreshMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    async _handleRefreshMessage(message) {
        if (this.view !== message.source) {
            await this._loadData();
        }
    }
}