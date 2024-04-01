public with sharing class DeploymentStepsUtils {
    @AuraEnabled
    public static void updateRecords(List<SObject> records) {
        try {
            records = Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
            update records;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getLastAttachmentBodyAsString(String name, String parentId) {
        try {
            Attachment attachment = getLastChildAttachmentByName(name, parentId);
            return attachment.Body.toString();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static String upsertAttachment(String name, String parentId, String body) {
        Attachment attachment;
        try {
            attachment = getLastChildAttachmentByName(name, parentId);
        } catch (System.QueryException e) {
            attachment = new Attachment(Name = name, ParentId = parentId);
        }
        attachment.Body = Blob.valueOf(body);
        try {
            // FALSE POSITIVE: Security.stripInaccessible removes parentId
            // causing an error and permissions over Attachment can not be controlled
            upsert attachment;
            return body;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @TestVisible
    private static Attachment getLastChildAttachmentByName(String name, String parentId) {
        return [
            SELECT Body
            FROM Attachment
            WHERE Name = :name AND parentId = :parentId
            WITH SECURITY_ENFORCED
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
    }

    /**
     * TriggerType values can be Scheduled, PlatformEvent, RecordAfterSave, among others. Null means it is not automatically fired by itself.
     * NamespacePrefix will contain the namespace if the flow was installed from a package, which is ManegeableState = true
     * ProcessType can have also values Flow which means it is an screen flow, and Workflow, CustomEvent OR InvocableProcess which means it is a process builder
     */
    @AuraEnabled(cacheable=true)
    public static String getFlowsAvailableForExecution() {
        try {
            List<FlowOptionWrapper> flowOptionWrappersAvailableForExecution = new List<FlowOptionWrapper>();
            List<FlowDefinitionView> flowAvailableForExecutionLst = [ SELECT ApiName, Label, NamespacePrefix
                                                                    FROM FlowDefinitionView
                                                                    WHERE ProcessType = 'AutoLaunchedFlow' AND IsActive = TRUE AND IsTemplate = FALSE AND TriggerType = NULL];
            for (FlowDefinitionView flowAvailableForExecution : flowAvailableForExecutionLst) {
                String namespace = getFlowNamespace(flowAvailableForExecution);
                flowOptionWrappersAvailableForExecution.add(
                    new FlowOptionWrapper(namespace + flowAvailableForExecution.ApiName, namespace + flowAvailableForExecution.Label)
                );
            }
            return JSON.serialize(flowOptionWrappersAvailableForExecution);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static String getFlowNamespace(FlowDefinitionView flowDefinition) {
        return flowDefinition.NamespacePrefix != null ? flowDefinition.NamespacePrefix + '.' : '';
    }

    @TestVisible
    private with sharing class FlowOptionWrapper {
        private String flowApiName;
        private String flowLabel;

        @TestVisible
        private FlowOptionWrapper(String flowApiName, String flowLabel) {
            this.flowApiName = flowApiName;
            this.flowLabel = flowLabel;
        }
    }
}