import { LightningElement, api } from 'lwc';

export default class DataTemplateDeploymentOptionsTab extends LightningElement {
    @api recordId;
    validCredential;

    handleCredentialCheck(event) {
        this.validCredential = event.detail;
    }
}