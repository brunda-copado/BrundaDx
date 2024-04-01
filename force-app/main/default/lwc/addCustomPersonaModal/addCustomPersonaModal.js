import { LightningElement, api } from 'lwc';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { createPersona } from 'c/personaManagementService';

import { label, constants } from './constants';

export default class AddCustomPersonaModal extends LightningElement {
    @api personas;

    label = label;
    constants = constants;
    showSpinner = false;

    // Error handling
    showError = false;
    errorMessage;

    // Inputs
    name = constants.EMPTY_STRING;
    description = constants.EMPTY_STRING;
    copyFrom = constants.CREATE_EMPTY_PERSONA_VALUE;

    // PUBLIC

    @api show() {
        this.template.querySelector('c-cds-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-cds-modal').hide();
    }

    // TEMPLATE

    handleCancelModal() {
        this._resetInputs();
        this.hide();
    }

    handleSaveModal() {
        if (this._validInputs()) {
            this._addPersona();
        }
    }

    get saveDisabled() {
        return this.name === constants.EMPTY_STRING;
    }

    get configurationOptions() {
        let options = [];
        options.push({ label: label.NONE_CREATE_EMPTY_CUSTOM_PERSONA, value: constants.CREATE_EMPTY_PERSONA_VALUE });
        if (this.personas) {
            this.personas.forEach(element => {
                options.push({ label: element.persona.Name, value: element.persona.Name });
            });
        }
        return options;
    }

    handleChange(event) {
        switch (event.target.name) {
            case constants.INPUT_FIELD_NAME:
                this.name = event.target.value;
                break;
            case constants.INPUT_FIELD_DESCRIPTION:
                this.description = event.target.value;
                break;
            default:
                this.copyFrom = event.target.value;
                break;
        }
    }

    // PRIVATE

    async _addPersona() {
        try {
            this.showSpinner = true;
            await createPersona({ name: this.name, description: this.description, copyFrom: this._getCopyFrom() });
            showToastSuccess(this, { message: label.ADD_CUSTOM_PERSONA_SUCCESS_MESSAGE });
            this.dispatchEvent(new CustomEvent('refreshpersona', { detail: 'addCustomPersona' }));
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
        this.name = constants.EMPTY_STRING;
        this.description = constants.EMPTY_STRING;
        this.copyFrom = constants.CREATE_EMPTY_PERSONA_VALUE;
        this.showError = false;
        this.errorMessage = null;
    }

    _validInputs() {
        return !(this.name === constants.EMPTY_STRING);
    }

    _getCopyFrom() {
        return this.copyFrom === constants.CREATE_EMPTY_PERSONA_VALUE ? constants.EMPTY_STRING : this.copyFrom;
    }
}