import Cancel from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import ENVIRONMENT_VAR from '@salesforce/label/c.Environment_Variable';
import NEW from '@salesforce/label/c.NEW';
import EDIT from '@salesforce/label/c.EDIT';
import Apply_all_Metadata from '@salesforce/label/c.Apply_all_Metadata';
import Specific_Metadata from '@salesforce/label/c.Specific_Metadata';
import INFORMATION from '@salesforce/label/c.INFORMATION'; 
import VarName from '@salesforce/label/c.VarName';
import DEFINE_SCOPE from '@salesforce/label/c.DEFINE_SCOPE';
import Default_Value from '@salesforce/label/c.Default_Value';
import Values from '@salesforce/label/c.Values';
import Metadata_and_Types from '@salesforce/label/c.Metadata_and_Types';
import Default_Value_Helptext from '@salesforce/label/c.Default_Value_Helptext';
import Metadata_and_Type_Helptext from '@salesforce/label/c.Metadata_and_Type_Helptext';
import Apply from '@salesforce/label/c.Apply';
import Search from '@salesforce/label/c.Search';
import Define_Scope_Helptext from '@salesforce/label/c.Define_Scope_Helptext';
import Fetch_Data_Error from '@salesforce/label/c.Fetch_Data_Error';
import Records_Updated_Successfully from '@salesforce/label/c.Records_Updated_Successfully';
import ENVIRONMENT_VAR_VALUE_EMPTY from '@salesforce/label/c.ENVIRONMENT_VAR_VALUE_EMPTY';
import DEFINE_METADATA_EMPTY from '@salesforce/label/c.DEFINE_METADATA_EMPTY';
import VARIABLE_NAME_REQUIRED from '@salesforce/label/c.VARIABLE_NAME_REQUIRED';
import EnvVar_Name_Update_Error from '@salesforce/label/c.EnvVar_Name_Update_Error'

export const label = {
    Cancel,
    SAVE,
    ENVIRONMENT_VAR,
    NEW,
    EDIT,
    Apply_all_Metadata,
    Specific_Metadata,
    INFORMATION,
    VarName,
    DEFINE_SCOPE,
    Default_Value,
    Values,
    Metadata_and_Types,
    Default_Value_Helptext,
    Metadata_and_Type_Helptext,
    Apply,
    Search,
    Define_Scope_Helptext,
    Fetch_Data_Error,
    Records_Updated_Successfully,
    ENVIRONMENT_VAR_VALUE_EMPTY,
    DEFINE_METADATA_EMPTY,
    VARIABLE_NAME_REQUIRED,
    EnvVar_Name_Update_Error
};

export const columns = [
    { label: 'Environment', fieldName: 'environment',  type: 'text',sortable: true, editable: false, searchable: true },
    { label: 'Value', fieldName: 'value', type: 'text', sortable: true, editable: true, searchable: true},
];