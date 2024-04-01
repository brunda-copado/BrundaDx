public with sharing class Files {
    private Boolean deleteContent = true;

    // PUBLIC

    public Files deleteContent(Boolean deleteContent) {
        this.deleteContent = deleteContent;
        return this;
    }

    public Id upsertFile(Id parentId, String name, String content) {
        Id result;

        Set<Id> contentDocumentIds = contentDocumentIds(parentId, name);
        if (!contentDocumentIds.isEmpty()) {
            Boolean fileCanBeDeleted = new ContentDocumentPermissionManager(contentDocumentIds).canDelete(contentDocumentIds);
            if (fileCanBeDeleted && deleteContent) {
                deleteContentDocuments(contentDocumentIds);
                result = createNewDocumentWithLink(name, content, parentId);
            } else {
                Id contentDocumentId = contentDocumentIds.iterator().next();
                result = createNewVersion(name, content, contentDocumentId);
            }
        } else {
            result = createNewDocumentWithLink(name, content, parentId);
        }

        return result;
    }

    public void deleteFile(Id parentId, String name) {
        deleteContentDocuments(contentDocumentIds(parentId, name));
    }

    public void deleteContentDocument(Id contentDocumentId) {
        deleteContentDocuments(new Set<Id>{contentDocumentId});
    }

    // PRIVATE

    private Set<Id> contentDocumentIds(Id parentId, String name) {
        Set<Id> result = new Set<Id>();

        for (ContentDocumentLink cdl : new ContentDocumentLinksSelector().byLinkedEntityId(new Set<Id>{ parentId })) {
            result.add(cdl.ContentDocumentId);
        }

        for (ContentVersion version : new ContentVersionsSelector().byContentDocumentId(result)) {
            if (version.PathOnClient != name) {
                result.remove(version.ContentDocumentId);
            }
        }

        return result;
    }

    private void deleteContentDocuments(Set<Id> contentDocumentIds) {
        List<ContentDocument> recordsToDelete = new List<ContentDocument>();
        for (Id contentDocumentId : contentDocumentIds) {
            recordsToDelete.add(new ContentDocument(Id = contentDocumentId));
        }
        // Note: False positive since it is file
        delete recordsToDelete; // NOPMD
    }

    private Id createNewVersion(String name, String content, Id contentDocumentId) {
        ContentVersion result = new ContentVersion(
            ContentDocumentId = contentDocumentId,
            Title = name.substringBeforeLast('.'),
            PathOnClient = name,
            VersionData = Blob.valueOf(content),
            ContentLocation = 'S'
        );
        // Note: False positive since it is file
        insert result; // NOPMD
        return result.Id;
    }

    private Id createNewDocumentWithLink(String name, String content, Id parentId) {
        Id contentVersionId = createNewVersion(name, content, null);

        Id contentDocumentId = new ContentVersionsSelector().byId(new Set<Id>{ contentVersionId })[0].ContentDocumentId;

        // Note: False positive since it is file
        insert new ContentDocumentLink(LinkedEntityId = parentId, ContentDocumentId = contentDocumentId, ShareType = 'I'); // NOPMD

        return contentVersionId;
    }
}