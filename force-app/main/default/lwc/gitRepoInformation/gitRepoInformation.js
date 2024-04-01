import { LightningElement, api } from 'lwc';
import NAME_FIELD from '@salesforce/schema/Git_Repository__c.Name';
import TUNNEL_FIELD from '@salesforce/schema/Git_Repository__c.Is_repository_connected_via_copa_tunnel__c';
import GIT_REPOSITORY from '@salesforce/schema/Git_Repository__c';


export default class GitRepoInformation extends LightningElement {
    @api
    fieldList = [NAME_FIELD, TUNNEL_FIELD];
    nameField = NAME_FIELD;
    tunnelField = TUNNEL_FIELD;
    objectApiName = GIT_REPOSITORY;
    showEditField;

    @api
    recordId;

    handleSuccess(event) {
        this.showEditField = false;
    }
    handleEdit() {
        this.showEditField = !this.showEditField;
    }
    handleCancel() {
        // Cancel editing
        this.showEditField = false;
    }
}