import { LightningElement, api } from "lwc";
import USER_STORY from "@salesforce/schema/User_Story__c";
import ENVIRONMENT_FIELD from "@salesforce/schema/User_Story__c.Environment__c";

export default class UserStoryTestPublishMessage extends LightningElement {
    @api recordId;
    
    userStoryEnvironmentField = ENVIRONMENT_FIELD.fieldApiName;
    userStoryObject = USER_STORY.objectApiName;
}