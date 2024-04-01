import { LightningElement, api } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import { updateRecord, createRecord } from 'lightning/uiRecordApi';

import { getSortedData } from 'c/datatableService';
import { columns, labels, schema } from './constants';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';

import getDefaultNotification from '@salesforce/apex/NotificationsCenterCtrl.getDefaultNotification';

export default class NotificationsCenter extends LightningElement {
    @api tab;
    @api allChannels;

    userId;
    defaultNotification = {};
    showSpinner = true;
    isReadMode = true;
    labels = labels;

    columns;
    filteredRows = [];
    sortDirection = 'asc';
    sortedBy;


    async connectedCallback() {
        if (this.tab === 'User') {
            this.userId = currentUserId;
            this.labels.title = labels.USER_NOTIFICATION_TITLE;
            this.labels.body = labels.USER_NOTIFICATION_BODY;
            this.columns = columns.userNotificationColumns;
        } else if (this.tab === 'System') {
            this.userId = null;
            this.labels.title = labels.SYSTEM_NOTIFICATION_TITLE;
            this.labels.body = labels.SYSTEM_NOTIFICATION_BODY;
            this.columns = columns.systemNotificationColumns;
        }
        await this.getData();
    }


    async getData() {
        try {
            this.showSpinner = true;
            this.defaultNotification = await getDefaultNotification({ userId: this.userId });

            this.filteredRows = this.defaultNotification.subscriptions;
            this.defaultNotification.channels = ['Email']; // Hardcoded till next release
            this.allChannels = this.allChannels?.map(channel => ({
                ...channel,
                isDefault: this.defaultNotification.channels?.includes(channel.value)
            }));
        } catch (ex) {
            showToastError(this, { message: ex.message || ex.body?.message });
        } finally {
            this.showSpinner = false;
        }
    }

    // TABLE

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;

        this.filteredRows = [
            ...getSortedData(this.columns, this.filteredRows, {
                name: fieldName,
                sortDirection
            })
        ];
        this.sortDirection = sortDirection;
        this.sortedBy = fieldName;
    }


    handleSearch(event) {
        this.filteredRows = [...event.detail.searchedData];
    }


    handleClearSearch() {
        this.filteredRows = this.defaultNotification.subscriptions;
    }


    handleRowAction(event) {
        const action = event.detail.action.name;
        const subscription = event.detail.row;

        switch (action) {
            case 'edit':
                this.template.querySelector('c-notification-subscription').edit(subscription);
                break;
            default:
        }
    }

    // SIDE BAR

    handleEdit() {
        this.isReadMode = false;
    }


    handleCancel() {
        this.isReadMode = true;
        this._resetInput();
    }


    async handleSave() {
        try {
            this.showSpinner = true;
            const newDefaultChannels = [...this.template.querySelectorAll('lightning-input[data-input=channel]')]
                ?.filter(input => input.checked)
                ?.map(input => input.dataset.channel)
                ?.sort()
                ?.join(';');

            if (newDefaultChannels !== this.defaultNotification.channels?.sort()?.join(';')) {
                await this._saveDefaults(newDefaultChannels);
            }
        } catch (ex) {
            showToastError(this, { message: ex.message || ex.body?.message });
        } finally {
            this.showSpinner = false;
            this.isReadMode = true;
        }
    }


    async _saveDefaults(newDefaultChannels) {
        const fields = {};
        fields[schema.CHANNELS_FIELD.fieldApiName] = newDefaultChannels;

        if (this.defaultNotification.id) {
            await this._updateDefaults(fields);
        } else {
            await this._createDefaults(fields);
        }
        this.getData();
        showToastSuccess(this, { message: labels.DEFAULT_CHANNELS_UPDATED });
    }


    async _createDefaults(fields) {
        fields[schema.RECEIVER_FIELD.fieldApiName] = this.userId;
        const recordInput = { apiName: schema.ID_FIELD.objectApiName, fields };
        await createRecord(recordInput);
    }


    async _updateDefaults(fields) {
        fields[schema.ID_FIELD.fieldApiName] = this.defaultNotification.id;
        await updateRecord({ fields });
    }


    _resetInput() {
        this.allChannels?.forEach((channel) => {
            const input = this.template.querySelector('lightning-input[data-channel=' + channel.value + ']');
            input.checked = channel.isDefault;
        });
    }
}