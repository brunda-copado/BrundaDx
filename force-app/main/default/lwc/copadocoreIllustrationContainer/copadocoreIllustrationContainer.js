import { LightningElement, api } from 'lwc';

export default class CopadocoreIllustrationContainer extends LightningElement {
    @api message;
    @api slotMessage;
    @api imageName = 'custom:lake_mountain';
    @api size = 'medium';
}