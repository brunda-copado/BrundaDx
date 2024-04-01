import { LightningElement, api } from "lwc";
import EPIC from "@salesforce/schema/Epic__c";
import EPIC_TITLE from "@salesforce/schema/Epic__c.Epic_Title__c";

export default class EpicRelatedListPublishMessage extends LightningElement {
    @api recordId;
    
    epicTitleField = EPIC_TITLE.fieldApiName;
    epicObject = EPIC.objectApiName;
}