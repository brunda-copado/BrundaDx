import { LightningElement, api } from 'lwc';
import PLATFORM_FIELD from '@salesforce/schema/Promotion__c.Platform__c';

export default class PublishPromotionPlatformMessage extends LightningElement {
    @api recordId;
    platformField = PLATFORM_FIELD;
}