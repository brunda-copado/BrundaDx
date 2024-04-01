public inherited sharing class ContentVersionsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return ContentVersion.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            ContentVersion.Id,
            ContentVersion.Checksum,
            ContentVersion.ContentBodyId,
            ContentVersion.ContentDocumentId,
            ContentVersion.ContentLocation,
            ContentVersion.ContentModifiedById,
            ContentVersion.ContentModifiedDate,
            ContentVersion.ContentSize,
            ContentVersion.ContentUrl,
            ContentVersion.Description,
            ContentVersion.ExternalDataSourceId,
            ContentVersion.ExternalDocumentInfo1,
            ContentVersion.ExternalDocumentInfo2,
            ContentVersion.FeaturedContentBoost,
            ContentVersion.FeaturedContentDate,
            ContentVersion.FileExtension,
            ContentVersion.FileType,
            ContentVersion.FirstPublishLocationId,
            ContentVersion.IsAssetEnabled,
            ContentVersion.IsLatest,
            ContentVersion.IsMajorVersion,
            ContentVersion.NegativeRatingCount,
            ContentVersion.Origin,
            ContentVersion.OwnerId,
            ContentVersion.PathOnClient,
            ContentVersion.PositiveRatingCount,
            ContentVersion.PublishStatus,
            ContentVersion.RatingCount,
            ContentVersion.ReasonForChange,
            ContentVersion.SharingOption,
            ContentVersion.SharingPrivacy,
            ContentVersion.TagCsv,
            ContentVersion.TextPreview,
            ContentVersion.Title,
            ContentVersion.VersionData,
            ContentVersion.VersionNumber,
            ContentVersion.LastModifiedDate
        };
    }

    public List<ContentVersion> byId(Set<Id> recordIds) {
        return (List<ContentVersion>) selectSObjectsById(recordIds);
    }

    public List<ContentVersion> byContentDocumentId(Set<Id> contentDocumentIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('ContentDocumentId IN :contentDocumentIds');
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }

    public List<ContentVersion> byContentDocumentIdWithLatest(Set<Id> contentDocumentIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('ContentDocumentId IN :contentDocumentIds AND isLatest = TRUE');
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }

    public List<ContentVersion> byContentDocumentIdFilteringTitles(Set<Id> contentDocumentIds, String title) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('ContentDocumentId IN :contentDocumentIds AND Title = :title AND isLatest = TRUE')
            .setOrdering(ContentVersion.LastModifiedDate, fflib_QueryFactory.SortOrder.DESCENDING)
            .addOrdering(ContentVersion.LastModifiedDate, fflib_QueryFactory.SortOrder.DESCENDING);
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }
}