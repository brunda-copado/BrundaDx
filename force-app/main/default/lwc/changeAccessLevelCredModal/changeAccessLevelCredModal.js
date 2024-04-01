import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { changeCredentialAccessLevel } from 'c/personaManagementService';

import { label, accessLevelOptions } from './constants';

export default class ChangeAccessLevelCredModal extends LightningElement {
    label = label;
    accessLevelOptions = accessLevelOptions;

    personaId;
    credentialId;
    accessLevel = accessLevelOptions[0].value;

    showSpinner = false;

    // PUBLIC

    @api show() {
        this.template.querySelector('c-cds-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-cds-modal').hide();
    }

    @api setPersonaCredential(personaId, credentialId) {
        this.personaId = personaId;
        this.credentialId = credentialId;
    }

    // TEMPLATE

    handleChangeAccessLevel(event) {
        this.accessLevel = event.detail.value;
    }

    handleClickCancel() {
        this.hide();
    }

    async handleClickChangeAccessLevel() {
        try {
            this.showSpinner = true;
            await changeCredentialAccessLevel({ personaId: this.personaId, credentialId: this.credentialId, accessLevel: this.accessLevel });
            this._resetInputs();
            showToastSuccess(this, { message: label.Change_Access_Level_Success_Message });
            this.dispatchEvent(new CustomEvent('changeaccesslevel'));
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
        this.credentialId = null;
        this.accessLevel = accessLevelOptions[0].value;
    }
}