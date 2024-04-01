import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import aura enabled apex methods
import createDXOperationPageURL from '@salesforce/apex/CredentialRedirectionHandler.createDXOperationPageURL';

// Import custom labels
import Opening_Dx_Operation from '@salesforce/label/c.Opening_Dx_Operation';

export default class CredentialOpenDxOperation extends LightningElement {
    @api recordId;

    label = {
        Opening_Dx_Operation
    };

    connectedCallback() {
        if (this.recordId) {
            this.createDoOauthURL();
        }
    }
    createDoOauthURL() {
        createDXOperationPageURL({ credentialId: this.recordId })
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