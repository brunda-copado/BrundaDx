import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { deletePersona } from 'c/personaManagementService';

import { label } from './constants';

export default class RemovePersonaConfirmationModal extends LightningElement {
    persona;

    label = label;
    showSpinner = false;

     // Error handling
     showError = false;
     errorMessage;

    // PUBLIC

    @api show() {
        this.template.querySelector('c-cds-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-cds-modal').hide();
    }

    @api setPersona(persona) {
        this.persona = persona;
    }

    // TEMPLATE

    handleCancel() {
        this._resetInputs();
        this.hide();
    }

    handleDeletePersona() {
        this._deletePersona();
    }

    // PRIVATE

    async _deletePersona() {
        try {
            this.showSpinner = true;
            await deletePersona({ personaId: this.persona.Id });
            showToastSuccess(this, { message: label.DELETE_CUSTOM_PERSONA_SUCCESS_MESSAGE });
            this.dispatchEvent(new CustomEvent('refreshpersona'));
            this.hide();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this.showError = true;
            this.errorMessage = errorMessage;
        } finally {
            this.showSpinner = false;
        }
    }

    _resetInputs() {
        this.showError = false;
        this.errorMessage = null;
    }
}