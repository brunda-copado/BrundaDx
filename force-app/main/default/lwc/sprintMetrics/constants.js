import SPRINT_CHARTS_CAN_NOT_BE_DISPLAYED from '@salesforce/label/c.Sprint_Charts_can_not_be_displayed';
import SPRINT_CHARTS_REQUIRE_START_END_END_DATES from '@salesforce/label/c.Sprint_Charts_Require_Start_and_End_Dates';
import SPRINT_FREEZED_LABEL from '@salesforce/label/c.Sprint_Freezed';

import SPRINT_OBJECT from '@salesforce/schema/Sprint__c';
import STATUS_FIELD from '@salesforce/schema/Sprint__c.Status__c';
import START_DATE_FIELD from '@salesforce/schema/Sprint__c.Start_Date__c';
import END_DATE_FIELD from '@salesforce/schema/Sprint__c.End_Date__c';

const SPRINT_STATUS_COMPLETED = 'Completed';

export const labels = {
    SPRINT_CHARTS_CAN_NOT_BE_DISPLAYED,
    SPRINT_CHARTS_REQUIRE_START_END_END_DATES,
    SPRINT_FREEZED_LABEL
};

export const constants = {
    SPRINT_STATUS_COMPLETED
}

export const schema = {
    SPRINT_OBJECT,
    STATUS_FIELD,
    START_DATE_FIELD,
    END_DATE_FIELD
}