import { LightningElement, api,wire } from 'lwc';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import JQUERY from '@salesforce/resourceUrl/Statics';
import queryTemplateDetail from '@salesforce/apex/DataTemplateExportCtrl.queryTemplateDetail';
import DATA_TEMPLATE_NAME_FIELD from '@salesforce/schema/Data_Template__c.Name';
import { loadScript } from "lightning/platformResourceLoader";
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { createAlert } from './utils';
import { reduceErrors } from 'c/copadocoreUtils';
import { publish, MessageContext } from 'lightning/messageService';
import { clearAllActionAlerts, EXPORT_ALERT_ID } from 'c/datatemplateUtil';
export default class DataTemplateExport extends LightningElement {
    @wire(MessageContext)
    messageContext;

    $copado;
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: DATA_TEMPLATE_NAME_FIELD })
    dataTemplate; 

    _wholeArrayParam = [];
    _wholeResponse = []; 
    _exportName;
    _communicationId = 'DataTemplateAlerts';
    _alertId = EXPORT_ALERT_ID;
    @api invoke() {
        this.createFileAndDownload();
    }

    renderedCallback(){
        loadScript(this, JQUERY + '/js/libs/jquery.min.3.6.0.js')
        .then(() => {
            this.$copado = this.$copado || jQuery.noConflict();
        })
        .catch(error=>{
            console.log('Failed to load the JQuery : ' +error);
        });
    }
    createFileAndDownload(){
        try {
            this.exportTemplate([this.recordId], getFieldValue(this.dataTemplate.data, DATA_TEMPLATE_NAME_FIELD)); 
        } catch (error) {
            const errorMessage = reduceErrors(error);
            this._publishOnMessageChannel(errorMessage, 'error', 'add');
        }    
    }

    exportTemplate(arrayParam, mainName){
        this._wholeArrayParam = this._wholeArrayParam.concat(arrayParam);
        let deferredArray = [];
        if (mainName) {
            this._exportName = mainName;
        }

        for (let i = 0; i < arrayParam.length; i++) {
            let deferred = new this.$copado.Deferred();
            deferredArray.push(deferred);
            this.queryAttachment(arrayParam[i], deferred.resolve);
        }

        //waits for every callout in the for loop to be done via deferred pattern and then calls the final actions
        this.$copado.when.apply(this, deferredArray).then(() => {
            let nextArrayParam = [];
            for (let i = 0; i < this._wholeResponse.length; i++) {
                for (let j = 0; j < arrayParam.length; j++) {
                    if (this._wholeResponse[i].templateUUId == arrayParam[j]) {
                        let values = this._wholeResponse[i].values;
                        nextArrayParam = nextArrayParam.concat(values.relationList);
                    }
                }
            }

            if (nextArrayParam.length == 0) {
                this.exportFinally(); 
            } else {
                let newArrayParam = [];
                for (let i = 0; i < nextArrayParam.length; i++) {
                    if (this._wholeArrayParam.indexOf(nextArrayParam[i]) == -1) {
                        if(nextArrayParam[i].templateUUId != null){
                            newArrayParam.push(nextArrayParam[i].templateUUId);
                        }
                    }
                }
                this.exportTemplate(newArrayParam);
            } 
        });
    }    
    exportFinally(){
        let dataStr = JSON.stringify(this._wholeResponse, null, 4);
        let regexValue;
        for (let i = 0; i < this._wholeResponse.length; i++) {
            let key = this._wholeResponse[i].templateUUId;
            let newKey = ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c =>
                (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))).toString(16)
            );
            regexValue = new RegExp(key, 'g');
            dataStr = dataStr.replace(regexValue, newKey);
        }

        let encodedData = window.btoa(dataStr); // encode a string

        let byteCharacters = atob(encodedData);
        let byteArrays = [];
        let sliceSize = 512;
        let contentType = 'application/json';

        for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
            let slice = byteCharacters.slice(offset, offset + sliceSize);

            let byteNumbers = new Array(slice.length);
            for (let i = 0; i < slice.length; i++) {
                byteNumbers[i] = slice.charCodeAt(i);
            }

            let byteArray = new Uint8Array(byteNumbers);
            byteArrays.push(byteArray);
        }

        let blob = new Blob(byteArrays, { type: contentType });
        let blobUrl = URL.createObjectURL(blob);
        let exportFileDefaultName = this._exportName;

        let linkElement = document.createElement('a');
        linkElement.setAttribute('href', blobUrl);
        linkElement.setAttribute('download', exportFileDefaultName);
        linkElement.click();
    }

    createContentForEachTemplate(content){
        let newContent = {
            objectFields: [],
            parentObjects: [],
            childObjects: []
        };

        if (content.selectableFieldsMap) {
            let fields = content.selectableFieldsMap;
            let objFields = {};
            for (let key in fields) {
                let parentObjectApiNameMap = fields[key].parentObjectApiNameMap;
                if (fields[key].isSelected && parentObjectApiNameMap && Object.keys(parentObjectApiNameMap).length == 0) {
                    objFields = {
                        name: fields[key].label,
                        apiName: fields[key].name
                    };

                    if (fields[key].useAsExternalId) {
                        objFields['useAsExternalId'] = true;
                    }

                    if (fields[key].contentValueUpdateValues) {
                        objFields['contentValueUpdateValues'] = fields[key].contentValueUpdateValues;
                    }

                    if (fields[key].fieldContentUpdate && fields[key].fieldContentUpdate !== 'none') {
                        objFields['fieldContentUpdate'] = fields[key].fieldContentUpdate;

                        if (fields[key].fieldContentUpdate === 'replace') {
                            if (fields[key].replaceValue) {
                                objFields['replaceValue'] = fields[key].replaceValue;
                            }

                            if (fields[key].replaceValueDate) {
                                objFields['replaceValueDate'] = fields[key].replaceValueDate;
                            }

                            if (fields[key].replaceValueDatetime) {
                                objFields['replaceValueDatetime'] = fields[key].replaceValueDatetime;
                            }

                            if (fields[key].replaceValueNumber && fields[key].replaceValueNumber > 0) {
                                objFields['replaceValueNumber'] = fields[key].replaceValueNumber;
                            }
                        }
                    }
                    newContent.objectFields.push(objFields);
                } else if (
                    fields[key].isSelected &&
                    parentObjectApiNameMap &&
                    Object.keys(parentObjectApiNameMap).length != 0 &&
                    (fields[key].deploymentTemplate !== 'Select Template' || Object.keys(parentObjectApiNameMap).indexOf('User') >= 0)
                ) {
                    objFields = {
                        name: fields[key].label,
                        apiName: fields[key].name
                    };
                    newContent.parentObjects.push(objFields);
                }
            }
            // child object field mapping
            let childRelations = content.selectableChildRelationsMap;
            for (let key in childRelations) {
                if (childRelations[key].isSelected && childRelations[key].deploymentTemplate !== 'Select Template') {
                    objFields = {
                        field: childRelations[key].field,
                        relationshipName: childRelations[key].relationshipName,
                        childSObject: childRelations[key].childSObject,
                        childSObjectLabel: childRelations[key].objectApiNameMap[childRelations[key].childSObject]
                    };
                    newContent.childObjects.push(objFields);
                }
            }
        }
        return newContent;
    };

    queryAttachment(param, cbOnEnd){
        let returnObj = new Object();
        let wholeObj = new Object();
       queryTemplateDetail({ parentId: param })
        .then((res) => {
            let contents = null;
            let relations = [];
            let filters = [];
            if (res) {
                contents = JSON.parse(res);
                contents.parentObjectsReferenceList.forEach(function(idElem) {
                    let relationObject = {
                        templateUUId: idElem.templateId,
                        relationName: idElem.relationName
                    };
                    relations.push(relationObject);
                });
                contents.childrenObjectsReferenceList.forEach(function(idElem) {
                    let relationObject = {
                        templateUUId: idElem.templateId,
                        relationName: idElem.relationName,
                        childSObject: idElem.childSObject
                    };
                    relations.push(relationObject);
                });

                let dataTemplate = {
                    templateName: contents.dataTemplate.templateName,
                    templateMainObject: contents.dataTemplate.templateMainObject,
                    templateQueryLimit: contents.dataTemplate.templateQueryLimit,
                    templateDescription: contents.dataTemplate.templateDescription,
                    templateFilterLogic: contents.dataTemplate.templateFilterLogic,
                    templateAttachmentOptions: contents.dataTemplate.templateAttachmentOption,
                    templateBatchSize: contents.dataTemplate.templateBatchSize,
                    templateMatchOwners: contents.dataTemplate.templateMatchOwners,
                    templateMatchRecordTypes: contents.dataTemplate.templateMatchRecordTypes,
                    templateContinueOnError: contents.dataTemplate.templateContinueOnError,
                    templateActive: contents.dataTemplate.templateActive,
                    templateAttachmentType: contents.dataTemplate.templateSelectedAttachmentType
                };

                contents.queryFilterList.forEach(function(filterItem) {
                    let filterObject = {
                        order: filterItem.order,
                        operator: filterItem.operator,
                        fieldName: filterItem.fieldName,
                        fieldType: filterItem.fieldType,
                        finalValue: filterItem.finalValue
                    };

                    if (filterItem.input) {
                        filterObject['input'] = filterItem.input;
                    }
                    if (filterItem.numberInput) {
                        filterObject['numberInput'] = filterItem.numberInput;
                    }
                    if (filterItem.dateInput) {
                        filterObject['dateInput'] = filterItem.dateInput;
                    }
                    if (filterItem.dateTimeInput) {
                        filterObject['dateTimeInput'] = filterItem.dateTimeInput;
                    }

                    filters.push(filterObject);
                });

                returnObj.dataTemplate = dataTemplate;
                returnObj.content = this.createContentForEachTemplate(contents);
                returnObj.relationList = relations.length > 0 ? relations : [];
                returnObj.filterList = filters.length > 0 ? filters : [];

                wholeObj.templateUUId = param;
                wholeObj.values = returnObj;

                this._wholeResponse.push(wholeObj);

                cbOnEnd && cbOnEnd();
            }
       })
       .catch((error) => {
        const errorMessage = reduceErrors(error);
        this._publishOnMessageChannel(errorMessage, 'error', 'add');
       });
    }
    _publishOnMessageChannel(message, type, operation) {
        clearAllActionAlerts(this.messageContext, COPADO_ALERT_CHANNEL, this._communicationId);
        const alertMessage = createAlert(message, type, true, this._communicationId, this._alertId, operation);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);
    }      
}