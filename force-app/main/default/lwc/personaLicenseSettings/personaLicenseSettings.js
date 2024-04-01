import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors, formatLabel } from 'c/copadocoreUtils';
import { getSortedData } from 'c/datatableService';
import { getLicenses, getLicensesForPersona, addPackageLicense, addLicense, removePackageLicense, removeLicense } from 'c/personaManagementService';

import { label } from './constants';

export default class PersonaLicenseSettings extends LightningElement {
    _personaDefinition;

    @api
    get personaDefinition() {
        return this._personaDefinition;
    }

    set personaDefinition(personaDefinition) {
        this._personaDefinition = personaDefinition;
        this._loadPersonaLicenses();
    }
    @api numberOfUsers;

    label = label;

    // summary mode
    summaryMessages = [];
    isLicenseSummary = false;

    // error handling
    showError = false;
    errorMessage;

    // spinner
    isRunning = true;
    objectInfoLoaded = false;

    // table
    personaLicenses = [];
    personaLicenseColumns = [];
    allLicenses = [];

    // sorting
    defaultSortDirectionPersonaLicenses = 'asc';
    sortDirectionPersonaLicenses = 'asc';
    sortedByPersonaLicenses = 'label';

    // searching
    searchTermPersonaLicenses = '';
    searchedPersonaLicenses = [];

    get assignedUsersLabel() {
        return formatLabel(label.Number_of_Users_Assigned_to_this_Persona, [this.numberOfUsers]);
    }

    get personaId() {
        return this.personaDefinition.Id;
    }

    get personaName() {
        return this.personaDefinition.Name;
    }

    get isEmpty() {
        return this.personaLicenses.length === 0;
    }

    get showSpinner() {
        return this.isRunning || !this.objectInfoLoaded;
    }

    get saveDisabled() {
        return this.isRunning;
    }

    get licensesToAdd() {
        const alreadyAssigned = this.personaLicenses.map(personaLicense => personaLicense.name);
        const inputs = Array.from(this.template.querySelectorAll('lightning-input[data-id="options"]')).filter(element => !element.disabled);
        const checked = inputs.filter(element => element.checked).map(element => element.name);
        const selected = checked.filter(item => !alreadyAssigned.includes(item));
        return selected;
    }

    get availablePersonaLicenses() {
        return this.searchTermPersonaLicenses ? this.searchedPersonaLicenses : this.personaLicenses;
    }

    connectedCallback() {
        this._createColumns();
        this.objectInfoLoaded = true;
        this._loadPersonaLicenses();
    }

    handleEditLicense(event) {
        event.preventDefault();
        this.template.querySelector('c-cds-modal').show();
        this._loadAllLicenses();
    }

    handleCancelModal() {
        this._closeModal();
    }

    handleSaveModal() {
        const alreadyAssigned = this.personaLicenses.map(personaLicense => personaLicense.name);
        const inputs = Array.from(this.template.querySelectorAll('lightning-input[data-id="options"]')).filter(element => !element.disabled);
        const checked = inputs.filter(element => element.checked).map(element => element.name);
        const unchecked = inputs.filter(element => !element.checked).map(element => element.name);
        const licensesToAdd = checked.filter(item => !alreadyAssigned.includes(item));
        const licensesToRemove = unchecked.filter(item => alreadyAssigned.includes(item));
        this._handleSave(licensesToAdd, licensesToRemove);
    }

    handleCloseSummary() {
        this._closeModal();
        showToastSuccess(this, { message: label.License_Assignment_Success_Message });
        this.refreshPersonaLicenseRows();
    }

    refreshPersonaLicenseRows() {
        this._loadPersonaLicenses();
    }

    handleSortPersonaLicenses(event) {
        this.sortDirectionPersonaLicenses = event.detail.sortDirection;
        this.sortedByPersonaLicenses = event.detail.fieldName;
        this._sortPersonaLicenses();
    }

    handleSearchPersonaLicenses(event) {
        try {
            const searchObj = event.detail;
            this.searchTermPersonaLicenses = searchObj.searchTerm;
            this.searchedPersonaLicenses = [...searchObj.searchedData];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleClearSearchPersonaLicenses() {
        try {
            this.searchTermPersonaLicenses = '';
            this.searchedPersonaLicenses = [];
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    // PRIVATE

    _createColumns() {
        this.personaLicenseColumns = [
            {
                label: label.License_Name,
                fieldName: 'label',
                sortable: true,
                searchable: true
            },
            {
                label: label.Used,
                fieldName: 'used',
                sortable: true,
                searchable: true
            },
            {
                label: label.Available,
                fieldName: 'remaining',
                sortable: true,
                searchable: true
            }
        ];
    }

    async _loadPersonaLicenses() {
        try {
            this.isRunning = true;
            this.personaLicenses = await getLicensesForPersona({ personaId: this.personaId });
            this._sortPersonaLicenses();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.isRunning = false;
        }
    }

    _sortPersonaLicenses() {
        if (this.personaLicenseColumns.length > 0) {
            this.personaLicenses = getSortedData(this.personaLicenseColumns, this.personaLicenses, {
                name: this.sortedByPersonaLicenses,
                sortDirection: this.sortDirectionPersonaLicenses
            });
        }
    }

    async _loadAllLicenses() {
        try {
            this.isRunning = true;
            const allLicenses = await getLicenses();
            const alreadyAssigned = this.personaLicenses.map(personaLicense => personaLicense.name);
            const standardLicenses = this.personaLicenses
                .filter(personaLicense => personaLicense.isStandard)
                .map(personaLicense => personaLicense.name);
            this.allLicenses = allLicenses.map(license => {
                return {
                    ...license,
                    optionLabel: formatLabel(label.License_Option_Label, [license.label, license.remaining]),
                    selected: alreadyAssigned.includes(license.name),
                    disabled: standardLicenses.includes(license.name)
                };
            });
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.isRunning = false;
        }
    }

    _closeModal() {
        this.template.querySelector('c-cds-modal').hide();
        this.showError = false;
        this.errorMessage = null;
        this.isLicenseSummary = false;
    }

    async _handleSave(licensesToAdd, licensesToRemove) {
        try {
            this.isRunning = true;
            if (licensesToAdd.length > 0) {
                const packageLicensesToAdd = this._getPackageLicenses(licensesToAdd);
                const copadoLicensesToAdd = this._getCopadoLicenses(licensesToAdd);

                if (packageLicensesToAdd.length > 0) {
                    await addPackageLicense({ personaId: this.personaId, licenses: packageLicensesToAdd });
                }
                if (copadoLicensesToAdd.length > 0) {
                    await addLicense({ personaId: this.personaId, licenses: copadoLicensesToAdd });
                }
            }
            if (licensesToRemove.length > 0) {
                const packageLicensesToRemove = this._getPackageLicenses(licensesToRemove);
                const copadoLicensesToRemove = this._getCopadoLicenses(licensesToRemove);

                if (packageLicensesToRemove.length > 0) {
                    await removePackageLicense({ personaId: this.personaId, licenses: packageLicensesToRemove });
                }
                if (copadoLicensesToRemove.length > 0) {
                    await removeLicense({ personaId: this.personaId, licenses: copadoLicensesToRemove });
                }
            }
            this.summaryMessages = this._getSummary(licensesToAdd, licensesToRemove);
            this.isLicenseSummary = true;
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this.showError = true;
            this.errorMessage = errorMessage;
        } finally {
            this.isRunning = false;
        }
    }

    _getSummary(licensesToAdd, licensesToRemove) {
        let result = [];
        result.push(
            ...licensesToAdd.map(license => {
                const currentLicense = this.allLicenses.find(personaLicense => personaLicense.name === license);
                return formatLabel(label.License_Assignment_Summary, [
                    currentLicense.label,
                    this.numberOfUsers,
                    currentLicense.available - (currentLicense.used + this.numberOfUsers)
                ]);
            })
        );
        result.push(
            ...licensesToRemove.map(license => {
                const currentLicense = this.allLicenses.find(personaLicense => personaLicense.name === license);
                return formatLabel(label.License_Removal_Summary, [
                    currentLicense.label,
                    this.numberOfUsers,
                    currentLicense.available - (currentLicense.used - this.numberOfUsers)
                ]);
            })
        );
        return result;
    }

    _getPackageLicenses(licenses) {
        let result = [];
        licenses.forEach(license => {
            const currentLicense = this.allLicenses.find(personaLicense => personaLicense.name === license);
            if (currentLicense.isPackageLicense) {
                result.push(license);
            }
        });

        return result;
    }

    _getCopadoLicenses(licenses) {
        let result = [];
        licenses.forEach(license => {
            const currentLicense = this.allLicenses.find(personaLicense => personaLicense.name === license);
            if (!currentLicense.isPackageLicense) {
                result.push(license);
            }
        });

        return result;
    }
}