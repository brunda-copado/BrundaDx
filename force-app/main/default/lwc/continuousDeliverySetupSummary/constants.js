import Setup_Continuous_Delivery from '@salesforce/label/c.Setup_Continuous_Delivery';
import Summary from '@salesforce/label/c.SUMMARY';
import CD_Setup_Summary_Body from '@salesforce/label/c.CD_Setup_Summary_Body';
import Activate_automations from '@salesforce/label/c.Activate_automations';
import Back from '@salesforce/label/c.BACK';
import Continuous_Delivery_was_set_up_successfully from '@salesforce/label/c.Continuous_Delivery_was_set_up_successfully';
import Continuous_Delivery_could_not_be_set_up from '@salesforce/label/c.Continuous_Delivery_could_not_be_set_up';
import CD_Setup_Summary_Info_Message from '@salesforce/label/c.CD_Setup_Summary_Info_Message';
import CD_Setup_Summary_Warning_Message from '@salesforce/label/c.CD_Setup_Summary_Warning_Message';
import Automation_Rule_Name from '@salesforce/label/c.Automation_Rule_Name';
import Stages from '@salesforce/label/c.Stages';
import Selected_Environments from '@salesforce/label/c.Selected_Environments';
import Cancel from '@salesforce/label/c.Cancel';

import ID_FIELD from "@salesforce/schema/Deployment_Flow__c.Id";
import CONTINUOUS_DELIVERY_CONFIGURATION_JSON from '@salesforce/schema/Deployment_Flow__c.Continuous_Delivery_Configuration_Json__c';

export const pipelineFields = {
    ID_FIELD,
    CONTINUOUS_DELIVERY_CONFIGURATION_JSON
}

export const label = {
    Setup_Continuous_Delivery,
    Summary,
    CD_Setup_Summary_Body,
    Back,
    Activate_automations,
    Continuous_Delivery_was_set_up_successfully,
    Continuous_Delivery_could_not_be_set_up,
    CD_Setup_Summary_Info_Message,
    CD_Setup_Summary_Warning_Message,
    Cancel
};

export const columns = [
    { label: Automation_Rule_Name, fieldName: 'Name', hideDefaultActions: true },
    { label: Stages, fieldName: 'Stages', hideDefaultActions: true }, 
    { label: Selected_Environments, fieldName: 'Environments', hideDefaultActions: true },
];