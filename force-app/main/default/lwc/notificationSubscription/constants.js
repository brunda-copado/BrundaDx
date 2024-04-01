import ID_FIELD from '@salesforce/schema/Notification_Subscription__c.Id';
import SUBSCRIBED_FIELD from '@salesforce/schema/Notification_Subscription__c.Subscribed__c';
import SUBSCRIPTION_CHANNELS_FIELD from '@salesforce/schema/Notification_Subscription__c.Channels__c';
import NOTIFICATION_NAME_FIELD from '@salesforce/schema/Notification_Subscription__c.Notification_Name__c';
import USER_DEFAULT_NOTIFICATION_FIELD from '@salesforce/schema/Notification_Subscription__c.User_Default_Notification__c';

import DEFAULT_CHANNELS_FIELD from '@salesforce/schema/Notification_Default_Channels__c.Channels__c';
import RECEIVER_FIELD from '@salesforce/schema/Notification_Default_Channels__c.Receiver__c';

import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import EDIT_NOTIFICATIONS from '@salesforce/label/c.EditNotification';
import NOTIFICATION_NAME from '@salesforce/label/c.NotificationName';
import DESCRIPTION from '@salesforce/label/c.Description';
import SUBSCRIBE from '@salesforce/label/c.Subscribe';
import LOADING from '@salesforce/label/c.LOADING';
import SUCCESS_MESSAGE from '@salesforce/label/c.SuccessMessage';

// CONSTANTS

const userSubscriptionLayout = [
    {
        typeInput: true,
        readOnly: true,
        label: NOTIFICATION_NAME,
        fieldName: 'label',
        size: 6
    },
    {
        typeInput: true,
        type: 'checkbox',
        label: SUBSCRIBE,
        fieldName: 'subscribed',
        apiName: SUBSCRIBED_FIELD.fieldApiName,
        size: 6
    },
    {
        typeInput: true,
        readOnly: true,
        label: DESCRIPTION,
        fieldName: 'description',
        size: 12
    }
];

const systemSubscriptionLayout = [
    {
        typeInput: true,
        readOnly: true,
        label: NOTIFICATION_NAME,
        fieldName: 'label',
        size: 6
    },
    {
        typeInput: true,
        type: 'checkbox',
        label: SUBSCRIBE,
        fieldName: 'subscribed',
        apiName: SUBSCRIBED_FIELD.fieldApiName,
        size: 6
    },
    {
        typeInput: true,
        readOnly: true,
        label: DESCRIPTION,
        fieldName: 'description',
        size: 12
    }
];

// EXPORTS

export const schema = {
    DEFAULT_CHANNELS_FIELD,
    RECEIVER_FIELD,
    ID_FIELD,
    NOTIFICATION_NAME_FIELD,
    SUBSCRIPTION_CHANNELS_FIELD,
    SUBSCRIBED_FIELD,
    USER_DEFAULT_NOTIFICATION_FIELD
};

export const labels = {
    SAVE,
    CANCEL,
    EDIT_NOTIFICATIONS,
    LOADING,
    SUCCESS_MESSAGE
};

export const layout = {
    userSubscriptionLayout,
    systemSubscriptionLayout
};