import ID_FIELD from '@salesforce/schema/Notification_Default_Channels__c.Id';
import CHANNELS_FIELD from '@salesforce/schema/Notification_Default_Channels__c.Channels__c';
import RECEIVER_FIELD from '@salesforce/schema/Notification_Default_Channels__c.Receiver__c';

import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import AVAILABLE_NOTIFICATIONS from '@salesforce/label/c.AvailableNotifications';
import SYSTEM_NOTIFICATION_TITLE from '@salesforce/label/c.SystemDefaultNotificationChannels';
import SYSTEM_NOTIFICATION_BODY from '@salesforce/label/c.SystemDefaultNotificationChannelsBody';
import USER_NOTIFICATION_TITLE from '@salesforce/label/c.UserDefaultNotificationChannels';
import USER_NOTIFICATION_BODY from '@salesforce/label/c.UserDefaultNotificationChannelsBody';
import NOTIFICATION_NAME from '@salesforce/label/c.NotificationName';
import DESCRIPTION from '@salesforce/label/c.Description';
import SUBSCRIBED from '@salesforce/label/c.Subscribed';
import SUBSCRIBE_USERS_BY_DEFAULT from '@salesforce/label/c.Subscribe_users_by_default';
import EDIT from '@salesforce/label/c.EDIT';
import LOADING from '@salesforce/label/c.LOADING';
import ITEMS from '@salesforce/label/c.Items';
import DEFAULT_CHANNELS_UPDATED from '@salesforce/label/c.DefaultChannelsUpdated';

// CONSTANTS

const userNotificationColumns = [
    { label: NOTIFICATION_NAME, fieldName: 'label', searchable: true, sortable: true },
    { label: DESCRIPTION, fieldName: 'description' },
    { label: SUBSCRIBED, fieldName: 'subscribed', type: 'boolean', sortable: true },
    {
        type: 'action',
        typeAttributes: { rowActions: [{ label: EDIT, name: 'edit' }] }
    }
];

const systemNotificationColumns = [
    { label: NOTIFICATION_NAME, fieldName: 'label', searchable: true, sortable: true },
    { label: DESCRIPTION, fieldName: 'description' },
    { label: SUBSCRIBE_USERS_BY_DEFAULT, fieldName: 'subscribed', type: 'boolean', sortable: true },
    {
        type: 'action',
        typeAttributes: { rowActions: [{ label: EDIT, name: 'edit' }] }
    }
];

// EXPORTS

export const schema = {
    ID_FIELD,
    CHANNELS_FIELD,
    RECEIVER_FIELD
};

export const columns = {
    userNotificationColumns,
    systemNotificationColumns
};

export const labels = {
    SAVE,
    CANCEL,
    AVAILABLE_NOTIFICATIONS,
    SYSTEM_NOTIFICATION_BODY,
    SYSTEM_NOTIFICATION_TITLE,
    USER_NOTIFICATION_BODY,
    USER_NOTIFICATION_TITLE,
    LOADING,
    ITEMS,
    DEFAULT_CHANNELS_UPDATED
};