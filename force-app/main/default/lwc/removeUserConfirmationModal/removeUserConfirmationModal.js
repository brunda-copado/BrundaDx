import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { removeUser } from 'c/personaManagementService';

import { label } from './constants';

export default class RemoveUserConfirmationModal extends LightningElement {
    personaId;
    userId;

    label = label;

    showSpinner = false;

    // PUBLIC

    @api show() {
        this.template.querySelector('c-cds-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-cds-modal').hide();
    }

    @api setPersonaUser(personaId, userId) {
        this.personaId = personaId;
        this.userId = userId;
    }

    // TEMPLATE

    handleClickCancel() {
        this.hide();
    }

    async handleClickRemove() {
        try {
            this.showSpinner = true;
            await removeUser({ personaId: this.personaId, userIds: [this.userId] });
            this._resetInputs();
            showToastSuccess(this, { message: label.Remove_User_From_Persona_Success_Message });
            this.dispatchEvent(new CustomEvent('removeduser'));
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
        this.userId = null;
    }
}