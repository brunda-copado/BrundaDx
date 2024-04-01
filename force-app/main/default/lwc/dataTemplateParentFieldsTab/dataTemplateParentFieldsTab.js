import { LightningElement, api } from 'lwc';

export default class DataTemplateParentFieldsTab extends LightningElement {
    @api recordId;
    validCredential;
    refreshDetail;

    handleCredentialCheck(event) {
        this.validCredential = event.detail;
    }

    handleRefreshDetail(event) {
        this.refreshDetail = event.detail;
    }
}