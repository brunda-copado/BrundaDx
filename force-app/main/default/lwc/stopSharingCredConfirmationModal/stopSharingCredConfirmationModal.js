import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { removeCredential } from 'c/personaManagementService';

import { label } from './constants';

export default class StopSharingCredConfirmationModal extends LightningElement {
    personaId;
    credentialId;

    label = label;

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

    handleClickCancel() {
        this.hide();
    }

    async handleClickStopSharing() {
        try {
            this.showSpinner = true;
            await removeCredential({ personaId: this.personaId, credentialIds: [this.credentialId] });
            this._resetInputs();
            showToastSuccess(this, { message: label.Remove_Credential_From_Persona_Success_Message });
            this.dispatchEvent(new CustomEvent('removedcredential'));
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
    }
}