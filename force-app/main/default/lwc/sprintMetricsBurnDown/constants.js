import IDEAL_POINTS from '@salesforce/label/c.Ideal_Points';
import PENDING_POINTS from '@salesforce/label/c.Pending_Points';
import SPRINT_BURN_DOWN_CHART from '@salesforce/label/c.Sprint_Burn_Down_Chart';
import SPRINT_SNAPSHOT_MAPPING_MISSING from '@salesforce/label/c.Sprint_Snapshot_Mapping_is_Missing';

import START_DATE_FIELD from '@salesforce/schema/Sprint__c.Start_Date__c';
import END_DATE_FIELD from '@salesforce/schema/Sprint__c.End_Date__c';

export const customLabels = {
    IDEAL_POINTS,
    PENDING_POINTS,
    SPRINT_BURN_DOWN_CHART,
    SPRINT_SNAPSHOT_MAPPING_MISSING
};

export const schema = {
    START_DATE_FIELD,
    END_DATE_FIELD
};