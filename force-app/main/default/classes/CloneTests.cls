public with sharing class CloneTests {
    private List<Id> originUserStoryIds;
    private List<Test__c> originTests;
    private Id destinationUserStoryId;

    public CloneTests(List<Test__c> originTests, Id destinationUserStoryId) {
        this.originTests = originTests;
        this.destinationUserStoryId = destinationUserStoryId;
    }

    public void execute() {
        Map<Id, Test__c> tests = new Map<Id, Test__c>(originTests);

        Map<Id, Test__c> newTestByOldTestId = new Map<Id, Test__c>();
        List<Test__c> testsToInsert = new List<Test__c>();
        for (Test__c test : tests.values()) {
            Test__c clonedTest = test.clone(false, true, false, false);
            clonedTest.Name = String.format(Label.User_Story_Bundle_Cloned_Test_Template, new List<String>{ test.Name });
            clonedTest.User_Story__c = destinationUserStoryId;
            clonedTest = emptyInvalidFields(clonedTest);
            testsToInsert.add(clonedTest);
            newTestByOldTestId.put(test.Id, clonedTest);
        }

        if (!testsToInsert.isEmpty()) {
            DML.safeInsert(
                testsToInsert,
                String.format(
                    Label.ErrorWhileInserting,
                    new List<String>{ Test__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(), 'CloneTests.execute' }
                )
            );

            Map<Id, ContentDocumentLink> contentDocumentLinksByContentDocumentId = new Map<Id, ContentDocumentLink>();

            for (ContentDocumentLink documentLink : [
                SELECT Id, ContentDocumentId, LinkedEntityId, ShareType
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :tests.keySet()
                WITH SECURITY_ENFORCED
            ]) {
                contentDocumentLinksByContentDocumentId.put(documentLink.ContentDocumentId, documentLink);
            }

            Map<Id, ContentVersion> newContentVersionsByOldContentDocumentId = new Map<Id, ContentVersion>();
            for (ContentVersion oldVersion : [
                SELECT Id, Title, VersionData, ContentDocumentId, PathOnClient
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentLinksByContentDocumentId.keySet()
                WITH SECURITY_ENFORCED
            ]) {
                ContentVersion newVersion = new ContentVersion();
                newVersion.Title = oldVersion.Title;
                newVersion.VersionData = oldVersion.VersionData;
                newVersion.PathOnClient = oldVersion.PathOnClient;
                newContentVersionsByOldContentDocumentId.put(oldVersion.ContentDocumentId, newVersion);
            }

            if (!newContentVersionsByOldContentDocumentId.values().isEmpty()) {
                DML.safeInsert(
                    newContentVersionsByOldContentDocumentId.values(),
                    String.format(
                        Label.ErrorWhileInserting,
                        new List<String>{ ContentVersion.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(), 'CloneTests.execute' }
                    )
                );

                Set<Id> contentVersionIds = new Map<Id, ContentVersion>(newContentVersionsByOldContentDocumentId.values()).keySet();
                Map<Id, ContentVersion> newContentVersionsById = new Map<Id, ContentVersion>(
                    [
                        SELECT Id, Title, VersionData, PathOnClient, ContentDocumentId
                        FROM ContentVersion
                        WHERE Id IN :contentVersionIds
                        WITH SECURITY_ENFORCED
                    ]
                );

                Map<Id, ContentVersion> newContentVersionByOldContentDocumentId = new Map<Id, ContentVersion>();
                for (Id contentDocumentId : newContentVersionsByOldContentDocumentId.keySet()) {
                    Id newContentVersionId = newContentVersionsByOldContentDocumentId.get(contentDocumentId).Id;
                    newContentVersionByOldContentDocumentId.put(contentDocumentId, newContentVersionsById.get(newContentVersionId));
                }

                List<ContentDocumentLink> contentDocumenLinksToInsert = new List<ContentDocumentLink>();
                for (Id oldDocumentId : contentDocumentLinksByContentDocumentId.keySet()) {
                    contentDocumenLinksToInsert.add(
                        new ContentDocumentLink(
                            LinkedEntityId = newTestByOldTestId.get(contentDocumentLinksByContentDocumentId.get(oldDocumentId).LinkedEntityId).Id,
                            ContentDocumentId = newContentVersionByOldContentDocumentId.get(oldDocumentId).ContentDocumentId,
                            ShareType = contentDocumentLinksByContentDocumentId.get(oldDocumentId).ShareType
                        )
                    );
                }

                DML.safeInsert(
                    contentDocumenLinksToInsert,
                    String.format(
                        Label.ErrorWhileInserting,
                        new List<String>{
                            ContentDocumentLink.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                            'CloneTests.execute'
                        }
                    )
                );
            }
        }
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private Test__c emptyInvalidFields(Test__c test) {
        Set<String> invalidFields = new Set<String>{
            Test__c.Test_Tool__c.getDescribe().getName(),
            Test__c.LatestJobExecution__c.getDescribe().getName()
        };

        Map<String, Object> testFields = new Map<String, Object>(test.getPopulatedFieldsAsMap());
        for (String testField : invalidFields) {
            testFields.remove(testField);
        }
        return (Test__c) JSON.deserialize(JSON.serialize(testFields), Test__c.class);
    }
}