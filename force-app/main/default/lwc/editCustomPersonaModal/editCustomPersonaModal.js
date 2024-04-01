import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { namespace, reduceErrors } from 'c/copadocoreUtils';
import { editPersonaDescription } from 'c/personaManagementService';

import { label } from './constants';

export default class EditCustomPersonaModal extends LightningElement {
    persona;

    label = label;
    showSpinner = false;

    // Error handling
    showError = false;
    errorMessage;

    // INPUTS
    description;

    // PUBLIC

    @api show() {
        this.template.querySelector('c-cds-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-cds-modal').hide();
    }

    @api setPersona(persona) {
        this.persona = persona;
        this.description = this.persona[namespace + 'Description__c'];
    }

    // TEMPLATE

    handleCancelModal() {
        this._resetInputs();
        this.hide();
    }

    handleSaveModal() {
        this._editPersona();
    }

    handleChange(event) {
        switch (event.target.fieldName) {
            case 'description':
                this.description = event.target.value;
                break;
            default:
                break;
        }
    }

    get personaName() {
        return this.persona?.Name;
    }

    // PRIVATE

    async _editPersona() {
        try {
            this.showSpinner = true;
            await editPersonaDescription({ personaId: this.persona.Id, description: this.description });
            showToastSuccess(this, { message: label.EDIT_CUSTOM_PERSONA_SUCCESS_MESSAGE });
            this.dispatchEvent(new CustomEvent('refreshpersona'));
            this.handleCancelModal();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this.showError = true;
            this.errorMessage = errorMessage;
        } finally {
            this.showSpinner = false;
        }
    }

    _resetInputs() {
        this.description = null;
        this.showError = false;
        this.errorMessage = null;
    }
}