import { LightningElement, api } from "lwc";
import FEATURE from "@salesforce/schema/Application_Feature__c";
import FEATURE_NAME from "@salesforce/schema/Application_Feature__c.Name";

export default class FeatureRelatedListPublishMessage extends LightningElement {
    @api recordId;
    
    featureNameField = FEATURE_NAME.fieldApiName;
    featureObject = FEATURE.objectApiName;
}