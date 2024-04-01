import { LightningElement, api } from 'lwc';

import { schema, label, constants, infoAlert } from './constants';
import { reduceErrors, handleAsyncError } from 'c/copadocoreUtils';

import { getColumnsConfiguration, saveRecords } from 'c/datatableService';

import search from '@salesforce/apex/CustomLookupComponentHelper.search';

export default class SprintWallEditStoriesPopup extends LightningElement {
    @api selectedRows = [];

    label = label;
    schema = schema;
    infoAlert = infoAlert;
    alert;

    showSpinner = false;
    columns = [];

    _valueByField = new Map();

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.selectedRows = [];
        this._valueByField = new Map();
        this.template.querySelector('c-copadocore-modal').hide();
    }

    connectedCallback() {
        this._fetchColumnConfigurations();
    }

    // TEMPLATE

    handleCloseAlert(event) {
        this.alert = null;
    }

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._search, {
            title: label.ERROR_SEARCHING_RECORDS
        });

        const queryConfig = {
            searchField: schema.NAME,
            objectName: schema.USER,
            searchKey: event.detail.searchTerm,
            extraFilterType: undefined,
            filterFormattingParameters: undefined
        };

        const result = await safeSearch(this, { queryConfig, objectLabel: 'Function' });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }

    getSelectedId(lookupData) {
        if (lookupData.detail.length) {
            this._valueByField.set(schema.OWNER_FIELD, lookupData.detail[0]);
        } else {
            this._valueByField.set(schema.OWNER_FIELD, undefined);
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        if (this._validateInput(fields)) {
            this._save(this._prepareRecords());
        } else {
            this.hide();
        }
    }

    handleCancel(event) {
        this.hide();
    }

    // PRIVATE

    async _fetchColumnConfigurations() {
        try {
            const columnsConfiguration = {
                objectApiName: schema.USER_STORY,
                fieldSetName: schema.FIELD_SET_NAME,
                hideDefaultColumnsActions: true,
                sortable: false,
                editable: true,
                searchable: false,
                filterable: false
            };
            const columnConfigs = await getColumnsConfiguration(this, columnsConfiguration);
            if (columnConfigs && columnConfigs.length) {
                this.columns = this._setAllowedFields(columnConfigs);
            } else {
                this._handleError(String.format(constants.NO_COLUMN_CONFIG_ERROR, schema.FIELD_SET_NAME));
            }
        } catch (error) {
            console.error(error);
            const errorMessage = reduceErrors(error);
            this._handleError(constants.FETCH_COLUMN_CONFIG_ERROR + ': ' + errorMessage);
        }
    }

    _setAllowedFields(columnConfigs) {
        const result = [];
        columnConfigs.forEach((column) => {
            const isFieldTypeReference =
                column.typeAttributes && column.typeAttributes.fieldType && column.typeAttributes.fieldType.toLowerCase() === constants.REFERENCE;

            let field;
            if (isFieldTypeReference) {
                field = this._getReferenceFieldObject(column);
            } else {
                field = this._getFieldObject(column);
            }

            if (field) {
                result.push(field);
            }
        });
        return result;
    }

    _getReferenceFieldObject(column) {
        if (column.typeAttributes.isUpdateable) {
            const fieldPath = column.typeAttributes.fieldPath;
            const isCustomLookup = this._isCustomLookup(fieldPath);
            if (!this._isNotAllowedReference(fieldPath)) {
                return {
                    fieldName: fieldPath,
                    label: column.label,
                    type: column.type,
                    fieldType: column.typeAttributes.fieldType,
                    isCustomLookup: isCustomLookup
                };
            }
        }
    }

    _isCustomLookup(field) {
        return constants.CUSTOM_LOOKUPS.includes(field.toLowerCase());
    }

    _isNotAllowedReference(field) {
        return constants.NOT_ALLOWED_REFERENCE_FIELDS.includes(field.toLowerCase());
    }

    _getFieldObject(column) {
        const isAllowedField = column.editable && !column.fieldName.includes('.');
        if (isAllowedField) {
            return { fieldName: column.fieldName, label: column.label, type: column.type, fieldType: column.typeAttributes.fieldType };
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _search(self, queryConfig) {
        return search(queryConfig);
    }

    _validateInput(row) {
        this.columns.forEach((field) => {
            if (row[field.fieldName]) {
                this._valueByField.set(field.fieldName, row[field.fieldName]);
            }
        });
        return this._valueByField.size;
    }

    _prepareRecords() {
        this.showSpinner = true;
        const result = { detail: { draftValues: [] } };
        const records = [];
        this.selectedRows.forEach((eachRow) => {
            const row = {};
            row.Id = eachRow.Id;
            this._valueByField.forEach((value, field) => {
                row[field] = value;
            });
            records.push(row);
        });
        result.detail.draftValues = records;
        return result;
    }

    async _save(records) {
        try {
            const result = await saveRecords(this, records);
            if (result) {
                this._handleRefresh();
            }
        } catch (error) {
            this.showSpinner = false;
            const errorMessage = reduceErrors(error);
            this._handleError(constants.UPDATE_RECORD_ERROR_TITLE + ': ' + errorMessage);
        }
    }

    _handleRefresh() {
        this.dispatchEvent(new CustomEvent('refreshdata'));
    }

    _handleError(message) {
        this.alert = {
            message: message,
            variant: constants.ERROR_VARIANT,
            dismissible: true
        };
    }
}