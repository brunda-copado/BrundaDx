import No_Users_for_Persona from '@salesforce/label/c.No_Users_for_Persona';
import Start_Adding_Users_Now from '@salesforce/label/c.Start_Adding_Users_Now';
import Add_User from '@salesforce/label/c.Add_User';
import Users_Assigned_to_Persona from '@salesforce/label/c.Users_Assigned_to_Persona';
import User_Settings_Subtitle from '@salesforce/label/c.User_Settings_Subtitle';
import Search from '@salesforce/label/c.Search';
import Add_User_Button from '@salesforce/label/c.Add_User_Button';
import Create_New_User_in_this_Org from '@salesforce/label/c.Create_New_User_in_this_Org';
import Add_Users_to_Persona_Title from '@salesforce/label/c.Add_Users_to_Persona_Title';
import Add_Users_to_Persona_Subtitle from '@salesforce/label/c.Add_Users_to_Persona_Subtitle';
import Refresh from '@salesforce/label/c.REFRESH';
import Cancel from '@salesforce/label/c.Cancel';
import Reset_User_Password from '@salesforce/label/c.Reset_User_Password';
import Remove_from_Persona_Button from '@salesforce/label/c.Remove_From_Persona';
import Copado_Persona from '@salesforce/label/c.Copado_Persona';
import Yes from '@salesforce/label/c.YES';
import No from '@salesforce/label/c.NO';
import Not_in_Copado from '@salesforce/label/c.Not_in_Copado';
import Reset_Password_Success_Message from '@salesforce/label/c.Reset_Password_Success_Message';

import USER_OBJECT from '@salesforce/schema/User';
import NAME_FIELD from '@salesforce/schema/User.Name';
import USERNAME_FIELD from '@salesforce/schema/User.Username';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import ISACTIVE_FIELD from '@salesforce/schema/User.IsActive';
import PERSONA_NAME_FIELD from '@salesforce/schema/Persona_Definition__c.Name';

export const label = {
    No_Users_for_Persona,
    Start_Adding_Users_Now,
    Add_User,
    Users_Assigned_to_Persona,
    User_Settings_Subtitle,
    Search,
    Add_User_Button,
    Create_New_User_in_this_Org,
    Add_Users_to_Persona_Title,
    Add_Users_to_Persona_Subtitle,
    Refresh,
    Cancel,
    Reset_User_Password,
    Remove_from_Persona_Button,
    Copado_Persona,
    Yes,
    No,
    Not_in_Copado,
    Reset_Password_Success_Message
};

export const schema = {
    USER_OBJECT,
    NAME_FIELD,
    USERNAME_FIELD,
    EMAIL_FIELD,
    ISACTIVE_FIELD,
    PERSONA_NAME_FIELD
};