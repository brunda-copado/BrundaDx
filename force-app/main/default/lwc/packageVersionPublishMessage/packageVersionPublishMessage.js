import { LightningElement, api } from 'lwc';
import PLATFORM_FIELD from '@salesforce/schema/Artifact_Version__c.Artifact__r.Pipeline__r.Platform__c';

export default class PackageVersionPublishMessageChannel extends LightningElement {
    @api recordId;
    platformField = PLATFORM_FIELD;
}