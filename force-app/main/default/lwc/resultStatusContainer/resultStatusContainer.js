import { LightningElement, api } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

export default class ResultStatusContainer extends NavigationMixin(LightningElement) {
    @api recordId;
    @api context;

    // TODO in following versions will be deleted, right now removing the references
}