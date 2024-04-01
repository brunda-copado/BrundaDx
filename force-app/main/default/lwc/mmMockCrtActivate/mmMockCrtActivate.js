import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';

import Id from '@salesforce/schema/ExtensionConfiguration__c.Id';
import Active from '@salesforce/schema/ExtensionConfiguration__c.Active__c';


import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

export default class MmMockCrtActivate extends NavigationMixin(LightningElement) {

    recordId;

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        if (pageReference && pageReference.state) {
            this.recordId = pageReference.attributes.recordId;
        }
    }

    async handleMockActivation() {

        try {
            console.log(this.recordId);

            const fields = {};

            fields[Id.fieldApiName] = this.recordId;
            fields[Active.fieldApiName] = true;

            await updateRecord({ fields });

        } catch (error) {
            console.log(error);
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
            
        this.closeModal();
    }

    closeModal() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.recordId,
                actionName: "view"
            }
        });
    }
}