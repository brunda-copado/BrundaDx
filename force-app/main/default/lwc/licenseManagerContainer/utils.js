import { namespace } from 'c/copadocoreUtils';

import fetchColumnsConfig from '@salesforce/apex/DynamicDatatableCtrl.fetchColumnsConfig';
import fetchData from '@salesforce/apex/LicenseManagerCtrl.fetchData';
import validateLicenses from '@salesforce/apex/LicenseManagerCtrl.validateLicenses';
import validateExtLicenses from '@salesforce/apex/LicenseManagerCtrl.validateExtLicenses';
import updatePackageLicenses from '@salesforce/apex/LicenseManagerCtrl.updatePackageLicenses';
import updateExtPackageLicenses from '@salesforce/apex/LicenseManagerCtrl.updateExtPackageLicenses';
import updateUsersWithLicenses from '@salesforce/apex/LicenseManagerCtrl.updateUsersWithLicenses';

import Copado_Managed_Package from '@salesforce/label/c.Copado_Managed_Package';
import Copado_Analytics from '@salesforce/label/c.Copado_Analytics';
import Copado_VSM from '@salesforce/label/c.Copado_VSM';
import Copado_Admin from '@salesforce/label/c.Copado_Admin';
import Copado_User from '@salesforce/label/c.Copado_User';
import Copado_Guest from '@salesforce/label/c.Copado_Guest';
import Compliance_Hub from '@salesforce/label/c.Compliance_Hub';
import Data_Deployer from '@salesforce/label/c.Data_Deployer';
import Selenium_Testing from '@salesforce/label/c.Selenium_Testing';

const actions = [
    { label: 'All', name: 'all', checked: true },
    { label: 'Assigned', name: 'assigned' },
    { label: 'Unassigned', name: 'unassigned' }
];

export const licenseFieldsByName = new Map([
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

export function processLicense(license) {
    license.value = (license.used / license.available) * 100;
    if (license.value >= 75) {
        license.class = 'red';
    } else if (license.value >= 50) {
        license.class = 'yellow';
    } else {
        license.class = '';
    }

    return license;
}

export function mapLicensesIntoColumns(columns, licensesInfo, editable , extlicenseInfo) {
    if (Object.keys(extlicenseInfo).length !== 0){
        for(let ext in extlicenseInfo){
            licenseFieldsByName.set(ext,extlicenseInfo[ext]);
        }
    }
    licensesInfo.forEach((license) => {
        if (licenseFieldsByName.has(license.name)) {
            columns.push({
                editable: editable,
                fieldName: licenseFieldsByName.get(license.name),
                hideDefaultActions: true,
                label: license.name,
                sortable: true,
                type: 'boolean',
                actions: JSON.parse(JSON.stringify(actions))
            });
        }
    });
    return columns;
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function getColumnsConfig(self, columnsConfiguration) {
    return fetchColumnsConfig(columnsConfiguration);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function getData(self, queryConfig) {
    return fetchData(queryConfig);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function checkLicensesAvailability(self, licenses, addToPackage, removeFromPackage) {
    return validateLicenses(licenses, addToPackage, removeFromPackage);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function checkLicensesExtAvailability(self, addToExtPackage, removeFromExtPackage) {
    return validateExtLicenses(addToExtPackage, removeFromExtPackage);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function updateLicensesForPackages(self, addToPackage, removeFromPackage) {
    return updatePackageLicenses(addToPackage, removeFromPackage);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function updateLicensesForExtPackages(self, addToExtPackage, removeFromExtPackage) {
    return updateExtPackageLicenses(addToExtPackage, removeFromExtPackage);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function updateUsersAndFeatureLicenses(self, users, licenses) {
    return updateUsersWithLicenses(users, licenses);
}