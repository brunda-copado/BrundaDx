public inherited sharing class ContentDocumentsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return ContentDocument.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            ContentDocument.Id,
            ContentDocument.Description,
            ContentDocument.FileExtension,
            ContentDocument.FileType,
            ContentDocument.LatestPublishedVersionId,
            ContentDocument.Title
        };
    }

    public List<ContentDocument> byId(Set<Id> recordIds) {
        return (List<ContentDocument>) selectSObjectsById(recordIds);
    }
}