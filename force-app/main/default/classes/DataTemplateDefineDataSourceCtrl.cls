public with sharing class DataTemplateDefineDataSourceCtrl {
    @TestVisible
    private static final String ADD_DESCRIBE_GLOBAL = 'ADD_Describe_Global_Result';

    private static List<String> disabledObjects {
        get {
            if (disabledObjects == null) {
                disabledObjects = new List<String>();
                for (Data_Template_Setup__mdt templateSetup : [
                    SELECT Id, API_Names__c
                    FROM Data_Template_Setup__mdt
                    WHERE DeveloperName = 'Disabled_Main_Objects'
                    LIMIT 1
                ]) {
                    if (String.isNotBlank(templateSetup.API_Names__c)) {
                        for (String name : templateSetup.API_Names__c.split(',')) {
                            disabledObjects.add(name.toLowerCase());
                        }
                    }
                }
            }
            return disabledObjects;
        }
        set {
        }
    }

    @AuraEnabled
    public static Boolean validateOrg(String orgId) {
        try {
            return ValidateOrgAction.execute(orgId);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<MainObjectOption> fetchObjects(String orgId) {
        try {
            DescribeSObjectService.DescribeGlobalResponse describerResponse = new DescribeSObjectService(orgId).getObjects();
            if (!describerResponse.success) {
                throw new ApplicationException(describerResponse.error);
            }
            updateOrgObjectsAttachment(orgId, describerResponse);
            return createObjectOptions(describerResponse);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void setDataTemplateDataSource(String recordId, String orgId, String mainObject) {
        try {
            new DataTemplateConfigurator(recordId).setSource(orgId, mainObject);
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Attachment updateOrgObjectsAttachment(String orgId, DescribeSObjectService.DescribeGlobalResponse objectsResponse) {
        Map<String, Attachment> existingAttachments = getAttachments(orgId, new Set<String>{ ADD_DESCRIBE_GLOBAL });
        Attachment result = existingAttachments.containsKey(ADD_DESCRIBE_GLOBAL)
            ? existingAttachments.get(ADD_DESCRIBE_GLOBAL)
            : createAttachment(ADD_DESCRIBE_GLOBAL, orgId);
        result.Body = Blob.valueOf(JSON.serialize(objectsResponse));
        Utilities.Secure_DML(result, Utilities.DML_Action.UPS, schema.SObjectType.Attachment);
        return result;
    }

    private static Map<String, Attachment> getAttachments(String recordId, Set<String> attachmentNames) {
        Map<String, Attachment> result = new Map<String, Attachment>();
        for (Attachment attachment : new AttachmentsSelector().byParentIdAndName(new Set<Id>{ recordId }, attachmentNames)) {
            result.put(attachment.Name, attachment);
        }
        return result;
    }

    private static Attachment createAttachment(String name, String parentId) {
        Attachment result = new Attachment();
        result.ParentId = parentId;
        result.Name = name;
        return result;
    }

    private static List<MainObjectOption> createObjectOptions(DescribeSObjectService.DescribeGlobalResponse describerResponse) {
        List<MainObjectOption> result = new List<MainObjectOption>();
        if (!describerResponse.sobjects?.isEmpty()) {
            for (DescribeSObjectService.CopadoObject copadoObject : describerResponse.sobjects) {
                if (isObjectNotAllowed(copadoObject)) {
                    continue;
                }
                result.add(new MainObjectOption(copadoObject.label + ' (' + copadoObject.name + ')', copadoObject.name));
            }
        }
        return result;
    }

    private static Boolean isObjectNotAllowed(DescribeSObjectService.CopadoObject copadoObject) {
        String name = copadoObject.name.toLowerCase();
        return name.endsWithIgnoreCase('history') ||
            name.endsWithIgnoreCase('tag') ||
            name.endsWithIgnoreCase('share') ||
            name.endsWithIgnoreCase('feed') ||
            name.endsWithIgnoreCase('changeevent') ||
            name.endsWithIgnoreCase('__mdt') ||
            name.endsWithIgnoreCase('__e') ||
            disabledObjects?.contains(name) ||
            !copadoObject.triggerable;
    }

    public with sharing class MainObjectOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        public MainObjectOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}