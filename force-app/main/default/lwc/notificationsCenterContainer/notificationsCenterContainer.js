import { LightningElement, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import CHANNELS_FIELD from '@salesforce/schema/Notification_Default_Channels__c.Channels__c';

import isCopadoAdmin from '@salesforce/apex/NotificationsCenterCtrl.isCopadoAdmin';
import isCopadoUser from '@salesforce/apex/NotificationsCenterCtrl.isCopadoUser';

import SYSTEM_NOTIFICATIONS from '@salesforce/label/c.SystemNotifications';
import MY_NOTIFICATIONS from '@salesforce/label/c.MyNotifications';
import LOADING from '@salesforce/label/c.LOADING';
import EMAIL from '@salesforce/label/c.Email';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

export default class NotificationsCenterContainer extends LightningElement {
    tabs = [];
    allChannels;
    showSpinner = true;

    _recordTypeId;

    label = { LOADING, EMAIL };

    @wire(getObjectInfo, { objectApiName: CHANNELS_FIELD.objectApiName })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this._recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    @wire(getPicklistValues, {
        recordTypeId: '$_recordTypeId',
        fieldApiName: CHANNELS_FIELD
    })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.allChannels = data.values;
            //Hardcoded till next release
            this.allChannels = [
                { value: 'Email', label: EMAIL }
            ];
        } else if (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    async connectedCallback() {
        const copadoUser = await isCopadoUser();
        const copadoAdmin = await isCopadoAdmin();
        this.tabs = [
            { label: MY_NOTIFICATIONS, isVisible: copadoUser, value: 'User' },
            { label: SYSTEM_NOTIFICATIONS, isVisible: copadoAdmin, value: 'System' }
        ];
        this.showSpinner = false;
    }
}