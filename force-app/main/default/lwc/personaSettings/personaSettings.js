import { LightningElement, api } from 'lwc';

import Persona_Management_Users_Tab from '@salesforce/label/c.Persona_Management_Users_Tab';
import Persona_Management_Permissions_Tab from '@salesforce/label/c.Persona_Management_Permissions_Tab';
import Persona_Management_Licenses_Tab from '@salesforce/label/c.Persona_Management_Licenses_Tab';
import Persona_Management_Credentials_Tab from '@salesforce/label/c.Persona_Management_Credentials_Tab';

export default class PersonaSettings extends LightningElement {
    @api personaDefinition;
    @api numberOfUsers;

    label = {
        Persona_Management_Users_Tab,
        Persona_Management_Permissions_Tab,
        Persona_Management_Licenses_Tab,
        Persona_Management_Credentials_Tab
    };
}