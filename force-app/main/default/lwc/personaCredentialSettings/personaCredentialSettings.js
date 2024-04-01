import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { showToastError } from 'c/copadocoreToastNotification';
import { namespace, reduceErrors, formatLabel } from 'c/copadocoreUtils';
import { getSortedData, getSearchedData } from 'c/datatableService';
import { getCredentials, getCredentialsForPersona, shareCredentials } from 'c/personaManagementService';

import { label, schema, ACCESS_LEVEL, EDIT_ACCESS_LEVEL } from './constants';

export default class PersonaCredentialSettings extends LightningElement {
    _personaDefinition;

    @api
    get personaDefinition() {
        return this._personaDefinition;
    }

    set personaDefinition(personaDefinition) {
        this._personaDefinition = personaDefinition;
        this._loadPersonaCredentials();
    }

    label = label;

    // error handling
    showError = false;
    errorMessage;

    // spinner
    isRunning = true;
    objectInfoLoaded = false;

    // table
    personaCredentials = [];
    personaCredentialColumns = [];
    allCredentials = [];
    allCredentialColumns = [];

    // sorting
    defaultSortDirectionPersonaCredentials = 'asc';
    sortDirectionPersonaCredentials = 'asc';
    sortedByPersonaCredentials = schema.NAME_FIELD.fieldApiName;
    defaultSortDirectionAllCredentials = 'asc';
    sortDirectionAllCredentials = 'asc';
    sortedByAllCredentials = schema.NAME_FIELD.fieldApiName;

    // searching
    searchTermPersonaCredentials = '';
    searchedPersonaCredentials = [];
    searchTermAllCredentials = '';
    searchedAllCredentials = [];

    @wire(getObjectInfo, { objectApiName: schema.CREDENTIAL_OBJECT })
    credentialInfo({ data, error }) {
        if (data) {
            this._createColumns(data);
            this.objectInfoLoaded = true;
            this._loadPersonaCredentials();
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
            this.objectInfoLoaded = true;
        }
    }

    get personaId() {
        return this.personaDefinition.Id;
    }

    get personaName() {
        return this.personaDefinition.Name;
    }

    get defaultAccessLevel() {
        return JSON.parse(this.personaDefinition[namespace + 'Config_JSON__c']).defaultCredentialAccessLevel.toUpperCase() ===
            EDIT_ACCESS_LEVEL.toUpperCase()
            ? label.Read_Write
            : label.Read_Only;
    }

    get isEmpty() {
        return this.personaCredentials.length === 0;
    }

    get showSpinner() {
        return this.isRunning || !this.objectInfoLoaded;
    }

    get saveDisabled() {
        return this.isRunning || this.selectedCount === 0;
    }

    get subtitle() {
        return formatLabel(label.Credential_Settings_Subtitle, [this.personaName]);
    }

    get selectedRecordsToAdd() {
        const selectedRecords = this.template.querySelector('lightning-datatable[data-id="allCredentialsTable"]')?.getSelectedRows();
        return selectedRecords ? selectedRecords : [];
    }

    get selectedCount() {
        return this.selectedRecordsToAdd ? this.selectedRecordsToAdd.length : 0;
    }

    get availableAllCredentials() {
        return this.searchTermAllCredentials ? this.searchedAllCredentials : this.allCredentials;
    }

    get availablePersonaCredentials() {
        return this.searchTermPersonaCredentials ? this.searchedPersonaCredentials : this.personaCredentials;
    }

    handleShareCredential(event) {
        event.preventDefault();
        this.template.querySelector('c-cds-modal').show();
        this._loadAllCredentials();
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'changeAccessLevel':
                this.handlechangeAccessLevel(row.Id);
                break;
            case 'stopSharing':
                this.handlestopSharingCred(row.Id);
                break;
            default:
        }
    }
    handlechangeAccessLevel(credentialId) {
        const modal = this.template.querySelector('c-change-access-level-cred-modal');
        modal.setPersonaCredential(this.personaId, credentialId);
        modal.show();
    }
    handlestopSharingCred(credentialId) {
        const modal = this.template.querySelector('c-stop-sharing-cred-confirmation-modal');
        modal.setPersonaCredential(this.personaId, credentialId);
        modal.show();
    }

    handleSearchPersonaCredentials(event) {
        try {
            const searchObj = event.detail;
            this.searchTermPersonaCredentials = searchObj.searchTerm;
            this.searchedPersonaCredentials = [...searchObj.searchedData];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleClearSearchPersonaCredentials() {
        try {
            this.searchTermPersonaCredentials = '';
            this.searchedPersonaCredentials = [];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleSearchAllCredentials(event) {
        try {
            const searchObj = event.detail;
            this.searchTermAllCredentials = searchObj.searchTerm;
            this.searchedAllCredentials = [...searchObj.searchedData];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleClearSearchAllCredentials() {
        try {
            this.searchTermAllCredentials = '';
            this.searchedAllCredentials = [];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleRefreshAllCredentialsTable() {
        this._loadAllCredentials();
    }

    handleCancelModal() {
        this._closeModal();
    }

    async handleSaveShareCredentials() {
        try {
            this.isRunning = true;
            let credentialIds = [];
            this.selectedRecordsToAdd.forEach(element => {
                credentialIds.push(element.Id);
            });
            await shareCredentials({ personaId: this.personaId, credentialIds: credentialIds });
            this._closeModal();
            this.refreshPersonaCredentialRows();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this.showError = true;
            this.errorMessage = errorMessage;
        } finally {
            this.isRunning = false;
        }
    }

    refreshPersonaCredentialRows() {
        this._loadPersonaCredentials();
    }

    handleSortPersonaCredentials(event) {
        this.sortDirectionPersonaCredentials = event.detail.sortDirection;
        this.sortedByPersonaCredentials = event.detail.fieldName;
        this._sortPersonaCredentials();
    }

    handleSortAllCredentials(event) {
        this.sortDirectionAllCredentials = event.detail.sortDirection;
        this.sortedByAllCredentials = event.detail.fieldName;
        this._sortAllCredentials();
    }

    // PRIVATE

    _createColumns(data) {
        const commonColumns = [
            {
                label: data.fields[schema.NAME_FIELD.fieldApiName].label,
                fieldName: schema.NAME_FIELD.fieldApiName,
                sortable: true,
                searchable: true
            },
            {
                label: data.fields[schema.ENVIRONMENT_FIELD.fieldApiName].label,
                fieldName: schema.ENVIRONMENT_FIELD.fieldApiName.replace('__c', '__r') + '.' + schema.ENVIRONMENT_NAME_FIELD.fieldApiName,
                sortable: true,
                searchable: true
            },
            {
                label: data.fields[schema.PLATFORM_FIELD.fieldApiName].label,
                fieldName: schema.PLATFORM_FIELD.fieldApiName,
                sortable: true,
                searchable: true
            },
            {
                label: data.fields[schema.ORG_TYPE_FIELD.fieldApiName].label,
                fieldName: schema.ORG_TYPE_FIELD.fieldApiName,
                sortable: true
            },
            {
                label: label.Access_Level,
                fieldName: ACCESS_LEVEL,
                sortable: true
            }
        ];
        this.personaCredentialColumns = [
            ...commonColumns,
            {
                type: 'action',
                typeAttributes: {
                    rowActions: [
                        { label: label.Change_Access_Level, name: 'changeAccessLevel', iconName: 'utility:lock', iconPosition: 'left' },
                        { label: label.Stop_Sharing, name: 'stopSharing', iconName: 'utility:ban', iconPosition: 'left' }
                    ]
                }
            }
        ];
        this.allCredentialColumns = [...commonColumns];
    }

    async _loadPersonaCredentials() {
        try {
            this.isRunning = true;
            const personaCredentials = await getCredentialsForPersona({ personaId: this.personaId });
            this.personaCredentials = personaCredentials.map(personaCredential => {
                const environmentField =
                    schema.ENVIRONMENT_FIELD.fieldApiName.replace('__c', '__r') + '.' + schema.ENVIRONMENT_NAME_FIELD.fieldApiName;
                const environmentValue = personaCredential.credential[schema.ENVIRONMENT_FIELD.fieldApiName]
                    ? personaCredential.credential[schema.ENVIRONMENT_FIELD.fieldApiName.replace('__c', '__r')][
                          schema.ENVIRONMENT_NAME_FIELD.fieldApiName
                      ]
                    : '';
                return {
                    Id: personaCredential.credential.Id,
                    [schema.NAME_FIELD.fieldApiName]: personaCredential.credential[schema.NAME_FIELD.fieldApiName],
                    [environmentField]: environmentValue,
                    [schema.PLATFORM_FIELD.fieldApiName]: personaCredential.credential[schema.PLATFORM_FIELD.fieldApiName],
                    [schema.ORG_TYPE_FIELD.fieldApiName]: personaCredential.credential[schema.ORG_TYPE_FIELD.fieldApiName],
                    [ACCESS_LEVEL]:
                        personaCredential.credentialShare[ACCESS_LEVEL].toUpperCase() === EDIT_ACCESS_LEVEL.toUpperCase()
                            ? label.Read_Write
                            : label.Read_Only
                };
            });
            this._sortPersonaCredentials();
            this._searchPersonaCredentials();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.isRunning = false;
        }
    }

    async _loadAllCredentials() {
        try {
            this.isRunning = true;
            const allCredentials = await getCredentials();
            const alreadyShared = this.personaCredentials.map(personaCredential => personaCredential.Id);
            this.allCredentials = allCredentials
                .filter(credential => !alreadyShared.includes(credential.Id))
                .map(credential => {
                    const environmentField =
                        schema.ENVIRONMENT_FIELD.fieldApiName.replace('__c', '__r') + '.' + schema.ENVIRONMENT_NAME_FIELD.fieldApiName;
                    const environmentValue = credential[schema.ENVIRONMENT_FIELD.fieldApiName]
                        ? credential[schema.ENVIRONMENT_FIELD.fieldApiName.replace('__c', '__r')][schema.ENVIRONMENT_NAME_FIELD.fieldApiName]
                        : '';
                    return {
                        ...credential,
                        [environmentField]: environmentValue,
                        [ACCESS_LEVEL]: this.defaultAccessLevel
                    };
                });
            this._sortAllCredentials();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.isRunning = false;
        }
    }

    _sortPersonaCredentials() {
        if (this.personaCredentialColumns.length > 0) {
            this.personaCredentials = getSortedData(this.personaCredentialColumns, this.personaCredentials, {
                name: this.sortedByPersonaCredentials,
                sortDirection: this.sortDirectionPersonaCredentials
            });
        }
    }

    _searchPersonaCredentials() {
        if (this.personaCredentialColumns.length > 0) {
            this.searchedPersonaCredentials = getSearchedData(
                this.personaCredentialColumns,
                this.personaCredentials,
                this.searchTermPersonaCredentials
            );
        }
    }

    _sortAllCredentials() {
        if (this.allCredentialColumns.length > 0) {
            this.allCredentials = getSortedData(this.allCredentialColumns, this.allCredentials, {
                name: this.sortedByAllCredentials,
                sortDirection: this.sortDirectionAllCredentials
            });
        }
    }

    _closeModal() {
        this.template.querySelector('c-cds-modal').hide();
        this.searchTermAllCredentials = '';
        this.searchedAllCredentials = [];
        this.showError = false;
        this.errorMessage = null;
    }
}