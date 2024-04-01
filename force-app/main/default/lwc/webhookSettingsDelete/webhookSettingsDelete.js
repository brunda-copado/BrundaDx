import { LightningElement, api } from 'lwc';

import { labels } from './constants';
import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import deleteActionKey from '@salesforce/apex/WebhookSettingsCtrl.deleteActionKey';

export default class WebhookSettingsDelete extends LightningElement {
    actionKey;
    labels = labels;

    @api
    delete(actionKey) {
        this.actionKey = actionKey;
        this.template.querySelector('c-copadocore-modal').show();
    }


    closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }


    async deleteKey() {
        try {
            await deleteActionKey({ actionKeyId: this.actionKey.id });
            this.dispatchEvent(new CustomEvent('delete'));
            this.template.querySelector('c-copadocore-modal').hide();
        } catch (ex) {
            showToastError(this, { message: reduceErrors(ex) });
        }
    }
}