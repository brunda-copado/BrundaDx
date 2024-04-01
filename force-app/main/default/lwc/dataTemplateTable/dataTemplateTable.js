import LightningDatatable from 'lightning/datatable';
import { loadStyle } from 'lightning/platformResourceLoader';

import sfAttribute from './sfAttribute.html';
import select from './select.html';
import selectExternalId from './selectExternalId.html';
import contentUpdateTemplate from './contentUpdate.html';
import deploymentTemplate from './deploymentTemplate.html';
import objectApiName from './objectApiName.html';

import DATA_TEMPLATE_TABLE_RESOURCES from '@salesforce/resourceUrl/DataTemplateTable';

export default class DataTemplateTable extends LightningDatatable {
    static customTypes = {
        attribute: {
            template: sfAttribute,
            standardCellLayout: true,
            typeAttributes: ['isExternalId', 'isRequired']
        },
        selectColumn: {
            template: select,
            standardCellLayout: true,
            typeAttributes: ['isSelected', 'readOnlyMode', 'fieldName']
        },
        selectExternalId: {
            template: selectExternalId,
            standardCellLayout: true,
            typeAttributes: ['isSelected', 'isExternalId', 'readOnlyMode', 'fieldName']
        },
        objectName: {
            template: objectApiName,
            standardCellLayout: true
        },
        contentUpdate: {
            template: contentUpdateTemplate,
            standardCellLayout: true,
            typeAttributes: [
                'isSelected',
                'contentValueUpdateValues',
                'fieldContentUpdate',
                'replaceValue',
                'replaceValueNumber',
                'replaceValueDate',
                'replaceValueDatetime',
                'readOnlyMode',
                'fieldName',
                'fieldType',
                'recordId'
            ]
        },
        deploymentTemplate: {
            template: deploymentTemplate,
            standardCellLayout: true,
            typeAttributes: ['isSelected', 'recordId', 'objectName', 'objectLabel', 'deploymentTemplateId', 'readOnlyMode', 'fieldName', 'fieldType']
        }
    };

    renderedCallback() {
        super.renderedCallback();
        loadStyle(this, DATA_TEMPLATE_TABLE_RESOURCES + '/style.css');
    }
}