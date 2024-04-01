import Setup_Continuous_Delivery from '@salesforce/label/c.Setup_Continuous_Delivery';
import CD_Setup_Preview_Header from '@salesforce/label/c.CD_Setup_Preview_Header';
import CD_Setup_Preview_Body from '@salesforce/label/c.CD_Setup_Preview_Body';
import Continue_Anyway from '@salesforce/label/c.Continue_Anyway';
import Cancel from '@salesforce/label/c.Cancel';
import CD_Setup_Preview_Info_Message from '@salesforce/label/c.CD_Setup_Preview_Info_Message';
import Automation_Rule_Name from '@salesforce/label/c.Automation_Rule_Name';
import Stages from '@salesforce/label/c.Stages';
import Selected_Environments from '@salesforce/label/c.Selected_Environments';

export const label = {
    Setup_Continuous_Delivery,
    CD_Setup_Preview_Header,
    CD_Setup_Preview_Body,
    Continue_Anyway,
    Cancel,
    CD_Setup_Preview_Info_Message
};

export const columns = [
    { label: Automation_Rule_Name, fieldName: 'name', hideDefaultActions: true },
    { label: Stages, fieldName: 'stages', hideDefaultActions: true }, 
    { label: Selected_Environments, fieldName: 'environments', cellAttributes: {
        class: 'slds-text-title',
    }, hideDefaultActions: true }
];