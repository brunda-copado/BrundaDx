import { LightningElement, api } from "lwc";
import RELEASE from "@salesforce/schema/Release__c";
import RELEASE_NAME from "@salesforce/schema/Release__c.Name";

export default class ReleaseRelatedListPublishMessage extends LightningElement {
    @api recordId;
    
    releaseNameField = RELEASE_NAME.fieldApiName;
    releaseObject = RELEASE.objectApiName;
}