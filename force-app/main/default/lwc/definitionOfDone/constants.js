import New from '@salesforce/label/c.NEW';
import Edit from '@salesforce/label/c.EDIT';
import Level from '@salesforce/label/c.LEVEL';
import Delete from '@salesforce/label/c.DELETE';
import TestType from '@salesforce/label/c.TestType';
import DefinitionofDone from '@salesforce/label/c.DEFINITION_OF_DONE';
import TestCreatedSuccessfully from '@salesforce/label/c.TestCreatedSuccessfully';

import TEST from '@salesforce/schema/Test__c';
import USER_STORY from '@salesforce/schema/User_Story__c';

import USERSTORY_FIELD from '@salesforce/schema/Test__c.User_Story__c';
import NAME_FIELD from '@salesforce/schema/Test__c.Name';
import EXTENSION_CONFIGURATION_FIELD from '@salesforce/schema/Test__c.ExtensionConfiguration__c';

export const label = {
    New,
    Edit,
    Level,
    Delete,
    TestType,
    DefinitionofDone,
    TestCreatedSuccessfully
};

export const schema = {
    TEST,
    USER_STORY,
    USERSTORY_FIELD: USERSTORY_FIELD.fieldApiName,
    NAME_FIELD: NAME_FIELD.fieldApiName,
    EXTENSION_CONFIGURATION_FIELD: EXTENSION_CONFIGURATION_FIELD.fieldApiName
};