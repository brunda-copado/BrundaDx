import LOADING from '@salesforce/label/c.LOADING';
import COMMIT_NOW from '@salesforce/label/c.COMMIT_NOW';
import CANCEL from '@salesforce/label/c.Cancel';

import USER_STORY_OBJECT from '@salesforce/schema/User_Story__c';
import USER_STORY_COMMIT_OBJECT from '@salesforce/schema/User_Story_Commit__c';
import PLATFORM_FIELD from '@salesforce/schema/User_Story__c.Platform__c';
import USER_STORY_COMMIT_FIELD from '@salesforce/schema/JobExecution__c.UserStoryCommit__c';

import HIDE_LIGHTNING_HEADER from '@salesforce/resourceUrl/HideLightningHeader';

export const label = {
    LOADING,
    COMMIT_NOW,
    CANCEL
};

export const schema = {
    USER_STORY_OBJECT,
    USER_STORY_COMMIT_OBJECT,
    PLATFORM_FIELD,
    USER_STORY_COMMIT_FIELD
};

export const resource = {
    HIDE_LIGHTNING_HEADER
};