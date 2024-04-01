import DOWNLOAD from '@salesforce/label/c.Download';
import EXECUTION_LOG from '@salesforce/label/c.Execution_Log';
import LOGS_IN_PROGRESS from '@salesforce/label/c.Logs_In_Progress';
import LOG_NOT_GENERATED from '@salesforce/label/c.Log_Not_Generated';
import LOGS_NOT_AVAILABLE from '@salesforce/label/c.Logs_Not_Available';
import LOG_NOT_GENERATED_PROCESS from '@salesforce/label/c.Log_Not_Generated_Process';
import LARGE_FILE_SIZE_MESSAGE from '@salesforce/label/c.LargeFileSizeMessage';

import STATUS_FIELD from '@salesforce/schema/Result__c.Status__c';
import VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';
import CONTENT_SIZE_FIELD from '@salesforce/schema/ContentVersion.ContentSize';
import TITLE_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.Title';
import LATEST_PUBLISHED_VERSION_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.LatestPublishedVersionId';

import copadoUtils from 'c/copadocoreUtils';

export const labels = {
    DOWNLOAD,
    EXECUTION_LOG,
    LOGS_IN_PROGRESS,
    LOG_NOT_GENERATED,
    LOGS_NOT_AVAILABLE,
    LOG_NOT_GENERATED_PROCESS,
    LARGE_FILE_SIZE_MESSAGE
};

export const schema = {
    TITLE_FIELD,
    STATUS_FIELD,
    VERSION_DATA_FIELD,
    CONTENT_SIZE_FIELD,
    LATEST_PUBLISHED_VERSION_FIELD,
    RESULT_DOC_RELATIONSHIP: 'ContentDocumentLinks'
};

export const constants = {
    DOWNLOAD_URL: copadoUtils.versionDownloadURL,
    FINISHED_STATUSES: ['Success', 'Failed', 'Cancelled'],
    MAX_FILE_SIZE_SUPPORTED: '2097152' // 2 MB = 2,097,152 Bytes (Binary)
};