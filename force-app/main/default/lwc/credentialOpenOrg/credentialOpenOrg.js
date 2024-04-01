import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import aura enabled apex methods
import createOpenOrgURL from '@salesforce/apex/CredentialRedirectionHandler.createOpenOrgURL';

// Import custom labels
import Opening_Credential from '@salesforce/label/c.Opening_Credential';

export default class CredentialOpenOrg extends LightningElement {
    @api recordId;

    label = {
        Opening_Credential
    };

    connectedCallback() {
        if (this.recordId) {
            this.createDoOauthURL();
        }
    }
    createDoOauthURL() {
        createOpenOrgURL({ credentialId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    this.navigateToGivenURL(result);
                }
            })
            .catch(error => {
                this.showToastMessage('Application Error', error, 'error', 'dismissable');
            });
    }
    navigateToGivenURL(givenURL) {
        window.open(givenURL);
    }
    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}