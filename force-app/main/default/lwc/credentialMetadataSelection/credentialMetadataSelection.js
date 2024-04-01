import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Import aura enabled apex methods
import getMetadataTypesForGivenCredentialId from '@salesforce/apex/CredentialRecordPageHandler.getMetadataTypesForGivenCredentialId';
import getMetadataTypesFieldHelpText from '@salesforce/apex/CredentialRecordPageHandler.getMetadataTypesFieldHelpText';

// Import Credential Fields
import METADATA_TYPES from '@salesforce/schema/Org__c.Metadata_Types__c';
import RECORD_ID from '@salesforce/schema/Org__c.Id';

export default class CredentialMetadataSelection extends LightningElement {
    @api recordId;
    @api objectApiName;

    selected = '';
    metadataTypesHelpText = '';
    _options = [];
    selectedOptions = [];

    // This variables are used to reset edited step information to the original value if modal is closed
    _credentialId;

    get options() {
        return this._options;
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

    @wire(getRecord, { recordId: '$_credentialId', fields: [METADATA_TYPES] })
    wiredCredential(value) {
        const { data, error } = value;
        if (data) {
            this.parseDataIntoVariables(data);
        } else if (error) {
            this.showToastMessage('UNEXPECTED ERROR ', error.body.message, 'error', 'dismissable');
        }
    }

    parseDataIntoVariables(data) {
        const metadataTypeValues = getFieldValue(data, METADATA_TYPES);
        this.selectedOptions = metadataTypeValues ? metadataTypeValues.split(',') : [];
    }

    handleChange(event) {
        this.selected = event.detail.value.join();
    }

    updateCredentialMetadataTypeField(recordInput) {
        updateRecord(recordInput)
            .then(() => {
                this.showToastMessage('Success', 'Metadata Type field has been updated', 'success', 'dismissable');
            })
            .catch(error => {
                this.showToastMessage('UNEXPECTED ERROR on Record Update', error.body.message, 'error', 'dismissable');
            });
    }

    updateMetadataTypeFieldValue() {
        const fields = {};
        fields[RECORD_ID.fieldApiName] = this.recordId;
        fields[METADATA_TYPES.fieldApiName] = this.selected;

        const recordInput = { fields };
        this.updateCredentialMetadataTypeField(recordInput);
    }

    populateHelpTextOfMetadataTypeField() {
        getMetadataTypesFieldHelpText({}).then(result => {
            if (result && result.length > 0) {
                this.metadataTypesHelpText = result;
            }
        });
    }

    retrieveMetadataTypesByDoingCalloutToBakcend() {
        getMetadataTypesForGivenCredentialId({ credentialId: this.recordId }).then(result => {
            if (result && result.length > 0) {
                let tempOptions = [];
                result.forEach(metadataItem => {
                    let newOption = {
                        label: metadataItem,
                        value: metadataItem
                    };
                    tempOptions.push(newOption);
                });

                this._options = tempOptions.length ? tempOptions : [];

                this.populateHelpTextOfMetadataTypeField();
            }
        });
    }

    connectedCallback() {
        if (this.recordId) {
            this._credentialId = this.recordId;
            this.retrieveMetadataTypesByDoingCalloutToBakcend();
        }
    }
}