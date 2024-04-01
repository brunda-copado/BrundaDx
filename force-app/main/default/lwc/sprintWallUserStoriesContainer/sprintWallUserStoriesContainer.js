import { LightningElement, api, wire } from 'lwc';
import { getRecordNotifyChange, getRecord } from 'lightning/uiRecordApi';

import { publish, MessageContext } from 'lightning/messageService';
import alertMessage from '@salesforce/messageChannel/CopadoAlert__c';

import isSprintWallLicenseEnabled from '@salesforce/apex/LicenseHelper.isSprintWallLicenseEnabled';
import isUserStoriesTeamSame from '@salesforce/apex/SprintWallUserStoriesCtrl.isUserStoriesTeamSame';

import { schema, constants, getNamespace } from './constants';
import { reduceErrors } from 'c/copadocoreUtils';
import { getRelatedListConfiguration, getColumnsConfiguration, getUpgradedColumnConfiguration, getRowsData } from 'c/datatableService';

export default class SprintWallUserStoriesContainer extends LightningElement {
    @api recordId;
    @api fieldset = schema.FIELD_SET_NAME;
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [schema.TEAM_FIELD_SET_NAME_FIELD.objectApiName + '.' + schema.TEAM_FIELD_SET_NAME_FIELD.fieldApiName]
    })
    getSpecificFieldSet(result) {
        let ns = getNamespace(),
            teamRelation = ns + constants.TEAM_OBJECT_RELATION,
            teamFieldSet = ns + constants.TEAM_FIELD_SET_FIELD_NAME;
        if (typeof result.data !== constants.UNDEFINED) {
            var objectRecords = result.data.fields;
            if (objectRecords) {
                if (objectRecords[teamRelation] && objectRecords[teamRelation].value) {
                    this._teamCheck();
                    let fieldSetName = objectRecords[teamRelation].value.fields[teamFieldSet].value;
                    if (fieldSetName) {
                        this.fieldset = fieldSetName;
                    }
                } else {
                    this._publishTeamAlert(true);
                }
            }
        }
    }

    orderBy = constants.ORDER_BY;
    rows = [];
    columns = [];
    showSpinner = false;
    queryConfig;
    recordLimit = constants.NUMBER_OF_RECORDS_LIMIT;

    schema = schema;
    relatedListConfig;

    _recordsOffset = 0;
    _isLicenseRestricted = false;
    _rowFetched = false;
    _colFetched = false;
    _relatedListInfoFetched = false;
    _isRendered = false;
    _hasTeam = false;

    get hasRows() {
        return !this._isLicenseRestricted && this._rowFetched && this._colFetched && this._relatedListInfoFetched ? true : false;
    }

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this._licenseCheck();
    }
    // TEMPLATE

    handleRefreshData() {
        this.showSpinner = true;
        this._rowFetched = false;
        this._fetchDataRows();
        const notifyChangeIds = [{ recordId: this.recordId }];
        getRecordNotifyChange(notifyChangeIds);
    }

    // PRIVATE

    async _licenseCheck() {
        try {
            const isLicenseEnabled = await isSprintWallLicenseEnabled();
            if (isLicenseEnabled) {
                this._fetchRelatedListConfiguration();
            } else {
                this._isLicenseRestricted = true;
                this._publishFlexiPageAlert(this._prepareAlert(constants.LICENSE_RESTRICTION_ERROR, constants.WARNING_VARIANT, false));
            }
        } catch (error) {
            this._processError(null, error);
        }
    }

    async _teamCheck() {
        try {
            const isTeamSame = await isUserStoriesTeamSame({ sprintId: this.recordId });
            this._publishTeamAlert(isTeamSame);
        } catch (error) {
            this._processError(null, error);
        }
    }

    _publishTeamAlert(isTeamSame){
        this._publishFlexiPageAlert(this._prepareTeamAlert(constants.DIFFERENT_TEAMS_WARNING, constants.WARNING_VARIANT, false, constants.ALERT_OPERATION_REMOVE));
        if (!isTeamSame  ) {
            this._publishFlexiPageAlert(this._prepareTeamAlert(constants.DIFFERENT_TEAMS_WARNING, constants.WARNING_VARIANT, true, constants.ALERT_OPERATION_ADD));
        } 
    }

    async _fetchRelatedListConfiguration() {
        try {
            const childObjectConfiguration = {
                apiName: schema.USER_STORY,
                relationshipField: schema.SPRINT_FIELD
            };
            const config = await getRelatedListConfiguration(this, this.recordId, childObjectConfiguration);
            if (config) {
                this.relatedListConfig = config;
                this.relatedListConfig.sobjectLabelPlural = constants.RELATED_LIST_NAME;
                this._relatedListInfoFetched = true;
                this._fetchColumnConfigurations();
            }
        } catch (error) {
            this._processError(constants.RELATED_LIST_ERROR, error);
        }
    }

    async _fetchColumnConfigurations() {
        try {
            const columnsConfiguration = {
                objectApiName: schema.USER_STORY,
                fieldSetName: this.fieldset,
                hideDefaultColumnsActions: constants.HIDE_DEFAULT_COLUMNS_ACTION,
                sortable: constants.SORTABLE,
                editable: constants.ENABLE_INLINE_EDITING,
                searchable: constants.SEARCHABLE,
                filterable: constants.FILTERABLE
            };
            const data = await getColumnsConfiguration(this, columnsConfiguration);
            if (data && data.length) {
                const columnConfigs = getUpgradedColumnConfiguration(data, constants.ROW_ACTIONS, false);

                this.columns = columnConfigs;
                this._setAdditionalRestrictions();
                this._fetchDataRows();
            } else {
                this._handleError(String.format(constants.NO_COLUMN_CONFIG_ERROR, this.fieldset));
            }
        } catch (error) {
            this._processError(constants.FETCH_COLUMN_CONFIG_ERROR, error);
        }
    }
    _setAdditionalRestrictions() {
        if (this.columns) {
            this.columns.forEach((column) => {
                column.editable = this._setNonEditableField(column);
            });
            this._colFetched = true;
        }
    }

    _setNonEditableField(column) {
        const isRelatedRecordField = column.fieldName && column.fieldName.includes('.');
        const isFieldTypePicklist =
            column.typeAttributes && column.typeAttributes.fieldType && column.typeAttributes.fieldType.toLowerCase() === constants.PICKLIST;

        if ((isFieldTypePicklist || isRelatedRecordField) && column.editable) {
            column.editable = false;
        }
        return column.editable;
    }

    async _fetchDataRows() {
        try {
            const queryConfig = {
                fieldSetName: this.fieldset,
                objectApiName: schema.USER_STORY,
                relationshipFieldApi: schema.SPRINT_FIELD,
                recordId: this.recordId,
                orderBy: this.orderBy,
                numberOfRecordsLimit: this.recordLimit,
                recordsOffset: this._recordsOffset
            };
            this.queryConfig = queryConfig;
            const data = await getRowsData(this, queryConfig);
            this.rows = [];
            if (data) {
                this.rows = data;
            }
            this._rowFetched = true;
            this.showSpinner = false;
        } catch (error) {
            this._processError(constants.FETCH_DATA_ERROR, error);
        }
    }

    _processError(title, error) {
        console.error(error);
        title = title ? title + ': ' : '';
        const errorMessage = reduceErrors(error);
        this._handleError(title + errorMessage);
    }

    _handleError(message) {
        this._publishFlexiPageAlert(this._prepareAlert(message, constants.ERROR_VARIANT, true));
        this.rows = [];
        this._colFetched = true;
        this._rowFetched = true;
        this.showSpinner = false;
    }

    _publishFlexiPageAlert(alert) {
        publish(this.messageContext, alertMessage, alert);
    }

    _prepareAlert(message, variant, isDismissible) {
        return { message: message, variant: variant, dismissible: isDismissible, communicationId: constants.SPRINT_WALL_ALERT_COMMUNICATION_ID };
    }

    _prepareTeamAlert(message, variant, isDismissible, operation) {
        return { message: message, variant: variant, dismissible: isDismissible, operation: operation, id: constants.TEAM_ALERT_ID, communicationId: constants.SPRINT_WALL_ALERT_COMMUNICATION_ID };
    }
}