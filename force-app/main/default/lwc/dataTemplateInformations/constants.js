import DATA_TEMPLATE_NAME from '@salesforce/schema/Data_Template__c.Name';
import DATA_TEMPLATE_MAIN_OBJECT from '@salesforce/schema/Data_Template__c.Main_Object__c';
import DATA_TEMPLATE_SOURCE_ORG from '@salesforce/schema/Data_Template__c.Template_Source_Org__r.Name';
import DATA_TEMPLATE_MAX_RECORDS from '@salesforce/schema/Data_Template__c.Max_Record_Limit__c';
import DATA_TEMPLATE_BATCH_SIZE from '@salesforce/schema/Data_Template__c.Batch_Size__c';

import RELATIONSHIP_DIAGRAM from '@salesforce/label/c.Relationship_Diagram';
import TEMPLATE_SOURCE_ORG from '@salesforce/label/c.DataTemplateSourceOrg';
import TEMPLATE_RELATED_OBJECTS from '@salesforce/label/c.DataTemplateTotalRelatedObjects';
import TEMPLATE_MAX_RECORDS from '@salesforce/label/c.DataTemplateMaxRecords';
import TEMPLATE_BATCH_SIZE from '@salesforce/label/c.DataTemplateBatchSize';
import TEMPLATE_DETAILS from '@salesforce/label/c.Template_Details';

import ICONS from '@salesforce/resourceUrl/DataTemplateIcons';

export const schema = {
    DATA_TEMPLATE_NAME,
    DATA_TEMPLATE_MAIN_OBJECT,
    DATA_TEMPLATE_SOURCE_ORG,
    DATA_TEMPLATE_MAX_RECORDS,
    DATA_TEMPLATE_BATCH_SIZE
};

let TEMPLATE_DETAIL = ICONS + '/newwindow.svg';
let RELATION_DIAGRAM = ICONS + '/relationship.svg';

export const images = {
    TEMPLATE_DETAIL,
    RELATION_DIAGRAM
};

export const labels = {
    RELATIONSHIP_DIAGRAM,
    TEMPLATE_SOURCE_ORG,
    TEMPLATE_RELATED_OBJECTS,
    TEMPLATE_MAX_RECORDS,
    TEMPLATE_BATCH_SIZE,
    TEMPLATE_DETAILS
};