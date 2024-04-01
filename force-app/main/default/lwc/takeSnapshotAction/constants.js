import TAKE_SNAPSHOT_INFO_MESSAGE from '@salesforce/label/c.Take_Snapshot_Info_Message';
import COPADO_SNAPSHOT from '@salesforce/label/c.GitSnapshotTakeSnapshotCommitMessage';
import TOAST_SUCCESS from '@salesforce/label/c.Take_Snapshot_Success_Toast';
import HEADER from '@salesforce/label/c.Take_Snapshot_Header_Message';
import CANCEL from '@salesforce/label/c.Cancel';
import ACCEPT from '@salesforce/label/c.Accept';

import CREDENTIAL_NAME from '@salesforce/schema/Git_Backup__c.Org__r.Name';
import BRANCH from '@salesforce/schema/Git_Backup__c.Branch__c';
import SNAPSHOT_COMMIT_OBJECT from '@salesforce/schema/Git_Org_Commit__c';
import COMMIT_MESSAGE from '@salesforce/schema/Git_Org_Commit__c.Commit_Message__c';

export const labels = {
    TAKE_SNAPSHOT_INFO_MESSAGE,
    COPADO_SNAPSHOT,
    TOAST_SUCCESS,
    HEADER,
    CANCEL,
    ACCEPT
};

export const schema = {
    CREDENTIAL_NAME,
    BRANCH,
    SNAPSHOT_COMMIT_OBJECT,
    COMMIT_MESSAGE
};