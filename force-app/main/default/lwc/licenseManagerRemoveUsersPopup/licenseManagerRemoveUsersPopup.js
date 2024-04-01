import { LightningElement, api } from 'lwc';

import { handleAsyncError } from 'c/copadocoreUtils';
import { showToastSuccess } from 'c/copadocoreToastNotification';

import removeAllPackageLicenses from '@salesforce/apex/LicenseManagerCtrl.removeAllPackageLicenses';
import removeAllExtPackageLicenses from '@salesforce/apex/LicenseManagerCtrl.removeAllExtPackageLicenses';
import removeAllLicenses from '@salesforce/apex/LicenseManagerCtrl.removeAllLicenses';

import Remove_Users_Licenses from '@salesforce/label/c.Remove_Users_Licenses';
import Cancel from '@salesforce/label/c.Cancel';
import Confirm from '@salesforce/label/c.Confirm';
import Remove_Users_Confirmation from '@salesforce/label/c.Remove_Users_Confirmation';
import Remove_None_Selected_Confirmation from '@salesforce/label/c.Remove_None_Selected_Confirmation';
import Select_Record_Message from '@salesforce/label/c.Select_Record_Message';
import Error_while_removing_package_licenses from '@salesforce/label/c.Error_while_removing_package_licenses';
import Error_while_removing_feature_licenses from '@salesforce/label/c.Error_while_removing_feature_licenses';
import Licenses_removed_successfully from '@salesforce/label/c.Licenses_removed_successfully';

/*eslint no-extend-native: ["error", { "exceptions": ["String"] }]*/
String.prototype.format = function() {
    var s = this,
        i = arguments.length;

    while (i--) {
        s = s.replace(new RegExp('\\{' + i + '\\}', 'gm'), arguments[i]);
    }
    return s;
};

export default class LicenseManagerRemoveUsersPopup extends LightningElement {
    @api userIds;

    label = {
        Remove_Users_Licenses,
        Cancel,
        Confirm,
        Remove_None_Selected_Confirmation,
        Select_Record_Message
    };

    get body() {
        return (this.userIds?.length === 0) ? Remove_None_Selected_Confirmation : Remove_Users_Confirmation.format(this.userIds?.length);
    }

    get isUserSelected() {
        return (this.userIds?.length === 0) ? false : true;
    }

    // PUBLIC

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    // TEMPLATE

    handleCancel() {
        this.hide();
    }

    async handleConfirm() {
        this.hide();

        const safeRemoveAllPackageLicenses = handleAsyncError(this.removeAllPackageLicenses, {
            title: Error_while_removing_package_licenses
        });

        const safeRemoveAllExtPackageLicenses = handleAsyncError(this.removeAllExtPackageLicenses, {
            title: Error_while_removing_package_licenses
        });

        const safeRemoveAllLicenses = handleAsyncError(this.removeAllLicenses, {
            title: Error_while_removing_feature_licenses
        });

        const licensesResults = await Promise.all([
            safeRemoveAllPackageLicenses(this, { userIds: this.userIds }),
            safeRemoveAllExtPackageLicenses(this, { userIds: this.userIds }),
            safeRemoveAllLicenses(this, { userIds: this.userIds })
        ]);

        // If it is null (because apex method returns void) or any other value,
        // it means that removeAllPackageLicenses and removeAllLicenses were successful
        if (licensesResults[0] !== undefined && licensesResults[1] !== undefined) {
            showToastSuccess(this, {
                title: Licenses_removed_successfully
            });
        }

        this.dispatchEvent(new CustomEvent('licensesremoved'));
    }

    // PRIVATE

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    removeAllPackageLicenses(self, userIds) {
        return removeAllPackageLicenses(userIds);
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    removeAllExtPackageLicenses(self, userIds) {
        return removeAllExtPackageLicenses(userIds);
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    removeAllLicenses(self, userIds) {
        return removeAllLicenses(userIds);
    }
}