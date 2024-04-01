import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { schema, label } from './constants';
import { createAlert, formatLabel } from './utils';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import isADDEnabled from '@salesforce/apex/DataTemplateTabContainerCtrl.isADDEnabled';
import hasInactiveRelatedTemplate from '@salesforce/apex/DataTemplateTabContainerCtrl.hasInactiveRelatedTemplate';
import checkCredentialAccess from '@salesforce/apex/DataTemplateMainObjectTableCtrl.checkCredentialAccess';
import { validateCredential } from 'c/copadoCredentialValidator';
import { INACTIVE_RELATED_TEMPLATE_ERROR_ID } from 'c/datatemplateUtil';

export default class DataTemplateTabContainer extends LightningElement {
    schema = schema;
    label = label;
    isADDEnabled;
    @api recordId;

    sourceOrg;
    mainObject;

    showSpinner = true;

    communicationId = 'DataTemplateAlerts';

    @wire(MessageContext)
    messageContext;

    alertId = 'licensewarning';
    invalidCredentialAlertId = 'invalidCredential';

    pageAccessible = false;
    validCredential = false;

    refreshedInfo;
    @api get refreshDetail() {
        return this.refreshedInfo;
    }

    set refreshDetail(value) {
        this.refreshedInfo = value;
    }

    get displayRefreshModal() {
        return this.refreshedInfo && (this.refreshedInfo.add || this.refreshedInfo.remove);
    }

    @wire(getRecord, { recordId: '$recordId', fields: [schema.SOURCE_ORG_FIELD, schema.MAIN_OBJECT_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.sourceOrg = data.fields[schema.SOURCE_ORG_FIELD.fieldApiName].value;
            this.mainObject = data.fields[schema.MAIN_OBJECT_FIELD.fieldApiName].value;
            this.showSpinner = false;
            this._checkCredential();
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    get dataSourceDefined() {
        return this.sourceOrg && this.mainObject;
    }

    async connectedCallback() {
        try {
            this.isADDEnabled = await isADDEnabled();
            if (this.isADDEnabled === false) {
                this._publishOnMessageChannel(undefined, undefined, false, this.alertId, 'remove');
                this._publishOnMessageChannel(label.DD_LICENSE_RESTRICTION, 'info', false, this.alertId, 'add');
            }
            this._checkInactiveRelatedTemplates();
        } catch (error) {
            this._showToastErrorMessage(error)
        }
        this.pageAccessible = true;
    }

    async _checkCredential() {
        try {
            if (this.sourceOrg) {
                const credentialAccess = await checkCredentialAccess({ orgId: this.sourceOrg });
                if (!credentialAccess) {
                    this._publishOnMessageChannel(undefined, undefined, false, this.invalidCredentialAlertId, 'remove');
                    this._publishOnMessageChannel(label.NO_ACCESS_TO_CREDENTIAL, 'error', false, this.invalidCredentialAlertId, 'add');
                    this._dispatchCredentialEvent();
                    return;
                }
                const result = await validateCredential(this.sourceOrg);
                this.validCredential = result[0] && result[0].validationType === 'OK' ? true : false;
                if (!this.validCredential) {
                    const alertMessage = formatLabel(label.ORG_CRED_INVALID, '/' + this.sourceOrg);
                    this._publishOnMessageChannel(undefined, undefined, false, this.invalidCredentialAlertId, 'remove');
                    this._publishOnMessageChannel(alertMessage, 'error', false, this.invalidCredentialAlertId, 'add');
                }
                this._dispatchCredentialEvent();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleCloseRefreshModal(event) {
        this.refreshedInfo = {};
    }

    _publishOnMessageChannel(message, type, dismissable, alertId, operation) {
        const alertMessage = createAlert(message, type, dismissable, this.communicationId, alertId, operation);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);
    }

    _dispatchCredentialEvent() {
        this.dispatchEvent(new CustomEvent('credentialcheck', { detail: this.validCredential }));
    }

    _showToastErrorMessage(error) {
        const errorMessage = reduceErrors(error);
        showToastError(this, { message: errorMessage });        
    }

    _checkInactiveRelatedTemplates() {
        if(this.dataSourceDefined && this.isADDEnabled) {
            hasInactiveRelatedTemplate({ recordId: this.recordId })
            .then(result => {
                if(result === true) {
                    this._publishOnMessageChannel(undefined, undefined, false, INACTIVE_RELATED_TEMPLATE_ERROR_ID, 'remove');
                    this._publishOnMessageChannel(label.DATA_TEMPLATE_INACTIVE_ERROR, 'error', false, INACTIVE_RELATED_TEMPLATE_ERROR_ID, 'add');
                }
            }).catch(error => {
                this._showToastErrorMessage(error)
            })
        }
    }
    
}