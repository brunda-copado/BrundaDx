import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import ADD_ACCEPTANCE_CRITERIA_TESTERS from '@salesforce/label/c.AddAcceptanceCriteriaTesters';
import CONFIRM_ACCEPTANCE_CRITERIA_SAVE from '@salesforce/label/c.ConfirmAcceptanceCriteriaSave';
import ERROR_ACCEPTANCE_CRITERIA_DUPLICATED_METRICS from '@salesforce/label/c.ErrorAcceptanceCriteriaDuplicatedMetrics';
import EMPTY_ACCEPTANCE_CRITERIA_TITLE from '@salesforce/label/c.EmptyAcceptanceCriteriaTitle';
import EMPTY_ACCEPTANCE_CRITERIA_BODY from '@salesforce/label/c.EmptyAcceptanceCriteriaBody';
import ACCEPTANCE_CRITERIA_HEADER_TITLE from '@salesforce/label/c.AcceptanceCriteriaHeaderTitle';
import ERROR_SEARCHING_RECORDS from '@salesforce/label/c.Error_Searching_Records';
import TESTER_SCOPE from '@salesforce/label/c.Tester_Scope';
import TESTER from '@salesforce/label/c.Tester';
import TYPE from '@salesforce/label/c.TYPE';
import MINIMUM_TESTERS from '@salesforce/label/c.Minimum_Testers';
import DELETE from '@salesforce/label/c.DELETE';

import EXTENSION_CONFIGURATION from '@salesforce/schema/ExtensionConfiguration__c';

export const labels = {
    EDIT,
    SAVE,
    CANCEL,
    ADD_ACCEPTANCE_CRITERIA_TESTERS,
    CONFIRM_ACCEPTANCE_CRITERIA_SAVE,
    ERROR_ACCEPTANCE_CRITERIA_DUPLICATED_METRICS,
    EMPTY_ACCEPTANCE_CRITERIA_TITLE,
    EMPTY_ACCEPTANCE_CRITERIA_BODY,
    ACCEPTANCE_CRITERIA_HEADER_TITLE,
    ERROR_SEARCHING_RECORDS,
    TESTER_SCOPE,
    TESTER,
    TYPE,
    MINIMUM_TESTERS,
    DELETE
};

export const schema = {
    EXTENSION_CONFIGURATION
};

export const metricOptions = [{ label: 'All', value: 'All' }];

export const typeOptions = [
    { label: 'Required', value: 'Required' },
    { label: 'Optional', value: 'Optional' }
];

export const testerScopeOptions = [
    { label: 'User', value: 'User' },
    { label: 'Group', value: 'Group' }
];