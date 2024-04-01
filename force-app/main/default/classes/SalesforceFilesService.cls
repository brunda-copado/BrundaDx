public inherited sharing class SalesforceFilesService {
    public static Map<Id, Set<Id>> contentDocumentIdsOfRecord(Set<Id> recordIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        Map<Id, List<ContentDocumentLink>> contentDocumentLinksByRecordId = contentDocumentLinksOfRecord(recordIds);

        for (Id recordId : recordIds) {
            if (!result.containsKey(recordId)) {
                result.put(recordId, new Set<Id>());
            }
            if (contentDocumentLinksByRecordId.containsKey(recordId)) {
                List<ContentDocumentLink> contentDocumentLinks = contentDocumentLinksByRecordId.get(recordId);
                for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
                    Id contentDocumentId = contentDocumentLink.ContentDocumentId;
                    result.get(recordId).add(contentDocumentId);
                }
            }
        }

        return result;
    }

    public static Map<Id, List<ContentDocumentLink>> contentDocumentLinksOfRecord(Set<Id> recordIds) {
        Map<Id, List<ContentDocumentLink>> result = new Map<Id, List<ContentDocumentLink>>();

        for (Id recordId : recordIds) {
            result.put(recordId, new List<ContentDocumentLink>());
        }
        for (ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector().byLinkedEntityId(recordIds)) {
            Id recordId = contentDocumentLink.LinkedEntityId;
            result.get(recordId).add(contentDocumentLink);
        }

        return result;
    }

    public static Map<Id, List<ContentDocumentLink>> contentDocumentsLinksOfContentDocument(Set<Id> contentDocumentIds) {
        Map<Id, List<ContentDocumentLink>> result = new Map<Id, List<ContentDocumentLink>>();

        for (Id contentDocumentId : contentDocumentIds) {
            result.put(contentDocumentId, new List<ContentDocumentLink>());
        }
        for (ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector().byContentDocumentId(contentDocumentIds)) {
            Id contentDocumentId = contentDocumentLink.ContentDocumentId;
            result.get(contentDocumentId).add(contentDocumentLink);
        }

        return result;
    }

    public static Map<Id, List<ContentDocumentLink>> contentDocumentsLinksOfContentVersion(List<ContentVersion> contentVersions) {
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentVersion contentVersion : contentVersions) {
            contentDocumentIds.add(contentVersion.ContentDocumentId);
        }

        return contentDocumentsLinksOfContentDocument(contentDocumentIds);
    }

    public static Map<Id, List<ContentVersion>> contentVersionsOfContentDocument(Set<Id> contentDocumentIds) {
        Map<Id, List<ContentVersion>> result = new Map<Id, List<ContentVersion>>();

        for (ContentVersion contentVersion : new ContentVersionsSelector().byContentDocumentId(contentDocumentIds)) {
            Id contentDocumentId = contentVersion.ContentDocumentId;
            if (!result.containsKey(contentDocumentId)) {
                result.put(contentDocumentId, new List<ContentVersion>());
            }
            result.get(contentDocumentId).add(contentVersion);
        }

        return result;
    }

    public static ContentVersion getLatestContentVersion(List<ContentVersion> contentVersions) {
        ContentVersion result;

        for (ContentVersion contentVersion : contentVersions) {
            if (contentVersion.IsLatest == true) {
                result = contentVersion;
                break;
            }
        }

        return result;
    }

    public static Boolean contentDocumentLinkAlreadyExists(ContentDocumentLink candidate, List<ContentDocumentLink> contentDocumentLinks) {
        Boolean result = false;
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            if (
                contentDocumentLink.ContentDocumentId == candidate.ContentDocumentId &&
                contentDocumentLink.LinkedEntityId == candidate.LinkedEntityId
            ) {
                result = true;
                break;
            }
        }
        return result;
    }
}