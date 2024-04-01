import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors, formatLabel } from 'c/copadocoreUtils';
import { removePermission } from 'c/personaManagementService';

import { label } from './constants';

export default class RemovePermissionConfirmationModal extends LightningElement {
    personaId;
    permissionName;
    permissionType;
    isStandard;

    label = label;

    showSpinner = false;

    // PUBLIC

    @api show() {
        this.template.querySelector('c-cds-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-cds-modal').hide();
    }

    @api setPersonaPermission(personaId, permissionName, permissionType, isStandard) {
        this.personaId = personaId;
        this.permissionName = permissionName;
        this.permissionType = permissionType;
        this.isStandard = isStandard;
    }

    get deletionAllowed() {
        return !this.isStandard;
    }

    get removePermissionTitle() {
        return this.permissionType ? formatLabel(label.Remove_Permission_Set_Group, [this.permissionType]) : '';
    }

    get removePermissionMessage() {
        return this.permissionType ? formatLabel(label.Remove_Permission_Set_Group_Message, [this.permissionType.toLowerCase()]) : '';
    }

    // TEMPLATE

    handleClickCancel() {
        this.hide();
    }

    async handleClickRemove() {
        try {
            this.showSpinner = true;
            const permissions = [{ developerName: this.permissionName, type: this.permissionType }];
            await removePermission({ personaId: this.personaId, permissions: JSON.stringify(permissions) });
            this._resetInputs();
            showToastSuccess(this, { message: label.Remove_Permission_Set_Group_From_Persona_Success_Message });
            this.dispatchEvent(new CustomEvent('removedpermission'));
            this.hide();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    // PRIVATE

    _resetInputs() {
        this.personaId = null;
        this.permissionName = null;
        this.permissionType = null;
        this.isStandard = false;
    }
}