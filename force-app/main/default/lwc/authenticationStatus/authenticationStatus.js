import { LightningElement, api, track, wire } from 'lwc';
import validateGitConnection from '@salesforce/apex/GitRepositoryController.validateGitConnection';
import { CurrentPageReference } from 'lightning/navigation';
import { subscribe, MessageContext, publish } from 'lightning/messageService';
import gitRepoCommunicationChannel from '@salesforce/messageChannel/GitRepoCommunication__c';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

const CONSTANT = {
    URI_CANNOT_BE_EMPTY: 'URI cannot be empty.'
}
export default class AuthenticationStatus extends LightningElement {

    _communicationId = 'gitRepoAuthenticationAlerts';
    _alertId = 'gitRepoAuthenticationAlertMessage';

    @track loaded = false;
    @track isFirstAuthentication = false;
    @track isAuthenticationSuccess = false;
    @track isAuthenticationFailed = false;

    @api gitAuthenticationStatusTitle = "Authentication Status";
    @api notAuthenticationMessege = "Repository not authenticated";
    @api successAuthenticationMessege = "Repository successfully authenticated";
    @api failedAuthenticationMessege = "Authentication failed";
    @api recordId;
    subscription = null;


    @wire(MessageContext)
    messageContext;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }
    
    connectedCallback()
    {
        this.subscribeToMessageChannel();
        console.log('callign' + this.recordId);
        this.authenticate();
    }

    authenticate() { 
        this.loaded = false;
        this._clearAlert();
        validateGitConnection({repositoryId: this.recordId})
            .then(val => {
            var result = JSON.parse(val);
            this.loaded = true;
            console.log('Data:' + JSON.stringify(val));
            if (!result.success && result.message === CONSTANT.URI_CANNOT_BE_EMPTY) {
                this.isFirstAuthentication = true;
                //this._showAlert(result.message );
            } else if (!result.success) { 
                this.isAuthenticationFailed = true;
                this.isAuthenticationSuccess = false;
                this.isFirstAuthentication = false;
                this._showAlert(result.message );
            }
            else { 
                this.isAuthenticationSuccess = true;
                this.isFirstAuthentication = false;
                this.isAuthenticationFailed = false;
                this._clearAlert();
            }
        }) .catch(error => {
            this.loaded = true;
            this.error = error;
            this._showAlert(error.body.message );
        }); 
    }
    subscribeToMessageChannel() { 
        this.subscription = subscribe(this.messageContext, gitRepoCommunicationChannel, (response) => {
            console.log('received response in channel' + response.isAuthenticated);
            this.isFirstAuthentication = false;
            this.isAuthenticationSuccess = false;
            this.isAuthenticationFailed = false;
            this.authenticate();
            //this.isAuthenticationSuccess = response.isAuthenticated;
            //this.isFirstAuthentication = false;
        })
    }
    doRefresh(){
        this.isAuthenticationSuccess = false;
        this.isAuthenticationFailed = false;
        this.isFirstAuthentication = false;
        this.authenticate();
    }
    
    _showAlert(error) {
        const alert = {
            operation: 'add',
            message: error,
            dismissible: true,
            variant: 'error',
            communicationId: this._communicationId,
            id: this._alertId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alert);
    }

    _clearAlert() {
        const alert = {
            operation: 'remove',
            communicationId: this._communicationId,
            id: this._alertId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alert);
    }
}