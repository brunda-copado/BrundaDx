import { LightningElement, api } from 'lwc';

export default class CdsPageHeader extends LightningElement {
    @api iconName;
    @api iconSize = 'medium';
}