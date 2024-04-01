import { LightningElement, api } from 'lwc';

export default class CdsEmptyState extends LightningElement {
    @api message;
    @api iconName;
    @api iconSize = 'medium';
    @api hasBody = false;
    @api hasAction = false;
}