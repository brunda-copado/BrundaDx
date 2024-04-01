import { LightningElement, api } from 'lwc';

export default class PersonaContainer extends LightningElement {
    @api currentContent = 'developer';

    get releaseManagerSection() {
        return this.currentContent == 'releaseManager' ? true : false;
    }
    get developerSection() {
        return this.currentContent == 'developer' ? true : false;
    }
    get qualityEngineerSection() {
        return this.currentContent == 'qualityEngineer' ? true : false;
    }
    get customPersonaSection() {
        return this.currentContent == 'customPersona' ? true : false;
    }
}