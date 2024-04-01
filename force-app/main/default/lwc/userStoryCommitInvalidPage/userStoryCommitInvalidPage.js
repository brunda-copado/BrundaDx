import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { MessageContext, publish } from 'lightning/messageService';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import { label } from './constants';

export default class UserStoryCommitInvalidPage extends NavigationMixin(LightningElement) {
    label = label;

    @api recordId;
    @api validationErrors;

    communicationId = 'userStoryCommitValidations';
    alertsPublished = false;

    @wire(MessageContext)
    _context;

    get validEntryPoint() {
        return !!this.recordId;
    }

    get validCommitRequirements() {
        return this.validationErrors && this.validationErrors.length === 0;
    }

    // TEMPLATE

    renderedCallback() {
        if (this.validationErrors && !this.alertsPublished) {
            this.validationErrors.forEach((copadoAlert) => {
                const commitAlert = { ...copadoAlert, communicationId: this.communicationId };
                publish(this._context, COPADO_ALERT_CHANNEL, commitAlert);
            });
            this.alertsPublished = true;
        }
    }

    handleClickBack() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}