import ENABLED from '@salesforce/label/c.Enabled';
import DISABLED from '@salesforce/label/c.Disabled';
import YES from '@salesforce/label/c.YES';
import NO from '@salesforce/label/c.NO';
import PREVIOUS_SELECTIONS from '@salesforce/label/c.PreviousSelections';
import SHOW_SELECTED from '@salesforce/label/c.ShowSelected';
import PREVIOUS_SELECTIONS_HELP_TEXT from '@salesforce/label/c.PreviousSelectionsHelpText';
import PREVIOUS_SELECTIONS_HELP_TEXT_DISABLED from '@salesforce/label/c.PreviousSelectionsHelpTextDisabled';
import FILES from '@salesforce/label/c.Files';
import SELECTED from '@salesforce/label/c.SELECTED';
import NAME from '@salesforce/label/c.NAME';
import TYPE from '@salesforce/label/c.TYPE';
import DIRECTORY from '@salesforce/label/c.Directory';
import LAST_MODIFIED_DATE from '@salesforce/label/c.Last_Modified_Date';
import LAST_MODIFIED_BY from '@salesforce/label/c.LASTMODIFIEDBY';
import OPERATION from '@salesforce/label/c.Operation';
import ADD from '@salesforce/label/c.ADD';
import DELETE from '@salesforce/label/c.DELETE';
import RETRIEVE_ONLY from '@salesforce/label/c.RETRIEVE_ONLY';
import NO_ITEMS_TO_DISPLAY from '@salesforce/label/c.NoItemsToDisplay';
import ITEMS from '@salesforce/label/c.Items';
import SORTED_BY from '@salesforce/label/c.SortedBy';
import FILTERED_BY from '@salesforce/label/c.FilteredBy';
import MORE_THAN_3_FILTERS_APPLIED from '@salesforce/label/c.MoreThan3FiltersApplied';
import FILTER_TABLE_UPDATED from '@salesforce/label/c.FilterTableUpdated';

import METADATA_ACTION_FIELD from '@salesforce/schema/User_Story_Metadata__c.Action__c';
import METADATA_API_NAME_FIELD from '@salesforce/schema/User_Story_Metadata__c.Metadata_API_Name__c';
import METADATA_DIRECTORY_FIELD from '@salesforce/schema/User_Story_Metadata__c.ModuleDirectory__c';
import METADATA_TYPE_FIELD from '@salesforce/schema/User_Story_Metadata__c.Type__c';
import METADATA_CATEGORY_FIELD from '@salesforce/schema/User_Story_Metadata__c.Category__c';
import JSON_INFORMATION_FIELD from '@salesforce/schema/User_Story_Metadata__c.JsonInformation__c';

export const label = {
    ENABLED,
    DISABLED,
    YES,
    NO,
    PREVIOUS_SELECTIONS,
    PREVIOUS_SELECTIONS_HELP_TEXT,
    PREVIOUS_SELECTIONS_HELP_TEXT_DISABLED,
    SHOW_SELECTED,
    FILES,
    SELECTED,
    NAME,
    TYPE,
    DIRECTORY,
    LAST_MODIFIED_DATE,
    LAST_MODIFIED_BY,
    OPERATION,
    ADD,
    DELETE,
    RETRIEVE_ONLY,
    NO_ITEMS_TO_DISPLAY,
    ITEMS,
    SORTED_BY,
    FILTERED_BY,
    MORE_THAN_3_FILTERS_APPLIED,
    FILTER_TABLE_UPDATED
};

export const schema = {
    METADATA_ACTION_FIELD,
    METADATA_API_NAME_FIELD,
    METADATA_DIRECTORY_FIELD,
    METADATA_TYPE_FIELD,
    METADATA_CATEGORY_FIELD,
    JSON_INFORMATION_FIELD
};