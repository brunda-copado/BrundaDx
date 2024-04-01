public with sharing class DataTemplateActivateTemplateCtrl {
    private static final String ID = 'id';
    private static final String REFERENCE = 'reference';
    private static final String RECORD_MATCHING = 'recordMatching';

    @AuraEnabled
    public static String activateTemplate(String recordId) {
        try {
            Boolean hasLicense = checkDataDeploymentLicense();
            if (!hasLicense) {
                return System.label.LicenseError;
            }

            Data_Template__c dataTemplate = fetchDataTemplate(recordId);

            Boolean hasObjectAndCredential = checkMainObjectAndSchemaCedential(dataTemplate);
            if (!hasObjectAndCredential) {
                return constructErrorMessage(System.label.CredentialAndMainObjectError);
            }

            Boolean hasAccessToCredential = checkAccessOfSchemacredential(dataTemplate);
            if (!hasAccessToCredential) {
                return System.label.CredentialAccessMessage;
            }

            Boolean validCredential = checkSchemaCredentialIsValid(dataTemplate);
            if (!validCredential) {
                return constructErrorMessage(System.label.SchemaCredentialInvalidMessage);
            }

            Attachment templateDetailAttachment = fetchDataTemplateDetailAttachment(dataTemplate);
            DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(
                templateDetailAttachment.Body.toString(),
                DataTemplateDetail.class
            );

            Boolean oneFieldIsSelected = checkFieldIsSelected(templateDetail);
            if (!oneFieldIsSelected) {
                return constructErrorMessage(System.label.FieldNotSelectedError);
            }

            Boolean parentObjectsValid = checkParentObjectsTemplateSelected(templateDetail);
            if (!parentObjectsValid) {
                return constructErrorMessage(System.label.ParentObjectError);
            }

            Boolean childObjectsValid = checkChildObjectsTemplateSelected(templateDetail);
            if (!childObjectsValid) {
                return constructErrorMessage(System.label.ChildObjectError);
            }

            Boolean formulaRequired = recordMatchingFormulaRequired(templateDetail, dataTemplate);
            if (formulaRequired) {
                return constructErrorMessage(System.label.RecordMatchingFormulaError);
            }

            templateDetail.dataTemplate.templateActive = true;
            dataTemplate.Active__c = true;
            templateDetailAttachment.Body = Blob.valueOf(JSON.serialize(templateDetail));

            Utilities.Secure_DML(templateDetailAttachment, Utilities.DML_Action.UPD, Schema.SObjectType.Attachment);

            return null;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Boolean checkDataDeploymentLicense() {
        LicenseHelper.automatedProcessTriggeringUserId = UserInfo.getUserId();
        return new licenseHelper().addEnabled;
    }

    private static Boolean checkMainObjectAndSchemaCedential(Data_Template__c dataTemplate) {
        return String.isNotBlank(dataTemplate.Main_Object__c) && String.isNotBlank(dataTemplate.Template_Source_Org__c);
    }

    private static Boolean checkAccessOfSchemacredential(Data_Template__c dataTemplate) {
        List<Org__c> orgs = [SELECT UserRecordAccess.HasReadAccess FROM Org__c WHERE Id = :dataTemplate.Template_Source_Org__c];
        return !orgs.isEmpty() ? orgs.get(0).UserRecordAccess.HasReadAccess : false;
    }

    private static Boolean checkSchemaCredentialIsValid(Data_Template__c dataTemplate) {
        return validOrg(dataTemplate.Template_Source_Org__c);
    }

    private static Boolean checkFieldIsSelected(DataTemplateDetail templateDetail) {
        Boolean oneFieldSelected = false;
        if (templateDetail != null && templateDetail.selectableFieldsMap != null && !templateDetail.selectableFieldsMap.isEmpty()) {
            for (DataTemplateDetail.CopadoSelectedField field : templateDetail.selectableFieldsMap.values()) {
                if (field.fieldType != ID && field.fieldType != REFERENCE && field.isSelected) {
                    oneFieldSelected = true;
                    break;
                }
            }
        }
        return oneFieldSelected;
    }

    private static Boolean checkParentObjectsTemplateSelected(DataTemplateDetail templateDetail) {
        if (templateDetail != null && templateDetail.selectableFieldsMap != null && !templateDetail.selectableFieldsMap.isEmpty()) {
            for (DataTemplateDetail.CopadoSelectedField field : templateDetail.selectableFieldsMap.values()) {
                if (field.fieldType == REFERENCE && field.isSelected) {
                    for (DataTemplateDetail.RelationTemplateDetails parentTemplate : templateDetail.parentObjectsReferenceList) {
                        if (field.name == parentTemplate.relationName && String.isBlank(parentTemplate.templateId)) {
                            return false;
                        }
                    }
                }
            }
        }
        return true;
    }

    private static Boolean checkChildObjectsTemplateSelected(DataTemplateDetail templateDetail) {
        if (templateDetail != null && templateDetail.selectableChildRelationsMap != null && !templateDetail.selectableChildRelationsMap.isEmpty()) {
            for (DataTemplateDetail.CopadoSelectedChildRelationship child : templateDetail.selectableChildRelationsMap.values()) {
                if (child.isSelected) {
                    for (DataTemplateDetail.RelationTemplateDetails childTemplate : templateDetail.childrenObjectsReferenceList) {
                        if (child.relationshipName == childTemplate.relationName && String.isBlank(childTemplate.templateId)) {
                            return false;
                        }
                    }
                }
            }
        }
        return true;
    }

    private static Boolean recordMatchingFormulaRequired(DataTemplateDetail templateDetail, Data_Template__c dataTemplate) {
        Record_Matching_Formula__c formula = getRecordMatchingFormula(dataTemplate.Main_Object__c);
        Boolean formulaUsedInContentUpdate = false;
        if (templateDetail != null && !templateDetail.selectableFieldsMap.isEmpty()) {
            for (DataTemplateDetail.CopadoSelectedField field : templateDetail.selectableFieldsMap.values()) {
                if (field.externalId && field.isSelected && field.useAsExternalId && field.fieldContentUpdate == RECORD_MATCHING) {
                    formulaUsedInContentUpdate = true;
                    break;
                }
            }
        }

        return formulaUsedInContentUpdate && formula == null;
    }

    private static Data_Template__c fetchDataTemplate(String recordId) {
        return new DataTemplatesSelector().byId(new Set<Id>{ recordId }).get(0);
    }

    private static Attachment fetchDataTemplateDetailAttachment(Data_Template__c dataTemplate) {
        return new AttachmentsSelector()
            .byParentIdAndName(new Set<Id>{ dataTemplate.Id }, new Set<String>{ DataTemplateDetail.ATTACHMENT_NAME })
            .get(0);
    }

    private static Boolean validOrg(String orgId) {
        return ValidateOrgAction.execute(orgId);
    }

    private static String constructErrorMessage(String message) {
        return System.label.TemplateActivationMessage + ' ' + message;
    }

    public static Record_Matching_Formula__c getRecordMatchingFormula(String mainObject) {
        Record_Matching_Formula__c formula;
        List<Record_Matching_Formula__c> recordMatchingFormula = [
            SELECT Id, Name, Configuration_Source_Org__c, Object__c, Hash_Formula__c, Field_1__c, Field_2__c, Field_3__c
            FROM Record_Matching_Formula__c
            WHERE Object__c = :mainObject
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (!recordMatchingFormula.isEmpty()) {
            formula = recordMatchingFormula.get(0);
        }
        return formula;
    }
}