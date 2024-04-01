import { LightningElement, api } from 'lwc';

import Editing_Items from '@salesforce/label/c.Editing_Items';
import Filter_Confirmation from '@salesforce/label/c.Filter_Confirmation';
import Stay_On_This_List from '@salesforce/label/c.Stay_On_This_List';
import Discard_Changes from '@salesforce/label/c.Discard_Changes';

export default class LicenseManagerFilterConfirmationPopup extends LightningElement {
    label = {
        Editing_Items,
        Filter_Confirmation,
        Stay_On_This_List,
        Discard_Changes
    };

    // PUBLIC

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    // TEMPLATE

    handleStay() {
        this.hide();
    }

    handleDiscardChanges() {
        this.hide();

        this.dispatchEvent(new CustomEvent('discardchanges'));
    }
}