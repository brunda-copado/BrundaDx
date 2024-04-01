import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import aura enabled apex methods
import createDoOauthAndReturnApiURL from '@salesforce/apex/CredentialRedirectionHandler.createDoOauthAndReturnApiURL';

// Import custom labels
import Do_Oauth_Message from '@salesforce/label/c.Do_Oauth_Message';

export default class CredentialDoOauth extends LightningElement {
    @api recordId;

    label = {
        Do_Oauth_Message
    };

    connectedCallback() {
        if (this.recordId) {
            this.createDoOauthURL();
        }
    }
    createDoOauthURL() {
        createDoOauthAndReturnApiURL({ credentialId: this.recordId })
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
        window.open(givenURL, '_self');
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