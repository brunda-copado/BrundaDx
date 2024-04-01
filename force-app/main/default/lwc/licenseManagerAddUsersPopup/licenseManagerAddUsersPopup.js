import { LightningElement, api } from 'lwc';

import { namespace, handleAsyncError } from 'c/copadocoreUtils';

import search from '@salesforce/apex/LicenseManagerCtrl.search';

import Assign_New_Licenses from '@salesforce/label/c.Assign_New_Licenses';
import Search from '@salesforce/label/c.Search';
import Users_Search_Helptext from '@salesforce/label/c.Users_Search_Helptext';
import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';
import ASSIGN_LICENSES from '@salesforce/label/c.ASSIGN_LICENSES';
import Cancel from '@salesforce/label/c.Cancel';
import Save from '@salesforce/label/c.Save';

import Branch_Management from '@salesforce/label/c.Branch_Management';
import Copado_Managed_Package from '@salesforce/label/c.Copado_Managed_Package';
import Copado_Analytics from '@salesforce/label/c.Copado_Analytics';
import Copado_VSM from '@salesforce/label/c.Copado_VSM';
import Copado_Admin from '@salesforce/label/c.Copado_Admin';
import Copado_User from '@salesforce/label/c.Copado_User';
import Copado_Guest from '@salesforce/label/c.Copado_Guest';
import Compliance_Hub from '@salesforce/label/c.Compliance_Hub';
import Data_Deployer from '@salesforce/label/c.Data_Deployer';
import Selenium_Testing from '@salesforce/label/c.Selenium_Testing';

const licenseFieldsByName = new Map([
    [Copado_Managed_Package, 'copado'],
    [Copado_Analytics, 'copadometrics'],
    [Copado_VSM, 'copadovsm'],
    [Copado_Admin, namespace + 'Enable_Copado__c'],
    [Copado_User, namespace + 'Enable_CCM__c'],
    [Copado_Guest, namespace + 'Enable_CAD__c'],
    [Compliance_Hub, namespace + 'Enable_CCH__c'],
    [Data_Deployer, namespace + 'Enable_ADD__c'],
    [Selenium_Testing, namespace + 'Enable_CST__c']
]);

export default class LicenseManagerAddUsersPopup extends LightningElement {
    @api usersAlreadyInTable;

    label = {
        Assign_New_Licenses,
        Search,
        Users_Search_Helptext,
        ASSIGN_LICENSES,
        Cancel,
        Save
    };

    _selectedUsers = [];
    _selectedLicenses = [];

    _licenses;
    _extLicense;

    @api
    get extLicense(){
        return this._extLicense;
    }
    set extLicense(value){
        this._extLicense = value;
    }

    @api
    get licenses() {
        return this._licenses;
    }
    set licenses(value) {
        this._licenses = value
            .map((license) => ({
                label: `${license.name} (${license.used}/${license.available})`,
                name: this._extLicense.has(license.name)? this._extLicense.get(license.name): licenseFieldsByName.get(license.name),
                disabled: license.used === license.available
            }))
            .filter((license) => !license.label.startsWith(Branch_Management));
    }

    _showSpinner;

    @api
    get showSpinner() {
        return this._showSpinner;
    }
    set showSpinner(value) {
        this._showSpinner = value;
    }

    get saveDisabled() {
        return this._selectedUsers.length < 1 || this._selectedLicenses.length < 1;
    }

    // PUBLIC

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this._selectedUsers = [];
        this._selectedLicenses = [];
        this.template.querySelector('c-copadocore-modal').hide();
    }

    // TEMPLATE

    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._search, {
            title: Error_Searching_Records
        });

        event.detail.selectedIds = [...event.detail.selectedIds, ...this.usersAlreadyInTable];
        const result = await safeSearch(this, event.detail);

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }

    handleLookupSelectionChange(event) {
        this._selectedUsers = event.detail;
    }

    handleChange(event) {
        if (event.detail.checked) {
            this._selectedLicenses = [...this._selectedLicenses, event.target.name];
        } else {
            this._selectedLicenses = this._selectedLicenses.filter(el => el !== event.target.name);
        }
    }

    handleSave() {
        // This is never set to false in this component, but by the parent when it finishes handling the event
        this._showSpinner = true;

        const draftValues = this._selectedUsers.map((userId) => {
            const drafRecord = { Id: userId };
            this._selectedLicenses.forEach((license) => {
                drafRecord[license] = true;
            });
            return drafRecord;
        });

        const saveLicensesEvent = new CustomEvent('savelicenses', {
            detail: {
                draftValues
            }
        });
        this.dispatchEvent(saveLicensesEvent);
    }

    handleCancel() {
        this.hide();
    }

    // PRIVATE

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _search(self, searchTerm, selectedIds) {
        return search(searchTerm, selectedIds);
    }
}