import { LightningElement, api, wire } from 'lwc';
import PLATFORM_FIELD from '@salesforce/schema/Artifact__c.Pipeline__r.Platform__c';

export default class PackageVersionCreationPublishMessage extends LightningElement {
    @api recordId;
    platformField = PLATFORM_FIELD;
}