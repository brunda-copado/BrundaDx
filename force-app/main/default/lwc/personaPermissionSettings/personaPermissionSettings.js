import { LightningElement, api } from 'lwc';
import { reduceErrors, formatLabel } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';
import { getSortedData } from 'c/datatableService';

import { getPermissionSetGroups, getPermissionsForPersona, addPermissionSetGroup } from 'c/personaManagementService';

import { label } from './constants';

export default class PersonaPermissionSettings extends LightningElement {
    _personaDefinition;

    @api
    get personaDefinition() {
        return this._personaDefinition;
    }

    set personaDefinition(personaDefinition) {
        this._personaDefinition = personaDefinition;
        this._loadPersonaPermissions();
    }

    label = label;

    // error handling
    showError = false;
    errorMessage;

    // spinner
    isRunning = true;
    objectInfoLoaded = false;

    // table
    personaPermissions = [];
    personaPermissionColumns = [];
    allPermissions = [];
    allPermissionColumns = [];

    // sorting
    defaultSortDirectionPersonaPermissions = 'asc';
    sortDirectionPersonaPermissions = 'asc';
    sortedByPersonaPermissions = 'label';
    defaultSortDirectionAllPermissions = 'asc';
    sortDirectionAllPermissions = 'asc';
    sortedByAllPermissions = 'MasterLabel';

    // searching
    searchTermPersonaPermissions = '';
    searchedPersonaPermissions = [];
    searchTermAllPermissions = '';
    searchedAllPermissions = [];

    connectedCallback() {
        this._createColumns();
        this.objectInfoLoaded = true;
        this._loadPersonaPermissions();
    }

    get personaId() {
        return this.personaDefinition.Id;
    }

    get personaName() {
        return this.personaDefinition.Name;
    }

    get isEmpty() {
        return this.personaPermissions.length === 0;
    }

    get showSpinner() {
        return this.isRunning || !this.objectInfoLoaded;
    }

    get saveDisabled() {
        return this.isRunning || this.selectedCount === 0;
    }

    get permissionsTitle() {
        return formatLabel(label.Copado_Permissions_for_Persona, [this.personaName]);
    }

    get selectedRecordsToAdd() {
        const selectedRecords = this.template.querySelector('lightning-datatable[data-id="allPermissionsTable"]')?.getSelectedRows();
        return selectedRecords ? selectedRecords : [];
    }

    get selectedCount() {
        return this.selectedRecordsToAdd ? this.selectedRecordsToAdd.length : 0;
    }

    get availableAllPermissions() {
        return this.searchTermAllPermissions ? this.searchedAllPermissions : this.allPermissions;
    }

    get availablePersonaPermissions() {
        return this.searchTermPersonaPermissions ? this.searchedPersonaPermissions : this.personaPermissions;
    }

    handleAddNewPermission(event) {
        event.preventDefault();
        this.template.querySelector('c-cds-modal').show();
        this._loadAllPermissions();
    }

    handleCancelModal() {
        this._closeModal();
    }

    handleRefreshAllPermissionsTable() {
        this._loadAllPermissions();
    }

    async handleSaveAddPermissions() {
        try {
            this.isRunning = true;
            let permissionSetGroups = [];
            this.selectedRecordsToAdd.forEach(element => {
                permissionSetGroups.push(element.DeveloperName);
            });
            await addPermissionSetGroup({ personaId: this.personaId, permissionSetGroups: permissionSetGroups });
            this._closeModal();
            this.refreshPersonaPermissionRows();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this.showError = true;
            this.errorMessage = errorMessage;
        } finally {
            this.isRunning = false;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'removeFromPersona':
                this.handleRemove(row.developerName, row.type, row.isStandard);
                break;
            default:
        }
    }

    handleRemove(permissionName, permissionType, isStandard) {
        const permissionConfirmationModal = this.template.querySelector('c-remove-permission-confirmation-modal');
        permissionConfirmationModal.setPersonaPermission(this.personaId, permissionName, permissionType, isStandard);
        permissionConfirmationModal.show();
    }

    refreshPersonaPermissionRows() {
        this._loadPersonaPermissions();
    }

    handleSortPersonaPermissions(event) {
        this.sortDirectionPersonaPermissions = event.detail.sortDirection;
        this.sortedByPersonaPermissions = event.detail.fieldName;
        this._sortPersonaPermissions();
    }

    handleSortAllPermissions(event) {
        this.sortDirectionAllPermissions = event.detail.sortDirection;
        this.sortedByAllPermissions = event.detail.fieldName;
        this._sortAllPermissions();
    }

    handleSearchPersonaPermissions(event) {
        try {
            const searchObj = event.detail;
            this.searchTermPersonaPermissions = searchObj.searchTerm;
            this.searchedPersonaPermissions = [...searchObj.searchedData];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleClearSearchPersonaPermissions() {
        try {
            this.searchTermPersonaPermissions = '';
            this.searchedPersonaPermissions = [];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleSearchAllPermissions(event) {
        try {
            const searchObj = event.detail;
            this.searchTermAllPermissions = searchObj.searchTerm;
            this.searchedAllPermissions = [...searchObj.searchedData];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleClearSearchAllPermissions() {
        try {
            this.searchTermAllPermissions = '';
            this.searchedAllPermissions = [];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    // PRIVATE

    _createColumns() {
        this.personaPermissionColumns = [
            {
                label: 'Permission Label',
                fieldName: 'label',
                sortable: true,
                searchable: true
            },
            {
                label: 'Description',
                fieldName: 'description',
                sortable: true,
                searchable: true
            },
            {
                label: label.Type,
                fieldName: 'type',
                sortable: true,
                searchable: true
            },
            {
                label: 'Package Namespace',
                fieldName: 'packageName',
                sortable: true,
                searchable: true
            },
            {
                label: 'Is Copado Standard',
                fieldName: 'isStandard',
                type: 'boolean',
                sortable: true,
                searchable: true
            },
            {
                type: 'action',
                typeAttributes: {
                    rowActions: [{ label: label.Remove_From_Persona, name: 'removeFromPersona', iconName: 'utility:ban', iconPosition: 'left' }]
                }
            }
        ];
        this.allPermissionColumns = [
            {
                label: 'Permission Label',
                fieldName: 'MasterLabel',
                sortable: true,
                searchable: true
            },
            {
                label: 'Description',
                fieldName: 'Description',
                sortable: true,
                searchable: true
            }
        ];
    }

    async _loadPersonaPermissions() {
        try {
            this.isRunning = true;
            this.personaPermissions = await getPermissionsForPersona({ personaId: this.personaId });
            this._sortPersonaPermissions();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.isRunning = false;
        }
    }

    async _loadAllPermissions() {
        try {
            this.isRunning = true;
            const allPermissions = await getPermissionSetGroups();
            const alreadyAssigned = this.personaPermissions.map(personaPermission => personaPermission.id);
            this.allPermissions = allPermissions.filter(permission => !alreadyAssigned.includes(permission.Id));
            this._sortAllPermissions();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.isRunning = false;
        }
    }

    _sortPersonaPermissions() {
        if (this.personaPermissionColumns.length > 0) {
            this.personaPermissions = getSortedData(this.personaPermissionColumns, this.personaPermissions, {
                name: this.sortedByPersonaPermissions,
                sortDirection: this.sortDirectionPersonaPermissions
            });
        }
    }

    _sortAllPermissions() {
        if (this.allPermissionColumns.length > 0) {
            this.allPermissions = getSortedData(this.allPermissionColumns, this.allPermissions, {
                name: this.sortedByAllPermissions,
                sortDirection: this.sortDirectionAllPermissions
            });
        }
    }

    _closeModal() {
        this.template.querySelector('c-cds-modal').hide();
        this.searchTermAllPermissions = '';
        this.searchedAllPermissions = [];
        this.showError = false;
        this.errorMessage = null;
    }
}