import { LightningElement, api } from 'lwc';
import QGRC_OBJECT from "@salesforce/schema/Quality_Gate_Rule_Condition__c";
import EXTENSION_TOOL from "@salesforce/schema/Quality_Gate_Rule_Condition__c.Extension_Configuration__r.ExtensionTool__c";

export default class qgrcTestToolPublishMessage extends LightningElement {
    @api recordId;
    
    qgrcObject = QGRC_OBJECT.objectApiName;
    extensionTool = EXTENSION_TOOL.fieldApiName;
}