import CANCEL from '@salesforce/label/c.Cancel';
import COMMIT from '@salesforce/label/c.Commit';
import COMMIT_NOW from '@salesforce/label/c.COMMIT_NOW';
import LOADING from '@salesforce/label/c.LOADING';
import COMMIT_MESSAGE_NOT_EMPTY from '@salesforce/label/c.CommitMessageNotEmpty';
import COMMIT_CHANGES_NOT_EMPTY from '@salesforce/label/c.CommitChangesNotEmpty';
import COMMIT_BASE_BRANCH_NOT_EMPTY from '@salesforce/label/c.CommitBaseBranchNotEmpty';

import USER_STORY_COMMIT_FIELD from '@salesforce/schema/JobExecution__c.UserStoryCommit__c';

export const label = {
    CANCEL,
    COMMIT,
    COMMIT_NOW,
    LOADING,
    COMMIT_MESSAGE_NOT_EMPTY,
    COMMIT_CHANGES_NOT_EMPTY,
    COMMIT_BASE_BRANCH_NOT_EMPTY
};

export const schema = {
    USER_STORY_COMMIT_FIELD
};