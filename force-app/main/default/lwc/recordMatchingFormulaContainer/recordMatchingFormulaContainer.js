import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { schema, label } from './constants';
import checkCredentialAccess from '@salesforce/apex/DataTemplateRecordMatchingFormulaCtrl.checkCredentialAccess';
import { validateCredential } from 'c/copadoCredentialValidator';
import {createAlert, formatLabel, RECORD_MATCHING_COMMUNICATION_ID, INVALIDCREDENTIAL_ALERT_ID } from 'c/datatemplateUtil';
import { publish, MessageContext} from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import isADDEnabled from '@salesforce/apex/DataTemplateTabContainerCtrl.isADDEnabled';
export default class RecordMatchingFormulaContainer extends LightningElement {
    
    @api recordId;

    @wire(MessageContext)
    messageContext;    

    label = label;

    showSpinner = true;
    isADDEnabled;
    schemaCredential;
    object;
    field1;
    operation = 'create';
    hasCredentialAccess = true;
    validCredential = false; 

    get credentialValid(){
        return this.validCredential && this.hasCredentialAccess;
    }

    get configure(){
        return !this.object && !this.field1;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [schema.SCHEMA_CREDENTIAL, schema.OBJECT, schema.FIELD1] })
    wiredRecord({ error, data }) {
        if (data) {
            this.schemaCredential = data.fields[schema.SCHEMA_CREDENTIAL.fieldApiName].value;
            this.mainObject = data.fields[schema.OBJECT.fieldApiName].value;
            this.field1 = data.fields[schema.FIELD1.fieldApiName].value;
            this._checkLicenseAndCredential();
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } 

    }

    handleDisplayModal(event){
        this.template.querySelector('c-record-matching-formula-modal').showRecordMatchingFormula();
    }

    handleEditFormula(event){
        if(this.credentialValid){
            this.operation = 'edit';
            this.template.querySelector('c-record-matching-formula-modal').showRecordMatchingFormula();
        }
    }

    async _checkCredential() {
        try {
            if (this.schemaCredential) {
               this.hasCredentialAccess = await checkCredentialAccess({ credential: this.schemaCredential });
                if (!this.hasCredentialAccess) {
                    this._publishOnMessageChannel(undefined, undefined, 'remove', INVALIDCREDENTIAL_ALERT_ID, false);
                    this._publishOnMessageChannel(label.RMF_NO_ACCESS_TO_CREDENTIAL, 'info', 'add', INVALIDCREDENTIAL_ALERT_ID, false);
                } else {
                    const result = await validateCredential(this.schemaCredential);
                    this.validCredential = result[0] && result[0].validationType === 'OK' ? true : false;
                    if (!this.validCredential) {
                        const alertMessage = formatLabel(label.ORG_CRED_INVALID, '/' + this.schemaCredential);
                        this._publishOnMessageChannel(undefined, undefined, 'remove', INVALIDCREDENTIAL_ALERT_ID, false);
                        this._publishOnMessageChannel(alertMessage, 'error', 'add', INVALIDCREDENTIAL_ALERT_ID, false);
                    }
                }
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }
    async _isADDEnabled() {
        try{
            this.isADDEnabled = await isADDEnabled();
            if (this.isADDEnabled === false) {
                this._publishOnMessageChannel(undefined, undefined, 'remove', 'licensewarning', false);
                this._publishOnMessageChannel(label.DD_LICENSE_RESTRICTION_RMFORMULA, 'info', 'add', 'licensewarning', false);
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }
    _publishOnMessageChannel(message, type, op, alertId, dismissible) {
        const alertMessage = createAlert(message, type, dismissible, RECORD_MATCHING_COMMUNICATION_ID, alertId, op);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);
    }  
    
    async _checkLicenseAndCredential() {
        await this._isADDEnabled();
        if(this.isADDEnabled) {
            await this._checkCredential();
        }
        this.showSpinner = false;
    }
}