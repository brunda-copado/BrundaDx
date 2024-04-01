import { LightningElement, api } from 'lwc';
import TEST_OBJECT from "@salesforce/schema/Test__c";
import EXTENSION_TOOL from "@salesforce/schema/Test__c.ExtensionConfiguration__r.ExtensionTool__c";

export default class TestDefinitionPublishMessage extends LightningElement {
    @api recordId;
    
    testObject = TEST_OBJECT.objectApiName;
    extensionTool = EXTENSION_TOOL.fieldApiName;
}