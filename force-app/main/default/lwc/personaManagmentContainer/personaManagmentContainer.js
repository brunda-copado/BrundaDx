import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import HIDE_LIGHTNING_HEADER from '@salesforce/resourceUrl/HideLightningHeader';

import {
    checkUserPermissions,
    getPersonaDefinitions,
    createDefaultPersonas,
    checkDefaultPersonaUpdates,
    applyDefaultPersonaUpdates
} from 'c/personaManagementService';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { label } from './constants';

export default class PersonaManagmentContainer extends LightningElement {
    @track selectedPersona;
    numberOfUsers;
    @track personaDefinitions = [];
    @track defaultPersonasToUpdate = [];

    showSpinner;
    styleLoaded = false;

    label = label;

    userHasPermission = false;

    get isActivation() {
        return !this.personaDefinitions || !this.personaDefinitions.length;
    }

    get isUpdate() {
        return this.defaultPersonasToUpdate.length > 0;
    }

    async connectedCallback() {
        try {
            this.showSpinner = true;
            await this._checkPermissions();
            await this._loadPersonaDefinitions(true, false);
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    renderedCallback() {
        if (!this.styleLoaded) {
            loadStyle(this, HIDE_LIGHTNING_HEADER);
            this.styleLoaded = true;
        }
    }

    handleNavClick(event) {
        let selected = event.detail;
        this._selectPersona(this.personaDefinitions.find(personaDefinition => personaDefinition.persona.Id === selected));
    }

    async handleStartNow() {
        try {
            this.showSpinner = true;
            const defaultPersonas = [];
            await this._createDefaultPersonas(defaultPersonas);
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async handleUpdate() {
        try {
            this.showSpinner = true;
            await this._applyDefaultPersonaUpdates();
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    // PRIVATE

    async _checkPermissions() {
        this.userHasPermission = await checkUserPermissions();
    }

    async _createDefaultPersonas(defaultPersonas) {
        await createDefaultPersonas(defaultPersonas);
        await this._loadPersonaDefinitions(false, false);
    }

    async _applyDefaultPersonaUpdates() {
        await applyDefaultPersonaUpdates(this.defaultPersonasToUpdate);
        this.defaultPersonasToUpdate = [];
        await this._loadPersonaDefinitions(false, false);
    }

    async _checkForUpdates() {
        this.defaultPersonasToUpdate = await checkDefaultPersonaUpdates();
    }

    async _loadPersonaDefinitions(checkForUpdates, customPersonaAdded) {
        this.personaDefinitions = await getPersonaDefinitions();
        if (this.personaDefinitions.length > 0) {
            this.personaDefinitions.sort(this._compareByOrder);
            let currentSelectedPersona =
                this.selectedPersona && this.personaDefinitions.some(record => record.persona.Id === this.selectedPersona.Id)
                    ? this.personaDefinitions.find(record => record.persona.Id === this.selectedPersona.Id)
                    : this.personaDefinitions[0];
            currentSelectedPersona = customPersonaAdded ? this.personaDefinitions[this.personaDefinitions.length - 1] : currentSelectedPersona;
            this._selectPersona(currentSelectedPersona);
            if (checkForUpdates) {
                await this._checkForUpdates();
            }
        }
    }

    _selectPersona(personaDefinition) {
        this.selectedPersona = personaDefinition.persona;
        this.numberOfUsers = personaDefinition.numberOfUsers;
        personaDefinition.elementClass = 'active';
    }

    refreshPersonaDefinitions(event) {
        let customPersonaAdded = false;
        if (event.detail === 'addCustomPersona') {
            customPersonaAdded = true;
        }
        this._loadPersonaDefinitions(false, customPersonaAdded);
    }

    _compareByOrder(a, b) {
        let result = 0;
        if (a.order && b.order) {
            result = a.order - b.order;
        }
        return result;
    }
}