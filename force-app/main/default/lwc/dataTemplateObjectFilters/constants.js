import DATA_TEMPLATE from '@salesforce/schema/Data_Template__c';
import MAX_RECORD_LIMIT from '@salesforce/schema/Data_Template__c.Max_Record_Limit__c';
import BATCH_SIZE from '@salesforce/schema/Data_Template__c.Batch_Size__c';

import MAIN_OBJECT_FILTER from '@salesforce/label/c.Main_Object_Filter';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import EDIT from '@salesforce/label/c.EDIT';
import REFRESH from '@salesforce/label/c.RefreshSchema';
import SCHEMA_REFRESHED from '@salesforce/label/c.SchemaRefreshed';
import COPADO_TIPS_TITLE from '@salesforce/label/c.Copado_Pro_Query_Tips';
import COPADO_TIPS1 from '@salesforce/label/c.Data_Template_Query_Tip_1';
import COPADO_TIPS2 from '@salesforce/label/c.Data_Template_Query_Tip_2';
import COPADO_TIPS3 from '@salesforce/label/c.Data_Template_Query_Tip_3';
import COPADO_TIPS4 from '@salesforce/label/c.Data_Template_Query_Tip_4';
import EDIT_DATA_TEMPLATE from '@salesforce/label/c.EditDataTemplate';
import DEACTIVATE from '@salesforce/label/c.Deactivate';
import EDIT_VALIDATION_MESSAGE from '@salesforce/label/c.DataTemplateEditValidationMsg';
import DATA_TEMPLATE_ACTIVE from '@salesforce/schema/Data_Template__c.Active__c';

export const label = {
    MAIN_OBJECT_FILTER,
    CANCEL,
    SAVE,
    EDIT,
    REFRESH,
    COPADO_TIPS_TITLE,
    COPADO_TIPS1,
    COPADO_TIPS2,
    COPADO_TIPS3,
    COPADO_TIPS4,
    EDIT_DATA_TEMPLATE,
    DEACTIVATE,
    EDIT_VALIDATION_MESSAGE,
    SCHEMA_REFRESHED
};

export const schema = { DATA_TEMPLATE };

export const FIELDS = {
    MAX_RECORD_LIMIT,
    BATCH_SIZE,
    DATA_TEMPLATE_ACTIVE
};