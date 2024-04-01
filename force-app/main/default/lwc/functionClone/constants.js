import Cancel from '@salesforce/label/c.Cancel';
import Clone_Function from '@salesforce/label/c.Clone_Function';
import Function_was_successfully_cloned from '@salesforce/label/c.Function_was_successfully_cloned';
import Clone_Function_Info from '@salesforce/label/c.Clone_Function_Info';
import It_was_not_possible_to_clone_this_Function from '@salesforce/label/c.It_was_not_possible_to_clone_this_Function';
import Error from '@salesforce/label/c.ERROR';
import CopyOf from '@salesforce/label/c.CopyOf';

import NAME_FIELD from '@salesforce/schema/Function__c.Name';
import OWNERID_FIELD from '@salesforce/schema/JobTemplate__c.OwnerId';
import DESCRIPTION_FIELD from '@salesforce/schema/Function__c.Description__c';
import API_NAME_FIELD from '@salesforce/schema/Function__c.API_Name__c';

export const fields = [
    {
        fieldName: NAME_FIELD.fieldApiName,
        isRequired: true,
        size: 6
    },
    {
        fieldName: OWNERID_FIELD.fieldApiName,
        isOutput: true,
        size: 6
    },
    {
        fieldName: API_NAME_FIELD.fieldApiName,
        value: '',
        size: 6
    },
    {
        fieldName: DESCRIPTION_FIELD.fieldApiName,
        size: 6
    }
];

export const label = {
    Cancel,
    Clone_Function,
    Clone_Function_Info,
    Function_was_successfully_cloned,
    It_was_not_possible_to_clone_this_Function,
    Error,
    CopyOf
};