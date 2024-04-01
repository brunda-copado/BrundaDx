import { LightningElement, api } from 'lwc';

import validateOrgAndReturnResultWrapper from '@salesforce/apex/CredentialRecordPageHandler.validateOrgAndReturnResultWrapper';

export default class CredentialValidation extends LightningElement {
    @api recordId;

    resultWrapper = [];
    isLoading = true;

    connectedCallback() {
        if (this.recordId) {
            this.validateOrg();
        }
    }

    validateOrg() {
        validateOrgAndReturnResultWrapper({ credentialId: this.recordId }).then(result => {
            if (result && result.length > 0) {
                result.forEach((row, index) => {
                    row.keyNumber = index;
                });
                this.resultWrapper = result;
                this.isLoading = false;
            }
        });
    }
}