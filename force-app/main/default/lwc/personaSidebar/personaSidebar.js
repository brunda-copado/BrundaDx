import { LightningElement, api } from 'lwc';
import { label } from './constants';

export default class PersonaSidebar extends LightningElement {
    @api personas = [];

    label = label;
    selectedPersonaId;

    get editDescriptionText() {
        return label.EDIT + ' ' + label.DESCRIPTION;
    }

    handleNavClick(event) {
        const selecteditem = this.template.querySelector('.active');
        if (selecteditem) {
            selecteditem.classList.remove('active');
        }
        const evt = event.currentTarget;
        evt.classList.add('active');
        let selected = event.currentTarget.dataset.targetId;
        this.selectedPersonaId = selected;
        const selectEvent = new CustomEvent('menuclick', {
            detail: selected
        });
        this.dispatchEvent(selectEvent);
    }

    handleAddPersona() {
        this.template.querySelector('c-add-custom-persona-modal').show();
    }

    handleMenuSelect(event) {
        this._handleMenuAction(event);
    }

    // PRIVATE

    _handleMenuAction(event) {
        const menuItem = event.detail.value;
        const index = this.personas.findIndex(record => record.persona.Id === this.selectedPersonaId);
        switch (menuItem) {
            case 'editPersona':
                this._handleEditPersona(this.personas[index].persona);
                break;
            case 'removePersona':
                this._handleRemovePersona(this.personas[index].persona);
                break;
            default:
        }
    }

    _handleEditPersona(persona) {
        const editCustomPersonaModal = this.template.querySelector('c-edit-custom-persona-modal');
        editCustomPersonaModal.setPersona(persona);
        editCustomPersonaModal.show();
    }

    _handleRemovePersona(persona) {
        const removeCustomPersonaModal = this.template.querySelector('c-remove-persona-confirmation-modal');
        removeCustomPersonaModal.setPersona(persona);
        removeCustomPersonaModal.show();
    }

    refreshPersonaDefinitions(event) {
        this.dispatchEvent(new CustomEvent('refreshpersona', { detail: event.detail }));
    }
}