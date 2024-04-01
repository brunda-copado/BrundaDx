import PULL_REQUEST_BASE_URL from '@salesforce/schema/Git_Repository__c.Pull_Request_Base_URL__c';
import GIT_PROVIDER from '@salesforce/schema/Git_Repository__c.Git_Provider__c';
import GIT_REPOSITORY from '@salesforce/schema/Deployment_Flow__c.Git_Repository__c';
import PROMOTION_NAME from '@salesforce/schema/Promotion__c.Name';

import GIT_URL_EMPTY from '@salesforce/label/c.GIT_URL_EMPTY';
import Open_Pull_Request from '@salesforce/label/c.Open_Pull_Request';
import GIT_REPOSITORY_REQUIRED from '@salesforce/label/c.GIT_REPOSITORY_REQUIRED';
import GIT_REPOSITORY_REDIRECT from '@salesforce/label/c.GIT_REPOSITORY_REDIRECT';
import POPUP_BLOCKER_MESSAGE from '@salesforce/label/c.POPUP_BLOCKER_MESSAGE';
import PULL_REQUEST_VALIDATION from '@salesforce/label/c.PULL_REQUEST_VALIDATION';
import Cancel from '@salesforce/label/c.Cancel';
import CLOSE from '@salesforce/label/c.CLOSE';
import VIEW_IN_GIT from '@salesforce/label/c.VIEW_IN_GIT';
import Promotion_Branch_PR_Button from '@salesforce/label/c.Promotion_Branch_PR_Button';
import Destination_Branch from '@salesforce/label/c.Destination_Branch';
import PULL_REQUEST_FOR_PROMOTION_CAN_NOT_BE_OPEN from '@salesforce/label/c.Pull_Request_For_Promotion_Can_Not_Be_Open';
import ERROR_TITLE from '@salesforce/label/c.Pull_Request_For_Promotion_Error';

// CONSTANTS

export const label = {
    GIT_URL_EMPTY,
    Open_Pull_Request,
    GIT_REPOSITORY_REQUIRED,
    GIT_REPOSITORY_REDIRECT,
    POPUP_BLOCKER_MESSAGE,
    PULL_REQUEST_VALIDATION,
    Cancel,
    CLOSE,
    VIEW_IN_GIT,
    Promotion_Branch_PR_Button,
    Destination_Branch,
    PULL_REQUEST_FOR_PROMOTION_CAN_NOT_BE_OPEN,
    ERROR_TITLE
};

export const fields = {
    PULL_REQUEST_BASE_URL,
    GIT_REPOSITORY,
    GIT_PROVIDER,
    PROMOTION_NAME
};