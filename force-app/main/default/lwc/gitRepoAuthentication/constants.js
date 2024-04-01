import GIT_REPOSITORY from '@salesforce/schema/Git_Repository__c';
import GIT_PROVIDER_FIELD from '@salesforce/schema/Git_Repository__c.Git_Provider__c';
import URI_FIELD from '@salesforce/schema/Git_Repository__c.URI__c';
import COMMIT_BASE_URL_FIELD from '@salesforce/schema/Git_Repository__c.Commit_Base_URL__c';
import PULL_REQUEST_BASE_URL_FIELD from '@salesforce/schema/Git_Repository__c.Pull_Request_Base_URL__c';
import BRANCH_BASE_URL_FIELD from '@salesforce/schema/Git_Repository__c.Branch_Base_URL__c';
import TAG_BASE_URL_FIELD from '@salesforce/schema/Git_Repository__c.Tag_Base_URL__c';

export const schema = {
    GIT_REPOSITORY,
    GIT_PROVIDER_FIELD,
    URI_FIELD,
    COMMIT_BASE_URL_FIELD,
    PULL_REQUEST_BASE_URL_FIELD,
    BRANCH_BASE_URL_FIELD,
    TAG_BASE_URL_FIELD
};