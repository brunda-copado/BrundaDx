public inherited sharing class ContentDocumentLinksSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return ContentDocumentLink.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            ContentDocumentLink.Id,
            ContentDocumentLink.ContentDocumentId,
            ContentDocumentLink.LinkedEntityId,
            ContentDocumentLink.ShareType,
            ContentDocumentLink.Visibility
        };
    }

    public List<ContentDocumentLink> byLinkedEntityId(Set<Id> linkedEntityIds) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();
        // avoid implementation restriction in ContentDocumentLink using empty ids
        if (!linkedEntityIds.isEmpty()) {
            fflib_QueryFactory query = newQueryFactory().setCondition('LinkedEntityId IN :linkedEntityIds');
            configureRelatedSelector(query);
            result = (List<ContentDocumentLink>) Database.query(query.toSOQL());
        }
        return result;
    }

    public List<ContentDocumentLink> byContentDocumentId(Set<Id> contentDocumentIds) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();
        // avoid implementation restriction in ContentDocumentLink using empty ids
        if (!contentDocumentIds.isEmpty()) {
            fflib_QueryFactory query = newQueryFactory().setCondition('ContentDocumentId IN :contentDocumentIds');
            configureRelatedSelector(query);
            result = (List<ContentDocumentLink>) Database.query(query.toSOQL());
        }
        return result;
    }

    private void configureRelatedSelector(fflib_QueryFactory query) {
        fflib_SObjectSelector contentDocumentsSelector = new ContentDocumentsSelector();
        contentDocumentsSelector.configureQueryFactoryFields(query, 'ContentDocument');
    }

    public List<ContentDocumentLink> byLinkedEntityIdWithRelationalFields(Set<Id> linkedEntityIds) {
        fflib_QueryFactory query = selectFields().setCondition('LinkedEntityId IN :linkedEntityIds');
        return Database.query(query.toSOQL());
    }

    public List<ContentDocumentLink> byLinkedEntityIdAndTitles(Set<Id> linkedEntityIds, Set<String> titles) {
        return Database.query(
            newQueryFactory()
                .setCondition('LinkedEntityId IN :linkedEntityIds AND ContentDocument.Title IN :titles')
                .toSOQL()
        );
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory().selectFields(new List<String>{ 'ContentDocument.Title', 'ContentDocument.LatestPublishedVersionId' });
    }
}