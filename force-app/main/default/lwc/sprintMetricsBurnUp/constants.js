import PLANNED_POINTS from '@salesforce/label/c.Planned_Points';
import COMPLETED_POINTS from '@salesforce/label/c.Completed_Points';
import SPRINT_BURN_UP_CHART from '@salesforce/label/c.Sprint_Burn_Up_Chart';
import SPRINT_SNAPSHOT_MAPPING_MISSING from '@salesforce/label/c.Sprint_Snapshot_Mapping_is_Missing';

import START_DATE_FIELD from '@salesforce/schema/Sprint__c.Start_Date__c';
import END_DATE_FIELD from '@salesforce/schema/Sprint__c.End_Date__c';

export const customLabels = {
    PLANNED_POINTS,
    COMPLETED_POINTS,
    SPRINT_BURN_UP_CHART,
    SPRINT_SNAPSHOT_MAPPING_MISSING
};

export const schema = {
    START_DATE_FIELD,
    END_DATE_FIELD
};