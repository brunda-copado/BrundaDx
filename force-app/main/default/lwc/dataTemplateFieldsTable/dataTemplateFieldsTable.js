import { LightningElement, api, track, wire } from 'lwc';
import { publish, MessageContext, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import DATA_TEMPLATE_REFRESH from '@salesforce/messageChannel/dataTemplateRefresh__c';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { getSearchedData, getSortedData } from 'c/datatableService';
import {
    label,
    schema,
    OBJECT_FIELDS_COLUMNS,
    PARENT_OBJECTS_COLUMNS,
    CHILD_OBJECTS_COLUMNS,
    REPLACE_PROPERTIES,
    SELECT_COLUMN,
    ATTRIBUTE_COLUMN,
    USE_AS_EXTERNAL_ID_COLUMN,
    CONTENT_UPDATE_COLUMN
} from './constants';
import { sortByExternalIdAndRequired, sortByUseAsExternalId, sortByContentUpdate, createAlert } from './utils';
import { compareRefreshedSchema } from 'c/datatemplateUtil';
import getTemplateDetail from '@salesforce/apex/DataTemplateMainObjectTableCtrl.getTemplateDetail';
import getDescribeObject from '@salesforce/apex/DataTemplateMainObjectTableCtrl.getDescribeObject';
import updateTemplateDetailAttachment from '@salesforce/apex/DataTemplateMainObjectTableCtrl.updateTemplateDetailAttachment';
import refreshFields from '@salesforce/apex/DataTemplateMainObjectTableCtrl.refreshFields';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import deActivateTemplate from '@salesforce/apex/DataTemplateDeactivateCtrl.deActivateTemplate';
export default class DataTemplateFieldsTable extends LightningElement {
    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.DATA_TEMPLATE_ACTIVE] })
    getTemplateDetail({ data, error }) {
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } else if (data) {
            this.dataTemplate = data;
        }
    }

    label = label;

    @api recordId;
    @api view; // object, parent, child
    @api validCredential;

    communicationId = 'DataTemplateAlerts';
    requiredFieldAlertId = 'RequiredField';
    externalFieldAlertId = 'ExternalField';

    subscription = null;

    rows = [];
    filteredRows = [];
    selectedRows = [];
    _objectDescribe;
    _templateDetail;
    _modifiedRows = new Map();
    _originalRows = [];
    _mainObject;

    searchTerm = '';
    editMode = false;
    showSpinner = false;

    // lazy loading
    _table;
    _batchSize = 10;
    _rowOffset = 0;
    _hasMoreData = false;

    // sorting
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy = 'attribute';

    get hideCheckBox() {
        return !this.editMode;
    }

    // Note: object label must be obtained from describe attachment, not from current org, we will improve this in future
    get cardTitle() {
        return (
            (this.view === 'object'
                ? label.OBJECT_FIELDS
                : this.view === 'parent'
                ? label.PARENT_OBJECTS
                : this.view === 'child'
                ? label.CHILD_OBJECTS
                : '') +
            (' (' + this.numberOfItems + ')')
        );
    }

    get itemsTitle() {
        return this.rows ? this.numberOfItems + ' ' + label.FIELDS : '';
    }

    get numberOfItems() {
        return this.rows && this.rows.length ? this.rows.length + (this._hasMoreData ? '+' : '') : '0';
    }

    get columns() {
        let result = [];
        if (this.view === 'object') {
            result = [...OBJECT_FIELDS_COLUMNS];
        } else if (this.view === 'parent') {
            result = [...PARENT_OBJECTS_COLUMNS];
        } else if (this.view === 'child') {
            result = [...CHILD_OBJECTS_COLUMNS];
        }
        if (!this.editMode) {
            result.unshift(SELECT_COLUMN);
        }
        return result;
    }

    get displayIllustration() {
        return this._emptySearch() || this._emptyRelatedObjects();
    }

    get message() {
        return this._emptyRelatedObjects()
            ? this.label.NO_RELATED_OBJECT_MESSAGE.replace('{0}', this.view)
            : this._emptySearch()
            ? this.label.EMPTY_SEARCH_MESSAGE
            : '';
    }

    get tableHeight() {
        return `height: ${this.displayIllustration ? 'auto' : this.editMode ? '45vh' : '52vh'}`;
    }

    async connectedCallback() {
        try {
            this.showSpinner = true;
            this._setDefaultSortByAndDirection();
            await this._loadData();
            this._validateRequiredFieldsSelected();
            this._validateExternalIdSelected();
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

    handleLoadMoreData(event) {
        try {
            if (!this._hasMoreData) {
                return;
            }
            this._table = event.target;

            if (this._table) {
                this._table.isLoading = true;
            }
            // workaround to show spinner
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this._loadMore();
                if (this._table) {
                    this._table.isLoading = false;
                }
            });
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async handleSort(event) {
        try {
            this.showSpinner = true;
            this.sortDirection = event.detail.sortDirection;
            this.sortedBy = event.detail.fieldName;
            await this._setRows();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async handleClickRefresh() {
        try {
            this.showSpinner = true;
            const existingTemplateDetail = JSON.parse(JSON.stringify(this._templateDetail));
            this._clearData();
            await refreshFields({ recordId: this.recordId });
            await this._loadData();
            this._validateRequiredFieldsSelected();
            this._validateExternalIdSelected();
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

    async handleChangeSearchTerm(event) {
        try {
            this.showSpinner = true;
            this.searchTerm = event.detail.value;
            await this._setRows();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleClickEdit(event) {
        try {
            let templateStatus = getFieldValue(this.dataTemplate, schema.DATA_TEMPLATE_ACTIVE);
            if (templateStatus) {
                this.template.querySelector('c-copadocore-modal').show();
            } else {
                this.showSpinner = true;
                this.editMode = true;
                this._updateRowMode();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async handleClickSave(event) {
        try {
            if(this._isDataTemplateSelected()) {
                this.showSpinner = true;
                this.editMode = false;
                await this._getTemplateDetail();
                this._transferModifiedRowsToTemplateDetail();
                await updateTemplateDetailAttachment({ recordId: this.recordId, modifiedTemplateDetail: JSON.stringify(this._templateDetail) });
                this._generateRows();
                this._validateRequiredFieldsSelected();
                this._validateExternalIdSelected();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async handleClickCancel(event) {
        try {
            this.showSpinner = true;
            this.editMode = false;
            await this._returnToOriginalRows();
            if (this._originalRows.length >= this._batchSize) {
                this._hasMoreData = true;
            }
            await this._setRows();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleRowSelection(event) {
        const property = 'isSelected';

        const selectedRows = event.detail.selectedRows;
        const newSelections = selectedRows.filter((row) => !this.selectedRows.some((fieldName) => fieldName === row.name)).map((row) => row.name);
        newSelections.forEach((fieldName) => {
            this._updateModifiedRows(fieldName, true, property);
        });

        const newDeselections = this.selectedRows.filter((fieldName) => !selectedRows.some((row) => fieldName === row.name));
        newDeselections.forEach((fieldName) => {
            this._updateModifiedRows(fieldName, false, property);
        });

        this.selectedRows = selectedRows.map((field) => field.name);
        this._updateRowsWithModifiedValues();
    }

    handleSelectExternalId(event) {
        let fieldName = event.detail.fieldName;
        let useAsExternalId = event.detail.useAsExternalId;
        let property = 'useAsExternalId';
        this._updateModifiedRows(fieldName, useAsExternalId, property);
        this._ensureOnlyOneExternalId(fieldName);
        this._updateRowsWithModifiedValues();
    }

    handleSetFieldContentUpdate(event) {
        const fieldName = event.detail.fieldName;
        const fieldContentUpdate = event.detail.fieldContentUpdate;
        const property = 'fieldContentUpdate';
        this._updateModifiedRows(fieldName, fieldContentUpdate, property);
        if (fieldContentUpdate !== 'replace') {
            this._clearReplaceValues(fieldName);
        }
        this._updateRowsWithModifiedValues();
    }

    handleSetReplaceValue(event) {
        const fieldName = event.detail.fieldName;
        REPLACE_PROPERTIES.forEach((property) => {
            if (event.detail.hasOwnProperty(property)) {
                const replaceValue = event.detail[property];
                this._updateModifiedRows(fieldName, replaceValue, property);
            } else {
                this._updateModifiedRows(fieldName, null, property);
            }
        });
        this._updateRowsWithModifiedValues();
    }

    handleSetDeploymentTemplate(event) {
        const fieldName = event.detail.fieldName;
        const deploymentTemplate = event.detail.deploymentTemplate;
        const deploymentTemplateId = event.detail.deploymentTemplateId;
        const property = 'deploymentTemplate';
        this._updateModifiedRows(fieldName, deploymentTemplate, property);
        // this property is only used to store details in the attachment in the parentObjectsReferenceList property
        this._updateModifiedRows(fieldName, deploymentTemplateId, 'deploymentTemplateId');
        this._updateRowsWithModifiedValues();
    }

    async _loadData() {
        await this._getFields();
        await this._getTemplateDetail();
        await this._generateRows();
    }

    async _getFields() {
        const result = await getDescribeObject({ recordId: this.recordId });
        this._objectDescribe = JSON.parse(result);
    }

    async _getTemplateDetail() {
        const result = await getTemplateDetail({ recordId: this.recordId });
        this._templateDetail = JSON.parse(result);
        this._mainObject = this._templateDetail.dataTemplate.templateMainObject;
    }

    async _returnToOriginalRows() {
        this.rows = [...this._originalRows];
        this._modifiedRows = new Map();
    }

    async _clearData() {
        this._templateDetail = {};
        this._objectDescribe = [];
        this.rows = [];
        this.selectedRows = [];
        this._originalRows = [];
        this._modifiedRows = new Map();
    }

    async _updateRowsWithModifiedValues() {
        const rowsCopy = this._incorporateModifiedFields(this.rows);
        this.rows = [...rowsCopy];
    }

    async _generateRows() {
        const rows =
            this.view === 'object'
                ? this._generateObjectRows()
                : this.view === 'parent'
                ? this._generateParentRows()
                : this.view === 'child'
                ? this._generateChildRows()
                : [];
        this._originalRows = [...rows];
        await this._setRows();
    }

    _generateObjectRows() {
        let rows = [];
        for (const [fieldName, selectableField] of Object.entries(this._templateDetail.selectableFieldsMap)) {
            if (fieldName === 'Id') {
                continue;
            }
            const fieldDetail = this._objectDescribe.find((field) => field.name === fieldName);
            if (fieldDetail) {
                if (this._isReferenceField(fieldName)) {
                    continue;
                }
            }

            const readOnlyMode = true;
            const required = fieldDetail ? fieldDetail.type.toLowerCase() !== 'boolean' && !fieldDetail.nillable : false;
            const recordId = this.recordId;

            let row = {
                ...selectableField,
                required,
                readOnlyMode,
                recordId
            };

            rows.push(row);
        }

        return rows;
    }

    _generateParentRows() {
        let rows = [];
        for (const [fieldName, selectableField] of Object.entries(this._templateDetail.selectableFieldsMap)) {
            if (fieldName === 'Id' || fieldName === 'OwnerId') {
                continue;
            }
            const fieldDetail = this._objectDescribe.find((field) => field.name === fieldName);
            if (fieldDetail) {
                if (!this._isReferenceField(fieldName)) {
                    continue;
                }
            }

            const readOnlyMode = true;
            const required = fieldDetail ? fieldDetail.type.toLowerCase() !== 'boolean' && !fieldDetail.nillable : false;
            const recordId = this.recordId;

            const objectLabel =
                selectableField.parentObjectApiNameMap && Object.values(selectableField.parentObjectApiNameMap).length > 0
                    ? Object.values(selectableField.parentObjectApiNameMap)[0]
                    : null;
            const objectName =
                selectableField.parentObjectApiNameMap && Object.keys(selectableField.parentObjectApiNameMap).length > 0
                    ? Object.keys(selectableField.parentObjectApiNameMap)[0]
                    : null;
            const parentReference = this._templateDetail.parentObjectsReferenceList.find((reference) => reference.relationName === fieldName);
            const deploymentTemplateId = parentReference ? parentReference.templateId : null;

            const row = {
                ...selectableField,
                required,
                readOnlyMode,
                recordId,
                objectLabel,
                objectName,
                deploymentTemplateId
            };

            rows.push(row);
        }

        return rows;
    }

    _generateChildRows() {
        let rows = [];
        for (const [key, selectableChildRelation] of Object.entries(this._templateDetail.selectableChildRelationsMap)) {
            const readOnlyMode = true;
            const required = false;
            const recordId = this.recordId;

            const objectLabel =
                selectableChildRelation.objectApiNameMap && Object.values(selectableChildRelation.objectApiNameMap).length > 0
                    ? Object.values(selectableChildRelation.objectApiNameMap)[0]
                    : null;
            const objectName =
                selectableChildRelation.objectApiNameMap && Object.keys(selectableChildRelation.objectApiNameMap).length > 0
                    ? Object.keys(selectableChildRelation.objectApiNameMap)[0]
                    : null;
            const childReference = this._templateDetail.childrenObjectsReferenceList.find(
                (reference) => reference.relationName === selectableChildRelation.relationshipName
            );
            const deploymentTemplateId = childReference ? childReference.templateId : null;

            // Note: this is the key for the selectableChildRelationsMap (field-relationshipName), as it is used by the table to match entries in the map
            const name = key;

            const row = {
                ...selectableChildRelation,
                required,
                readOnlyMode,
                recordId,
                objectLabel,
                objectName,
                deploymentTemplateId,
                name
            };

            rows.push(row);
        }

        return rows;
    }

    async _loadMore() {
        const rows = [...this.filteredRows];
        const sortedData = this._applySort(rows, { name: this.sortedBy, sortDirection: this.sortDirection });
        if (this._rowOffset < sortedData.length) {
            const moreData = sortedData.slice(0, this._rowOffset + this._batchSize);
            if (moreData && moreData.length) {
                this.rows = [...moreData];
                // Note: without this the table is not re-rendering the select checkbox
                this.selectedRows = [...this.selectedRows];
                this._rowOffset = this.rows.length;
                this._hasMoreData = this._rowOffset < sortedData.length;
                if (this.editMode) {
                    this._updateRowsWithModifiedValues();
                    this._updateRowMode();
                }
                this._populateSelectedRows();
            }
        } else {
            this._hasMoreData = false;
        }
    }

    _applySort(rows, sortConfiguration) {
        if (rows && rows.length) {
            if (sortConfiguration.name === ATTRIBUTE_COLUMN.fieldName) {
                return sortByExternalIdAndRequired(rows, sortConfiguration);
            } else if (sortConfiguration.name === USE_AS_EXTERNAL_ID_COLUMN.fieldName) {
                return sortByUseAsExternalId(rows, sortConfiguration);
            } else if (sortConfiguration.name === CONTENT_UPDATE_COLUMN.fieldName) {
                return sortByContentUpdate(rows, sortConfiguration);
            } else {
                return getSortedData(this.columns, rows, sortConfiguration);
            }
        } else {
            return rows;
        }
    }

    _isReferenceField(fieldName) {
        let result = false;
        const fieldDetail = this._objectDescribe.find((field) => field.name === fieldName);
        if (fieldDetail) {
            result = fieldDetail.type === 'reference' && fieldDetail.referenceTo != null && fieldDetail.referenceTo.length > 0;
        }
        return result;
    }

    async _applySearch(rows) {
        let result = [];
        if (this.searchTerm.length < 3) {
            result = [...rows];
        } else {
            if (this.searchTerm && this.searchTerm.toLowerCase() === 'xid') {
                result = this._originalRows.filter((row) => row.externalId === true);
            } else {
                const filteredRawData = await getSearchedData(this.columns, rows, this.searchTerm);
                if (filteredRawData) {
                    result = [...filteredRawData];
                } else {
                    result = [...rows];
                }
            }
        }
        return result;
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
                this._updateRowMode();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    _incorporateModifiedFields(data) {
        return data.map((field) => {
            if (this._modifiedRows.has(field.name)) {
                field = this._modifiedRows.get(field.name);
            }
            return field;
        });
    }

    _updateRowMode() {
        this.rows = this.rows.map((field) => {
            return { ...field, readOnlyMode: false };
        });
    }

    _setReadOnlyMode() {
        this.rows = this.rows.map((field) => {
            return { ...field, readOnlyMode: true };
        });
    }

    _ensureOnlyOneExternalId(fieldName) {
        // modify rows to update false in other useAsExternalIdValue if any values are present in table.
        this.rows = this.rows.map((field) => {
            if (field.externalId && field.name != fieldName) {
                field['useAsExternalId'] = false;
            }
            return field;
        });

        //update Other ExternalId field's useasexternalIdValues to false and store it in _modifiedRows
        this._originalRows
            .filter((field) => {
                return field.externalId && field.name != fieldName;
            })
            .forEach((field) => {
                this._updateModifiedRows(field.name, false, 'useAsExternalId');
            });
    }

    _clearReplaceValues(fieldName) {
        REPLACE_PROPERTIES.forEach((property) => {
            this._updateModifiedRows(fieldName, null, property);
        });
    }

    _transferModifiedRowsToTemplateDetail() {
        this._modifiedRows.forEach((value, key) => {
            this._transferSelected(key, value);
            this._transferUseAsExternalId(key, value);
            this._transferContentUpdate(key, value);
            this._transferReferences(key, value);
        });
        this._modifiedRows = new Map();
    }

    _transferSelected(key, value) {
        if (this.view === 'object' || this.view === 'parent') {
            this._templateDetail.selectableFieldsMap[key].isSelected = value.isSelected;
        } else if (this.view === 'child') {
            this._templateDetail.selectableChildRelationsMap[key].isSelected = value.isSelected;
        }
    }

    _transferUseAsExternalId(key, value) {
        if (this.view === 'object') {
            this._templateDetail.selectableFieldsMap[key].useAsExternalId = value.useAsExternalId;
        }
    }

    _transferContentUpdate(key, value) {
        if (this.view === 'object') {
            this._templateDetail.selectableFieldsMap[key].fieldContentUpdate = value.fieldContentUpdate;
            REPLACE_PROPERTIES.forEach((property) => {
                this._templateDetail.selectableFieldsMap[key][property] = value[property];
            });
        }
    }

    _transferReferences(key, value) {
        if (this.view === 'parent' || this.view === 'child') {
            const mapToTransfer = this.view === 'parent' ? 'selectableFieldsMap' : 'selectableChildRelationsMap';
            const referenceList = this.view === 'parent' ? 'parentObjectsReferenceList' : 'childrenObjectsReferenceList';
            const relationShipName = this.view === 'parent' ? key : value.relationshipName;
            const childSObject = this.view === 'child' ? this._templateDetail[mapToTransfer][key]['childSObject'] : null;
            this._templateDetail[mapToTransfer][key].deploymentTemplate = value.deploymentTemplate;
            // needed for backwards compatibility?
            this._templateDetail[mapToTransfer][key].deploymentTemplateNameMap = {};
            this._templateDetail[mapToTransfer][key].deploymentTemplateNameMap[value.deploymentTemplateId] = value.deploymentTemplate;

            const referenceIndex = this._templateDetail[referenceList].findIndex((reference) => reference.relationName === relationShipName);
            if (value.hasOwnProperty('deploymentTemplateId')) {
                if (referenceIndex !== -1) {
                    let existingReference = this._templateDetail[referenceList][referenceIndex];
                    existingReference.templateId = value['deploymentTemplateId'];
                } else {
                    this._templateDetail[referenceList] = [
                        ...this._templateDetail[referenceList],
                        {
                            templateId: value['deploymentTemplateId'],
                            relationName: relationShipName,
                            childSObject: childSObject
                        }
                    ];
                }
            }
            if (!value.isSelected && referenceIndex !== -1) {
                this._templateDetail[referenceList].splice(referenceIndex, 1);
            }
        }
    }

    _updateModifiedRows(fieldName, value, property) {
        if (!this._modifiedRows.has(fieldName)) {
            let field = this.rows.find((field) => field.name === fieldName);
            if (field) {
                this._modifiedRows.set(fieldName, field);
            }
        }
        this._modifiedRows.get(fieldName)[property] = value;
    }

    _populateSelectedRows() {
        this.selectedRows = this.rows.filter((row) => row.isSelected).map((field) => field.name);
    }

    async _setRows() {
        this.filteredRows = await this._applySearch(this._originalRows);
        const sortedData = this._applySort(this.filteredRows, { name: this.sortedBy, sortDirection: this.sortDirection });
        this.rows = [...sortedData].slice(0, this._rowOffset + this._batchSize);
        this._updateRowsWithModifiedValues();
        this._populateSelectedRows();
        if (this.editMode) {
            this._updateRowMode();
        } else {
            this._setReadOnlyMode();
        }
        // Note: without this the table is not re-rendering the select checkbox
        this.selectedRows = [...this.selectedRows];
        this._rowOffset = this.rows.length;
        this._hasMoreData = this._rowOffset < sortedData.length;
    }

    _prepareData(rows) {
        const data = [...rows].slice(0, this._batchSize);
        this.rows = [...data];
        this._updateRowsWithModifiedValues();
        this._populateSelectedRows();
        this._rowOffset = this.rows.length;
    }

    _setDefaultSortByAndDirection() {
        this.sortedBy = this.view === 'child' ? 'objectLabel' : 'attribute';
        this.sortDirection = this.view === 'child' ? 'asc' : 'desc';
    }

    _emptySearch() {
        return this.searchTerm && this.rows && this.rows.length === 0;
    }

    _emptyRelatedObjects() {
        return (this.view === 'parent' || this.view === 'child') && this._templateDetail && this._originalRows && this._originalRows.length === 0;
    }

    _validateRequiredFieldsSelected() {
        if (this.view !== 'child') {
            // clear existing message
            this._publishOnMessageChannel(undefined, undefined, this.requiredFieldAlertId, 'remove');
            for (const [fieldName, selectableField] of Object.entries(this._templateDetail.selectableFieldsMap)) {
                const fieldDetail = this._objectDescribe.find((field) => field.name === fieldName);
                const required = fieldDetail ? fieldDetail.type.toLowerCase() !== 'boolean' && !fieldDetail.nillable : false;
                if (required && !selectableField.isSelected) {
                    this._publishOnMessageChannel(label.REQUIRED_FIELD_NOT_SELECTED, 'warning', this.requiredFieldAlertId, 'add');
                    break;
                }
            }
        }
    }

    _validateExternalIdSelected() {
        if (this.view === 'object') {
            // clear existing message
            this._publishOnMessageChannel(undefined, undefined, this.externalFieldAlertId, 'remove');
            const externalIdFields = Object.values(this._templateDetail.selectableFieldsMap).filter((field) => field.externalId);
            const externalIdUsed = externalIdFields.length > 0 ? externalIdFields.some((field) => field.isSelected && field.useAsExternalId) : true;
            if (!externalIdUsed) {
                this._publishOnMessageChannel(label.EXTERNAL_ID_WARNING_MESSAGE, 'warning', this.externalFieldAlertId, 'add');
            }
        }
    }

    _publishOnMessageChannel(message, type, alertId, operation, dismissible) {
        dismissible = dismissible === undefined ? true : dismissible;
        const alertMessage = createAlert(message, type, dismissible, this.communicationId, alertId, operation);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);
    }

    _processRefreshInformation(result) {
        //Note: After comparing the new schema and old schema, the expected result format
        //result = { add: [{ id: 'test_Field__c', message: 'Test Field added' }], remove: [{ id: 'test_Field2__c', message: 'Test Field2 removed' }] };
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
            this._validateRequiredFieldsSelected();
            this._validateExternalIdSelected();
        }
    }

    handleEditCancel() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    _isDataTemplateSelected() {
        if(this.view === "object") {
            return true;
        }
       return ![...this._modifiedRows.values()].find((row) => row.isSelected && !row.deploymentTemplateId && row.objectName !== "User");
    }
}