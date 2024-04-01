import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import DESCRIPTION from '@salesforce/label/c.Description';
import NEW_CUSTOM_PERSONA_TITLE from '@salesforce/label/c.New_Custom_Persona_Title';
import NEW_CUSTOM_PERSONA_SUBTITLE from '@salesforce/label/c.New_Custom_Persona_Subtitle';
import NAME from '@salesforce/label/c.Custom_Persona_Name';
import COPY_CONFIGURATION from '@salesforce/label/c.Custom_Persona_Copy_Configuration';
import COPY_CONFIGURATION_HELPTEXT from '@salesforce/label/c.Custom_Persona_Copy_Configuration_Helptext';
import ADD_CUSTOM_PERSONA_SUCCESS_MESSAGE from '@salesforce/label/c.Add_Custom_Persona_Success_Message';
import NONE_CREATE_EMPTY_CUSTOM_PERSONA from '@salesforce/label/c.None_Create_Empty_Custom_Persona';

export const label = {
    SAVE,
    CANCEL,
    NAME,
    DESCRIPTION,
    NEW_CUSTOM_PERSONA_TITLE,
    NEW_CUSTOM_PERSONA_SUBTITLE,
    COPY_CONFIGURATION,
    COPY_CONFIGURATION_HELPTEXT,
    ADD_CUSTOM_PERSONA_SUCCESS_MESSAGE,
    NONE_CREATE_EMPTY_CUSTOM_PERSONA
};

export const constants = {
    CREATE_EMPTY_PERSONA_VALUE: 'none',
    EMPTY_STRING: '',
    INPUT_FIELD_NAME: 'name',
    INPUT_FIELD_DESCRIPTION: 'description'
};