import { LightningElement, api } from 'lwc';
export default class DataTemplateRelationshipDiagram extends LightningElement {
    @api recordId;
    templateName;
    handlePopulateTemplateName(event) {
        this.templateName = event.detail;
    }
}