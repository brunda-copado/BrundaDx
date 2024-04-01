import CANCEL from '@salesforce/label/c.Cancel';
import NEXT from '@salesforce/label/c.NEXT';
import NEW_GIT_SNAPSHOT from '@salesforce/label/c.NEW_GIT_SNAPSHOT';
import NEW_GIT_SNAPSHOT_BODY_MESSAGE from '@salesforce/label/c.NEW_GIT_SNAPSHOT_BODY_MESSAGE';
import SALESFORCE_CLASSIC from '@salesforce/label/c.SALESFORCE_CLASSIC';
import SALESFORCE_2ND_GEN from '@salesforce/label/c.SALESFORCE_2ND_GEN';

import SNAPSHOT_OBJECT from '@salesforce/schema/Git_Backup__c';

export const labels = {
    NEW_GIT_SNAPSHOT,
    NEW_GIT_SNAPSHOT_BODY_MESSAGE,
    SALESFORCE_CLASSIC,
    SALESFORCE_2ND_GEN,
    CANCEL,
    NEXT
};

export const object = {
    SNAPSHOT_OBJECT
};

export const selectedValue = {
    classic: 'classic',
    multicloud: 'multicloud'
};

export const options = [
    { label: SALESFORCE_CLASSIC, value: selectedValue.classic },
    { label: SALESFORCE_2ND_GEN, value: selectedValue.multicloud }
];