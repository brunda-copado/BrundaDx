public inherited sharing class ContentDocumentPermissionManager {
    private Set<Id> contentDocumentIds;

    private Map<Id, List<ContentDocumentLink>> contentDocumentLinksByContentDocumentId {
        get {
            if (contentDocumentLinksByContentDocumentId == null) {
                contentDocumentLinksByContentDocumentId = SalesforceFilesService.contentDocumentsLinksOfContentDocument(this.contentDocumentIds);
            }
            return contentDocumentLinksByContentDocumentId;
        }
        set;
    }

    public ContentDocumentPermissionManager(Set<Id> contentDocumentIds) {
        this.contentDocumentIds = contentDocumentIds;
    }

    public Boolean canDelete(Set<Id> contentDocumentIds) {
        Boolean result = false;

        result = userIsOwner(contentDocumentIds) || userCanDelete(contentDocumentIds);

        return result;
    }

    private Boolean userIsOwner(Set<Id> contentDocumentIds) {
        Boolean result = false;
        for (Id contentDocumentId : contentDocumentIds) {
            result = userIsOwner(contentDocumentId);
            if (result == false) {
                break;
            }
        }
        return result;
    }

    private Boolean userIsOwner(Id contentDocumentId) {
        Boolean result = false;

        for (ContentDocumentLink contentDocumentLink : getContentDocumentLinks(contentDocumentId)) {
            if (contentDocumentLink.LinkedEntityId == UserInfo.getUserId() && contentDocumentLink.ShareType == 'I') {
                result = true;
                break;
            }
        }

        return result;
    }

    private List<ContentDocumentLink> getContentDocumentLinks(Id contentDocumentId) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();
        if (this.contentDocumentLinksByContentDocumentId.containsKey(contentDocumentId)) {
            result = this.contentDocumentLinksByContentDocumentId.get(contentDocumentId);
        }
        return result;
    }

    private Boolean userCanDelete(Set<Id> contentDocumentIds) {
        Boolean result = false;
        Savepoint sp = Database.setSavepoint();
        try {
            List<ContentDocument> contentDocumentsToDelete = new List<ContentDocument>();
            for (Id contentDocumentId : contentDocumentIds) {
                ContentDocument document = new ContentDocument(Id = contentDocumentId);
                contentDocumentsToDelete.add(document);
            }
            Utilities.Secure_DML(contentDocumentsToDelete, Utilities.DML_Action.DEL, schema.SObjectType.ContentDocument);
            result = true;
        } catch (Exception e) {
            result = false;
        } finally {
            Database.rollback(sp);
        }
        return result;
    }
}