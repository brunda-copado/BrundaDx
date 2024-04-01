public inherited sharing class ContentVersionDeleter {
    // inputs
    private Set<Id> recordIds;

    // existing data
    private Map<Id, Set<Id>> contentDocumentIdsByRecordId;
    private Map<Id, List<ContentVersion>> contentVersionsByContentDocumentId;
    private Map<Id, List<ContentDocumentLink>> contentDocumentLinksByContentDocumentId;

    // new data
    private Map<Id, ContentVersion> contentVersionsToInsertByExistingContentDocumentId;
    private List<ContentDocument> contentDocumentsToDelete;
    private List<ContentDocumentLink> contentDocumentLinksToInsert;

    public ContentVersionDeleter fromRecords(Set<Id> recordIds) {
        this.recordIds = recordIds;
        return this;
    }

    public void deleteOldVersions() {
        gatherData();

        this.contentVersionsToInsertByExistingContentDocumentId = cloneLatestContentVersions();
        Utilities.Secure_DML(
            this.contentVersionsToInsertByExistingContentDocumentId.values(),
            Utilities.DML_Action.INS,
            Schema.SObjectType.ContentVersion
        );

        this.contentDocumentLinksToInsert = cloneContentDocumentLinks();
        this.contentDocumentsToDelete = getContentDocumentsToDelete();
        Utilities.Secure_DML(this.contentDocumentLinksToInsert, Utilities.DML_Action.INS, Schema.SObjectType.ContentDocumentLink);
        Utilities.Secure_DML(this.contentDocumentsToDelete, Utilities.DML_Action.DEL, Schema.SObjectType.ContentDocument);
    }

    private void gatherData() {
        this.contentDocumentIdsByRecordId = getContentDocumentsIdByRecordId();
        Set<Id> contentDocumentIds = flatten(this.contentDocumentIdsByRecordId);
        this.contentVersionsByContentDocumentId = SalesforceFilesService.contentVersionsOfContentDocument(contentDocumentIds);
        this.contentDocumentLinksByContentDocumentId = SalesforceFilesService.contentDocumentsLinksOfContentDocument(contentDocumentIds);
    }

    private Map<Id, Set<Id>> getContentDocumentsIdByRecordId() {
        Map<Id, Set<Id>> contentDocumentIdsByRecordId = new Map<Id, Set<Id>>();
        if (this.recordIds != null) {
            contentDocumentIdsByRecordId = SalesforceFilesService.contentDocumentIdsOfRecord(this.recordIds);
        }
        return contentDocumentIdsByRecordId;
    }

    private Map<Id, ContentVersion> cloneLatestContentVersions() {
        Map<Id, ContentVersion> result = new Map<Id, ContentVersion>();
        for (Id recordId : this.contentDocumentIdsByRecordId.keySet()) {
            for (Id contentDocumentId : this.contentDocumentIdsByRecordId.get(recordId)) {
                if (this.contentVersionsByContentDocumentId.containsKey(contentDocumentId)) {
                    List<ContentVersion> contentVersions = this.contentVersionsByContentDocumentId.get(contentDocumentId);
                    if (contentVersions.size() > 1) {
                        ContentVersion latestContentVersion = SalesforceFilesService.getLatestContentVersion(contentVersions);
                        ContentVersion clonedContentVersion = cloneContentVersion(latestContentVersion);
                        result.put(contentDocumentId, clonedContentVersion);
                    }
                }
            }
        }
        return result;
    }

    private List<ContentDocument> getContentDocumentsToDelete() {
        List<ContentDocument> result = new List<ContentDocument>();

        for (Id contentDocumentId : this.contentVersionsToInsertByExistingContentDocumentId.keySet()) {
            result.add(new ContentDocument(Id = contentDocumentId));
        }

        return result;
    }

    private static ContentVersion cloneContentVersion(ContentVersion contentVersion) {
        ContentVersion result = contentVersion.clone();

        // remove references from previous version
        result.OwnerId = UserInfo.getUserId();
        result.ContentBodyId = null;
        result.ContentDocumentId = null;
        // null to set a new date, if we don't modify the previous date the user doesn't notice the file has changed
        result.ContentModifiedDate = null;

        return result;
    }

    private List<ContentDocumentLink> cloneContentDocumentLinks() {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();

        // query ContentVersion again, otherwise ContentDocumentId field is not populated
        Map<Id, ContentVersion> newContentVersionsById = new Map<Id, ContentVersion>(
            new ContentVersionsSelector().byId(new Map<Id, ContentVersion>(this.contentVersionsToInsertByExistingContentDocumentId.values()).keySet())
        );

        Map<Id, List<ContentDocumentLink>> newContentDocumentLinksByNewContentDocumentId = SalesforceFilesService.contentDocumentsLinksOfContentVersion(
            newContentVersionsById.values()
        );

        for (Id contentDocumentId : this.contentVersionsToInsertByExistingContentDocumentId.keySet()) {
            ContentVersion newContentVersion = newContentVersionsById.get(
                this.contentVersionsToInsertByExistingContentDocumentId.get(contentDocumentId).Id
            );
            Id newContentDocumentId = newContentVersion.ContentDocumentId;
            List<ContentDocumentLink> existingContentDocumentLinks = this.contentDocumentLinksByContentDocumentId.get(contentDocumentId);
            List<ContentDocumentLink> newContentDocumentLinksForNewContentDocument = newContentDocumentLinksByNewContentDocumentId.get(
                newContentDocumentId
            );
            for (ContentDocumentLink existingContentDocumentLink : existingContentDocumentLinks) {
                ContentDocumentLink clonedContentDocumentLink = existingContentDocumentLink.clone();
                clonedContentDocumentLink.ContentDocumentId = newContentDocumentId;
                // previous owner of the file will become collaborator
                if (isUserOwnershipLink(clonedContentDocumentLink)) {
                    clonedContentDocumentLink.ShareType = 'C';
                }
                Boolean linkAlreadyExists = SalesforceFilesService.contentDocumentLinkAlreadyExists(
                    clonedContentDocumentLink,
                    newContentDocumentLinksForNewContentDocument
                );
                if (!linkAlreadyExists) {
                    result.add(clonedContentDocumentLink);
                }
            }
        }

        return result;
    }

    private static Boolean isUserOwnershipLink(ContentDocumentLink contentDocumentLink) {
        return String.valueOf(contentDocumentLink.LinkedEntityId).startsWith(User.getSObjectType().getDescribe().getKeyPrefix()) &&
            contentDocumentLink.ShareType == 'I';
    }

    private static Set<Id> flatten(Map<Id, Set<Id>> collectionsByKey) {
        Set<Id> result = new Set<Id>();

        for (Set<Id> collection : collectionsByKey.values()) {
            result.addAll(collection);
        }

        return result;
    }
}