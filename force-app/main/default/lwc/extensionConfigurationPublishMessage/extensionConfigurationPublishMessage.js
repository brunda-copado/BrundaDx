import { LightningElement, api } from "lwc";
import EXTENSION_CONFIGURATION from "@salesforce/schema/ExtensionConfiguration__c";
import EXTENSION_TOOL from "@salesforce/schema/ExtensionConfiguration__c.ExtensionTool__c";

export default class PackageVersionPublishMessageChannel extends LightningElement {
    @api recordId;
    
    extensionToolField = EXTENSION_TOOL.fieldApiName;
    extensionConfigurationObject = EXTENSION_CONFIGURATION.objectApiName;
}