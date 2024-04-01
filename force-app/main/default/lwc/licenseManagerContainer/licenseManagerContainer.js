/* eslint-disable guard-for-in */
import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';

import { showToastWarning, showToastSuccess } from 'c/copadocoreToastNotification';
import { handleAsyncError } from 'c/copadocoreUtils';

import {
    licenseFieldsByName,
    processLicense,
    mapLicensesIntoColumns,
    getColumnsConfig,
    getData,
    checkLicensesAvailability,
    checkLicensesExtAvailability,
    updateLicensesForPackages,
    updateLicensesForExtPackages,
    updateUsersAndFeatureLicenses
} from './utils';

import canManageUsers from '@salesforce/userPermission/ManageUsers';

import licenseManagerResources from '@salesforce/resourceUrl/licenseManagerResources';

import fetchLicensesInfo from '@salesforce/apex/LicenseManagerCtrl.fetchLicensesInfo';
import fetchExtLicenseNames from '@salesforce/apex/LicenseManagerCtrl.fetchExtLicenseNames';
import deleteUnusedLicenses from '@salesforce/apex/LicenseManagerCtrl.deleteUnusedLicenses';

import Manage_Licenses_Warning from '@salesforce/label/c.Manage_Licenses_Warning';
import Users_With_Licenses from '@salesforce/label/c.Users_With_Licenses';
import Remove_Users_Licenses from '@salesforce/label/c.Remove_Users_Licenses';
import Add_User from '@salesforce/label/c.Add_User';
import Fetch_Licenses_Information_Error from '@salesforce/label/c.Fetch_Licenses_Information_Error';
import Fetch_Columns_Config_Error from '@salesforce/label/c.Fetch_Columns_Config_Error';
import Fetch_Data_Error from '@salesforce/label/c.Fetch_Data_Error';
import Error_Validating_Licenses from '@salesforce/label/c.Error_Validating_Licenses';
import Error_Updating_Package_Licenses from '@salesforce/label/c.Error_Updating_Package_Licenses';
import Error_Updating_Feature_Licenses from '@salesforce/label/c.Error_Updating_Feature_Licenses';
import Licenses_Updated_Successfully from '@salesforce/label/c.Licenses_Updated_Successfully';

const packageColumns = ['copado', 'copadometrics', 'copadovsm'];
const extLicensesColumns = [];

const relatedListHeaderHeight = 125;

export default class LicenseManagerContainer extends LightningElement {
    label = {
        Users_With_Licenses,
        Remove_Users_Licenses,
        Add_User
    };

    // If tableInfo is initialized to {} then child components will not listen for changes on it
    allLicenses;
    licenses;
    extLicense;
    tableInfo;
    usersAlreadyInTable;

    showSpinner;
    removeUsersDisabled = true;

    _sobject = 'User';
    _fieldset = 'License_Manager';
    _columns;
    _allRows;
    _searchTerm;
    _eventHeaderAction;

    canManageUsers = canManageUsers;

    _height = window.innerHeight;
    _nonFreeHeight;

    get height() {
        return `${this._height - this._nonFreeHeight}px`;
    }

    async connectedCallback() {
        // Retrieve table information in connectedCallback instead of wired methods
        // to be able to set properly the showSpinner value and because we also need
        // to retrieve data imperatively for "oninlineeditsave" event
        this.showSpinner = true;
        await this._setTableInformation();
        if (!canManageUsers) {
            showToastWarning(this, {
                message: Manage_Licenses_Warning,
                mode: 'sticky'
            });
        }
        this.showSpinner = false;
    }

    renderedCallback() {
        window.addEventListener('resize', () => {
            this._height = window.innerHeight;
        });

        const countersFinishAt = this.template.querySelector('lightning-layout[data-id*="counters"]')?.getBoundingClientRect()?.bottom || 0;
        this._nonFreeHeight = countersFinishAt + relatedListHeaderHeight;

        loadStyle(this, licenseManagerResources + '/licenseManager.css');
    }

    // TEMPLATE

    handleRowSelection(event) {
        this.removeUsersDisabled = event.detail.selectedRows.length === 0;
    }

    async handleHeaderAction(event) {
        this._eventHeaderAction = event;
        const draftValues = this.template.querySelector('c-related-list').tableComponent.draftValues;

        if (draftValues.length > 0) {
            const filterConfirmationPopup = this.template.querySelector('c-license-manager-filter-confirmation-popup');
            filterConfirmationPopup.show();
        } else {
            this._processHeaderAction();
        }
    }

    handleDiscardChanges() {
        this._processHeaderAction();
    }

    handleSearchApplied(event) {
        this.tableInfo.rows = event.detail.tableRows;
        this._applyFilteredAvailableLicenses();
    }

    handleRemoveUsers() {
        const userIds = this.template.querySelector('c-related-list').tableComponent.selectedRows;
        const removeUsersPopup = this.template.querySelector('c-license-manager-remove-users-popup');
        removeUsersPopup.userIds = userIds;
        removeUsersPopup.show();
    }

    handleAddUsers() {
        const addUsersPopup = this.template.querySelector('c-license-manager-add-users-popup');
        addUsersPopup.extLicense = this.extLicense;
        addUsersPopup.licenses = this.allLicenses;
        addUsersPopup.usersAlreadyInTable = this.usersAlreadyInTable;
        addUsersPopup.licenseFieldsByName
        addUsersPopup.show();
    }

    async handleSave(event) {
        this.showSpinner = true;
        const draftRows = event.detail.draftValues;

        const addUsersPopup = this.template.querySelector('c-license-manager-add-users-popup');

        const { users, jsonLicenses, addToPackage, removeFromPackage , addToExtPackage, removeFromExtPackage  } = this._splitRows(draftRows);

        const safeValidateLicenses = handleAsyncError(checkLicensesAvailability, {
            title: Error_Validating_Licenses
        });

        const safeValidateExtLicenses = handleAsyncError(checkLicensesExtAvailability, {
            title: Error_Validating_Licenses
        });

        const validateResult = await safeValidateLicenses(this, { jsonLicenses, addToPackage, removeFromPackage });
        const validateExtResult = await safeValidateExtLicenses(this, { addToExtPackage, removeFromExtPackage });

        // If it is null (because apex method returns void) or any other value,
        // it means that validateLicenses is successful
        if (validateResult !== undefined && validateExtResult !== undefined) {
            const safeUpdatePackageLicenses = handleAsyncError(updateLicensesForPackages, {
                title: Error_Updating_Package_Licenses
            });

            const safeUpdateExtPackageLicenses = handleAsyncError(updateLicensesForExtPackages, {
                title: Error_Updating_Package_Licenses
            });

            const safeUpdateUsersWithLicenses = handleAsyncError(updateUsersAndFeatureLicenses, {
                title: Error_Updating_Feature_Licenses
            });

            const licensesResults = await Promise.all([
                safeUpdatePackageLicenses(this, { addToPackage, removeFromPackage }),
                safeUpdateExtPackageLicenses(this,{addToExtPackage, removeFromExtPackage }),
                safeUpdateUsersWithLicenses(this, { users, jsonLicenses })
            ]);

            // If it is null (because apex method returns void) or any other value,
            // it means that updatePackageLicenses and updateUsersWithLicenses were successful
            if (licensesResults[0] !== undefined && licensesResults[1] !== undefined && licensesResults[2] !== undefined ) {
                addUsersPopup.hide();

                showToastSuccess(this, {
                    title: Licenses_Updated_Successfully
                });

                // Note: result is ignored, if it fails, it should not affect user experience
                await deleteUnusedLicenses();
            }

            await this._setTableInformation();
        }
        addUsersPopup.showSpinner = false;
        this.showSpinner = false;
    }

    async handleRefresh() {
        this.showSpinner = true;
        // Set it to undefined first, otherwise child components will not listen for changes on it
        this.tableInfo = undefined;
        await this._setTableInformation();
        this.showSpinner = false;
    }

    // PRIVATE

    async _setTableInformation() {
        const [licensesInfo, columns, rows] = await Promise.all([this._getLicensesInfo(), this._getColumnsConfig(), this._getRowsData()]);
        const extLicenseInfo = await this._getExtLicensesInfo();
        if (!(licensesInfo && columns && rows)) {
            return;
        }

        licensesInfo.forEach((license) => {
            processLicense(license);
        });
        this.allLicenses = licensesInfo;
        this.licenses = JSON.parse(JSON.stringify(this.allLicenses));

        this.extLicense = new Map();
        for(const lic in extLicenseInfo ){
            extLicensesColumns.push(extLicenseInfo[lic]);
            this.extLicense.set(lic,extLicenseInfo[lic]);
        }
        let isRefresh;
        let columnsCopy;
        if (this._columns) {
            isRefresh = true;
            columnsCopy = this._columns;
        } else {
            isRefresh = false;
            columnsCopy = this._columns = mapLicensesIntoColumns([...columns], licensesInfo, canManageUsers, extLicenseInfo);
        }

        const rowsCopy = [];
        const usersAlreadyInTable = [];
        for (const row of rows) {
            usersAlreadyInTable.push(row.user.Id);
            if (row.license) {
                row.license.LicenseId = row.license.Id;
                delete row.license.Id;
            }
            rowsCopy.push(Object.assign(row.user, row.packageLicenses, row.license, row.extLicenses));
        }
        this.usersAlreadyInTable = usersAlreadyInTable;

        this.tableInfo = Object.assign(this.tableInfo || {}, { columns: columnsCopy }, { rows: rowsCopy });
        this._allRows = this.tableInfo.rows;

        if (isRefresh) {
            this._applyFilters();
        }
    }

    async _getLicensesInfo() {
        const safeFetchLicensesInfo = handleAsyncError(fetchLicensesInfo, {
            title: Fetch_Licenses_Information_Error
        });

        const licensesInfo = await safeFetchLicensesInfo(this);
        return licensesInfo;
    }

    async _getExtLicensesInfo() {
        const safefetchExtLicenseNames = handleAsyncError(fetchExtLicenseNames, {
            title: Fetch_Licenses_Information_Error
        });

        const extLicensesInfo = await safefetchExtLicenseNames(this);
        return extLicensesInfo;
    }

    async _getColumnsConfig() {
        const safeFetchColumnsConfig = handleAsyncError(getColumnsConfig, {
            title: Fetch_Columns_Config_Error
        });

        const columnsConfiguration = {
            objectApiName: this._sobject,
            fieldSetName: this._fieldset,
            editable: false,
            hideDefaultColumnsActions: true,
            searchable: true,
            sortable: true
        };

        const columns = await safeFetchColumnsConfig(this, { columnsConfiguration });
        return columns;
    }

    async _getRowsData() {
        const safeFetchData = handleAsyncError(getData, {
            title: Fetch_Data_Error
        });

        const rows = await safeFetchData(this, { selectFieldSet: this._fieldset });
        return rows;
    }

    _splitRows(rows) {
        const users = [];
        const licenses = [];
        const addToPackage = {};
        const removeFromPackage = {};
        const addToExtPackage = {};
        const removeFromExtPackage = {};

        for (const row of rows) {
            const user = {};
            const license = {};
            let hasUser = false;
            let hasLicense = false;
            for (const field in row) {
                if (field !== 'Id') {
                    if (packageColumns.includes(field)) {
                        if (row[field]) {
                            // eslint-disable-next-line no-prototype-builtins
                            if (!addToPackage.hasOwnProperty(field)) {
                                addToPackage[field] = [];
                            }
                            const value = addToPackage[field];
                            value.push(row.Id);
                            addToPackage[field] = value;
                        } else {
                            // eslint-disable-next-line no-prototype-builtins
                            if (!removeFromPackage.hasOwnProperty(field)) {
                                removeFromPackage[field] = [];
                            }
                            const value = removeFromPackage[field];
                            value.push(row.Id);
                            removeFromPackage[field] = value;
                        }
                    } else if(extLicensesColumns.includes(field)){
                        if (row[field]) {
                            // eslint-disable-next-line no-prototype-builtins
                            if (!addToExtPackage.hasOwnProperty(field)) {
                                addToExtPackage[field] = [];
                            }
                            const value = addToExtPackage[field];
                            value.push(row.Id);
                            addToExtPackage[field] = value;
                        } else {
                            // eslint-disable-next-line no-prototype-builtins
                            if (!removeFromExtPackage.hasOwnProperty(field)) {
                                removeFromExtPackage[field] = [];
                            }
                            const value = removeFromExtPackage[field];
                            value.push(row.Id);
                            removeFromExtPackage[field] = value;
                        }

                    } else if (Array.from(licenseFieldsByName.values()).includes(field)) {
                        hasLicense = true;
                        license[field] = row[field];
                    } else {
                        hasUser = true;
                        user[field] = row[field];
                    }
                }
            }
            if (hasUser) {
                user.Id = row.Id;
                users.push(user);
            }
            if (hasLicense) {
                const licenseId = this._allRows.find((el) => el.Id === row.Id)?.LicenseId;
                if (licenseId) {
                    license.Id = licenseId;
                } else {
                    license.SetupOwnerId = row.Id;
                }
                licenses.push(license);
            }
        }

        const jsonLicenses = JSON.stringify(licenses);
        return { users, jsonLicenses, addToPackage, removeFromPackage, addToExtPackage, removeFromExtPackage };
    }

    _processHeaderAction() {
        const actionName = this._eventHeaderAction.detail.action.name;
        const colDef = this._eventHeaderAction.detail.columnDefinition;
        const field = colDef.fieldName;

        const idx = this.tableInfo.columns.findIndex((element) => element.fieldName === field);
        const column = this.tableInfo.columns[idx];
        column.actions.forEach((action) => {
            action.checked = action.name === actionName;
        });

        switch (actionName) {
            case 'all': {
                delete column.iconName;
                delete column.filterAssigned;
                delete column.filterUnassigned;
                break;
            }
            case 'assigned':
                column.filterAssigned = true;
                delete column.filterUnassigned;
                break;
            case 'unassigned':
                delete column.filterAssigned;
                column.filterUnassigned = true;
                break;
            default:
        }

        this._applyFilters();
    }

    _applyFilters() {
        const assignedColumns = this.tableInfo.columns.filter((column) => column.filterAssigned);
        const unassignedColumns = this.tableInfo.columns.filter((column) => column.filterUnassigned);
        assignedColumns.forEach((column) => {
            column.iconName = 'utility:filterList';
        });
        unassignedColumns.forEach((column) => {
            column.iconName = 'utility:filterList';
        });
        this.tableInfo.rows = JSON.parse(JSON.stringify(this._allRows));

        assignedColumns.map((column) => column.fieldName).forEach((field) => this._filterRowsByFieldValue(field, true));
        unassignedColumns.map((column) => column.fieldName).forEach((field) => this._filterRowsByFieldValue(field, false));

        this._columns = this.tableInfo.columns;
        const tableInfoCopy = Object.assign({}, this.tableInfo);
        this.tableInfo = undefined;
        this.tableInfo = tableInfoCopy;
    }

    _filterRowsByFieldValue(field, value) {
        this.tableInfo.rows = this.tableInfo.rows.filter((row) => row[field] === value);
    }

    _applyFilteredAvailableLicenses() {
        const availableLicensesByField = new Map();
        this.tableInfo.rows.forEach((row) => {
            for (const field in row) {
                if (Array.from(licenseFieldsByName.values()).includes(field)) {
                    const existingCount = availableLicensesByField.get(field) || 0;
                    availableLicensesByField.set(field, existingCount + row[field]);
                }
            }
        });

        this.licenses.forEach((license) => {
            if (licenseFieldsByName.has(license.name)) {
                license.used = availableLicensesByField.get(licenseFieldsByName.get(license.name)) || 0;
                license = processLicense(license);
            }
        });

        // Strangely this was not needed when tableInfo was being updated in the same transaction
        this.licenses = [...this.licenses];
    }
}