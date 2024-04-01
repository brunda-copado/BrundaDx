import { LightningElement, api } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import { updateRecord, createRecord } from 'lightning/uiRecordApi';

import { labels, schema, layout } from './constants';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';

import getDefaultNotification from '@salesforce/apex/NotificationsCenterCtrl.getDefaultNotification';

export default class NotificationSubscription extends LightningElement {
    @api tab;
    @api allChannels;
    @api defaultNotification;

    subscription;
    labels = labels;
    showSpinner = false;
    layout;


    async connectedCallback() {
        if (this.tab === 'User') {
            this.userId = currentUserId;
            this.layout = layout.userSubscriptionLayout;
        } else if (this.tab === 'System') {
            this.userId = null;
            this.layout = layout.systemSubscriptionLayout;
        }
    }


    @api
    edit(subscription) {
        this.subscription = subscription;
        this.layout = this.layout.map((field) => {
            let value = subscription[field.fieldName];
            if (field.fieldName === 'channels') {
                field.options = this.allChannels;
                if (!value || value === 'User Default') {
                    value = this.defaultNotification.channels || [];
                    subscription[field.fieldName] = value;
                }
            }
            return { ...field, value: value, checked: value };
        });
        this.template.querySelector('c-copadocore-modal').show();
    }


    closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }


    async save() {
        try {
            this.showSpinner = true;
            const fields = {};
            let hasChanged = false;

            const inputs = [...this.template.querySelectorAll('[data-input=subscription]')];
            inputs.forEach((field) => {
                if (field.dataset.apiName) {
                    let newValue = this._getFieldValue(field);
                    fields[field.dataset.apiName] = newValue;
                    if (newValue !== this.subscription[field.dataset.fieldName]) {
                        hasChanged = true;
                    }
                }
            });
            if (hasChanged) {
                fields[schema.NOTIFICATION_NAME_FIELD.fieldApiName] = this.subscription.developerName;
                if (this.subscription.id) {
                    await this._updateSubscription(fields);
                } else {
                    await this._createSubscription(fields);
                }
                this.dispatchEvent(new CustomEvent('change'));
                showToastSuccess(this, { message: labels.SUCCESS_MESSAGE });
            }
        } catch (ex) {
            showToastError(this, { message: ex.message || ex.body?.message });
        } finally {
            this.template.querySelector('c-copadocore-modal').hide();
            this.showSpinner = false;
        }
    }


    _getFieldValue(field) {
        let result;
        if (field.tagName.toLowerCase() === 'lightning-input') {
            result = field.value || field.checked;
        }
        if (field.tagName.toLowerCase() === 'lightning-checkbox-group') {
            result = field.value.join(';');
        }

        return result;
    }


    async _createSubscription(fields) {
        if (!this.defaultNotification.id) {
            await this._createDefault();
        }
        fields[schema.USER_DEFAULT_NOTIFICATION_FIELD.fieldApiName] = this.defaultNotification.id;
        const recordInput = { apiName: schema.SUBSCRIBED_FIELD.objectApiName, fields };
        await createRecord(recordInput);
    }


    async _updateSubscription(fields) {
        fields[schema.ID_FIELD.fieldApiName] = this.subscription.id;
        await updateRecord({ fields });
    }


    async _createDefault() {
        const fields = {};
        const systemNotification = await getDefaultNotification({ userId: null });
        fields[schema.RECEIVER_FIELD.fieldApiName] = this.userId;
        fields[schema.DEFAULT_CHANNELS_FIELD.fieldApiName] = systemNotification?.channels?.join(';');
        const defaultNotification = await createRecord({ apiName: schema.DEFAULT_CHANNELS_FIELD.objectApiName, fields });
        this.defaultNotification = { ...this.defaultNotification, id: defaultNotification.id };
    }
}