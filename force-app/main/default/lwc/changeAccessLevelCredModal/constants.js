import Change_Access_Level from '@salesforce/label/c.Change_Access_Level';
import Access_Level_Input from '@salesforce/label/c.Access_Level_Input';
import Cancel from '@salesforce/label/c.Cancel';
import Save from '@salesforce/label/c.Save';
import Access_Level_Input_Helptext from '@salesforce/label/c.Access_Level_Input_Helptext';
import Read_Write from '@salesforce/label/c.Read_Write';
import Read_Only from '@salesforce/label/c.Read_Only';
import Change_Access_Level_Success_Message from '@salesforce/label/c.Change_Access_Level_Success_Message';

export const label = {
    Change_Access_Level,
    Access_Level_Input,
    Cancel,
    Save,
    Access_Level_Input_Helptext,
    Read_Write,
    Read_Only,
    Change_Access_Level_Success_Message
};

export const accessLevelOptions = [
    { label: label.Read_Write, value: 'edit' },
    { label: label.Read_Only, value: 'read' }
];