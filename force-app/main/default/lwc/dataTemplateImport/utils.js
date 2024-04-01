import { schema } from './constants';
export function formatLabel(customLabel, ...formattingArguments) {
    if (typeof customLabel !== 'string') return customLabel;
    return customLabel.replace(/{(\d+)}/gm, (match, index) => (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
}

export const addNameSpace = (namespace, apiName) => {
    return namespace && !apiName.startsWith(namespace) ? `${namespace}${apiName}` : apiName;
}

export const createDataTemplateAttachmentsBody = (attachmentData, namespace) => {
    const attachmentBodyData = {
        parentId: attachmentData.parentId,
        describeResult: attachmentData.describeResult,
        globalDescribe: attachmentData.globalDescribe,
        sourceOrgId: attachmentData.sourceOrgId,
        importedObj: attachmentData.importedObj,
        templateDetails: attachmentData.templateDetails
    }

    const mainDataTemplate = {
        templateSourceOrg: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.SOURCE_ORG_FIELD.fieldApiName)],
        templateName: attachmentBodyData.templateDetails[schema.NAME.fieldApiName],
        templateMatchRecordTypes: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.MATCH_RECORDTYPE.fieldApiName)],
        templateMainObject: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.MAIN_OBJECT.fieldApiName)],
        templateMatchOwners: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.MATCH_OWNERS.fieldApiName)],
        templateId: attachmentBodyData.parentId,
        templateDescription: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.DESCRIPTION.fieldApiName)],
        templateContinueOnError: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.CONTINUE_ON_ERROR.fieldApiName)],
        templateActive: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.ACTIVE.fieldApiName)],
        templateQueryLimit: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.MAX_RECORD_LIMIT.fieldApiName)],
        templateBatchSize: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.BATCH_SIZE.fieldApiName)],
        templateFilterLogic: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.FILTER_LOGIC.fieldApiName)],
        templateAttachmentOption: attachmentBodyData.templateDetails[addNameSpace(namespace, schema.ATTACHMENT_OPTIONS.fieldApiName)],
        templateSelectedAttachmentType: attachmentBodyData.importedObj.dataTemplate.templateAttachmentType
    };

    const resultData = {
        describeResult: attachmentBodyData.describeResult,
        globalDescribe: attachmentBodyData.globalDescribe,
        importedObj: attachmentBodyData.importedObj,
        templateDetails: attachmentBodyData.templateDetails
    };

    const populatedData = _matchCopadoFieldsForDataTemplateAttachment(resultData);

    const attachmentBody = {
        dataTemplate: mainDataTemplate,
        parentObjectsReferenceList: populatedData.parentObjectsReferenceList,
        childrenObjectsReferenceList: populatedData.childrenObjectsReferenceList,
        selectableFieldsMap: populatedData.fields,
        selectableChildRelationsMap: populatedData.childObjects,
        queryFilterList: populatedData.queryFilterList
    };

    const finalMap = {
        templateDetail: attachmentBody,
        describeResult: populatedData.describeResult
    };

    return finalMap;
}

const _matchCopadoFieldsForDataTemplateAttachment = (resultData) => {
    let relationList = resultData.importedObj.relationList;
    let filterArray = resultData.importedObj.filterList;
    let childObjetcsArray = resultData.importedObj.content.childObjects;
    let objectFieldsArray = resultData.importedObj.content.objectFields;
    objectFieldsArray = objectFieldsArray.concat(resultData.importedObj.content.parentObjects);
    let describeResult = resultData.describeResult;
    let describeFieldsResult = describeResult.fields;
    let childRelationshipsResult = describeResult.childRelationships;
    let globalDescribe = resultData.globalDescribe;
    let globalDescribeSobjects = globalDescribe.sobjects;
    let updatedDescribeFieldsResult = {};
    let updatedChildRelationshipResult = {};
    let currentField = {};
    let newDescribeFieldsResult = [];
    let parentObjectsReferenceList = [];
    let childrenObjectsReferenceList = [];
    let queryFilterList = [];
    let objectLabelName;
    let placeHolder = null;

    // object fields and parent object fields mapping
    describeFieldsResult.forEach((object) => {
        currentField = objectFieldsArray.find((element) => {
            return element.apiName === object.name;
        });

        let isSelected = currentField ? true : false;
        let tempUseAsExternalId = currentField && currentField.useAsExternalId ? currentField.useAsExternalId : false;
        let tempFieldContentUpdate = currentField && currentField.fieldContentUpdate ? currentField.fieldContentUpdate : '';
        let tempReplaceValue = currentField && currentField.replaceValue ? currentField.replaceValue : '';
        let tempReplaceValueNumber = currentField && currentField.replaceValueNumber ? currentField.replaceValueNumber : placeHolder;
        let tempReplaceValueDate = currentField && currentField.replaceValueDate ? currentField.replaceValueDate : placeHolder;
        let tempReplaceValueDatetime = currentField && currentField.replaceValueDatetime ? currentField.replaceValueDatetime : placeHolder;
        let tempContentValueUpdateValues = currentField && currentField.contentValueUpdateValues ? currentField.contentValueUpdateValues : placeHolder;
        let tempParentObjectApiNameMap = {};

        // to populate 'parentObjectApiNameMap' parameter, we will check if the field has reference to any other object
        let currentSObject = {};
        if (object.referenceTo) {
            object.referenceTo.forEach((objectName) => {
                currentSObject = globalDescribeSobjects.find((element) => {
                    return element.name === objectName;
                });
                tempParentObjectApiNameMap[currentSObject.name] = currentSObject.label;
            });
        }

        let copadoFields = {
            isSelected: isSelected,
            useAsExternalId: tempUseAsExternalId,
            externalId: object.externalId,
            label: object.label,
            name: object.name,
            fieldType: object.type,
            contentValueUpdateValues: tempContentValueUpdateValues,
            fieldContentUpdate: tempFieldContentUpdate,
            replaceValue: tempReplaceValue,
            replaceValueNumber: tempReplaceValueNumber,
            replaceValueDate: tempReplaceValueDate,
            replaceValueDatetime: tempReplaceValueDatetime,
            parentObjectApiNameMap: tempParentObjectApiNameMap,
            deploymentTemplateNameMap: placeHolder,
            deploymentTemplate: 'Select Template'
        };

        updatedDescribeFieldsResult[object.name] = copadoFields;

        let newDescribeResultField = {
            autonumber: object.autonumber, 
            calculated: object.calculated,
            custom: object.custom,
            externalId: object.externalId,
            filterable: object.filterable,
            label: object.label,
            length: object.length,
            name: object.name,
            nillable: object.nillable,
            relationshipName: object.relationshipName,
            relationshipOrder: object.relationshipOrder,
            referenceTo: object.referenceTo,
            sortable: object.sortable,
            type: object.type,
            unique: object.unique,
            writeRequiresMasterRead: object.writeRequiresMasterRead,
            replaceValueNumber: tempReplaceValueNumber,
            replaceValueDate: tempReplaceValueDate,
            replaceValueDatetime: tempReplaceValueDatetime
        };
        newDescribeFieldsResult.push(newDescribeResultField);
    });

    let childRelationshipsList = [];
    let innerChildRelationshipsList = [];
    let index = 0;
    // child object mapping
    childRelationshipsResult.forEach((object) => {
        let isSelected = false;
        index = childObjetcsArray.findIndex((element) => {
            if (object.relationshipName) {
                return (element.field === object.field && element.childSObject === object.childSObject);
            }
        });
        if (index !== -1) {
            isSelected = true;
        }

        objectLabelName = globalDescribeSobjects.find((describeSobject) => {
            return describeSobject.name === object.childSObject;
        });

        let objectLabel = {};
        if (objectLabelName) {
            objectLabel[object.childSObject] = objectLabelName.label;

            let childObjects = {
                isSelected: isSelected,
                childSObject: object.childSObject,
                field: object.field,
                relationshipName: object.relationshipName,
                objectApiNameMap: objectLabel,
                deploymentTemplateNameMap: {},
                deploymentTemplate: 'Select Template'
            };

            let childRelationKey = object.field + '-' + object.relationshipName;

            updatedChildRelationshipResult[childRelationKey] = childObjects;

            let childDescribeResult = {
                childSObject: object.childSObject,
                field: object.field,
                relationshipName: object.relationshipName,
            };

            innerChildRelationshipsList.push(childDescribeResult);

            if (innerChildRelationshipsList.length === 1000) {
                childRelationshipsList.push(innerChildRelationshipsList);
                innerChildRelationshipsList = [];
            }
        }
    });
    childRelationshipsList.push(innerChildRelationshipsList);

    relationList.forEach((object) => {
        let relationDetail = {
            templateId: object.templateUUId,
            relationName: object.relationName,
        };

        if (object.childSObject) {
            relationDetail['childSObject'] = object.childSObject;
            childrenObjectsReferenceList.push(relationDetail);
        } else {
            parentObjectsReferenceList.push(relationDetail);
        }
    });

    let filterObject = {};
    if (filterArray) {
        filterArray.forEach((filters) => {
            filterObject = {
                order: filters.order,
                operatorSet: placeHolder,
                operator: filters.operator,
                finalValue: filters.finalValue,
                fieldName: filters.fieldName,
                fieldType: filters.fieldType,
                input: filters.input ? filters.input : placeHolder,
                numberInput: filters.numberInput ? filters.numberInput : placeHolder,
                dateInput: filters.dateInput ? filters.dateInput : placeHolder,
                dateTimeInput: filters.dateTimeInput ? filters.dateTimeInput : placeHolder
            };

            queryFilterList.push(filterObject);
        });
    }

    describeResult.fields = newDescribeFieldsResult;
    describeResult.childRelationships = [];
    describeResult.childRelationshipsList = childRelationshipsList;
    let finalMap = {
        fields: updatedDescribeFieldsResult,
        childObjects: updatedChildRelationshipResult,
        describeResult: describeResult,
        childrenObjectsReferenceList: childrenObjectsReferenceList,
        parentObjectsReferenceList: parentObjectsReferenceList,
        queryFilterList: queryFilterList
    };
    return finalMap;
}

export const updateRelationInAttchment = (dataObject) => {
        
        let contents = null;
        //let relations = [];
        let newDataTemplateDetails = {};
        let childRelationKey = {};
            contents = JSON.parse(dataObject.newDataTemplateDetail.templateDetail);
            if (dataObject.importedObject.values.relationList.length > 0) {
                if (contents.childrenObjectsReferenceList.length > 0) {
                    contents.childrenObjectsReferenceList.forEach((childrenRelation) => {
                        newDataTemplateDetails = dataObject.realDataTemplateIdMap.find((dataTemplate) => {
                            return dataTemplate.templateUUId === childrenRelation.templateId;
                        });

                        childrenRelation.templateId = newDataTemplateDetails.id;

                        let childObjectKeys = Object.keys(contents.selectableChildRelationsMap);
                        childRelationKey = childObjectKeys.find((child) => {
                            return child.endsWith(childrenRelation.relationName);
                        });

                        let newDeploymentTemplateNameMap = {
                            [newDataTemplateDetails.id]: newDataTemplateDetails.name
                        };

                        contents.selectableChildRelationsMap[childRelationKey].deploymentTemplate = newDataTemplateDetails.name;
                        contents.selectableChildRelationsMap[childRelationKey].deploymentTemplateNameMap = newDeploymentTemplateNameMap;
                    });
                }

                if (contents.parentObjectsReferenceList.length > 0) {
                    contents.parentObjectsReferenceList.forEach((parentRelation) => {
                        newDataTemplateDetails = dataObject.realDataTemplateIdMap.find((dataTemplate) => {
                            return dataTemplate.templateUUId === parentRelation.templateId;
                        });

                        parentRelation.templateId = newDataTemplateDetails.id;
                        let newDeploymentTemplateNameMap = {
                            [newDataTemplateDetails.id]: newDataTemplateDetails.name
                        };

                        contents.selectableFieldsMap[parentRelation.relationName].deploymentTemplate = newDataTemplateDetails.name;
                        contents.selectableFieldsMap[parentRelation.relationName].deploymentTemplateNameMap = newDeploymentTemplateNameMap;
                    });
                }
            }
    return contents
}