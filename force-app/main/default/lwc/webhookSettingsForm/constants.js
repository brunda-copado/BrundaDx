import Save from '@salesforce/label/c.Save';
import Cancel from '@salesforce/label/c.Cancel';
import Username from '@salesforce/label/c.USERNAME';
import Selected from '@salesforce/label/c.SELECTED';
import ExpiresIn from '@salesforce/label/c.ExpiresIn';
import Available from '@salesforce/label/c.Available';
import Configuration from '@salesforce/label/c.Configuration';
import Credentials from '@salesforce/label/c.ORG_CREDENTIALS';
import ExpiresInHelp from '@salesforce/label/c.ExpiresInHelp';
import CopadoActions from '@salesforce/label/c.CopadoActions';
import EditActionKey from '@salesforce/label/c.EditWebhookKey';
import AddNewActionKey from '@salesforce/label/c.AddNewWebhookKey';
import CopadoActionsHelp from '@salesforce/label/c.CopadoActionsHelp';
import Enter_Valid_Value from '@salesforce/label/c.Enter_Valid_Value';
import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';
import RunJobTemplate from '@salesforce/label/c.RunJobTemplate';
import RunTests from '@salesforce/label/c.RunTests';

import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import PIPELINE_ACTIONS_FIELD from '@salesforce/schema/Pipeline_Action__c.Action__c';

// EXPORTS

export const labels = {
    Save,
    Cancel,
    Username,
    Selected,
    ExpiresIn,
    Available,
    Credentials,
    Configuration,
    CopadoActions,
    ExpiresInHelp,
    EditActionKey,
    AddNewActionKey,
    CopadoActionsHelp,
    Enter_Valid_Value,
    Error_Searching_Records,
    RunJobTemplate,
    RunTests
};

export const schema = {
    NAME_FIELD,
    EMAIL_FIELD,
    PIPELINE_ACTIONS_FIELD
};