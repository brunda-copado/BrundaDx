public with sharing class GlobalFindAndReplaceCtrl {
    
    @RemoteAction
    public static Id upsertFile(Id parentId, String name, String content) {
        return new Files().upsertFile(parentId, name, content);
    }

    @RemoteAction
    public static DocumentData getFile(Id parentId) {
        List<ContentDocumentLink> documentLinks = new ContentDocumentLinksSelector().byLinkedEntityIdWithRelationalFields(new Set<Id> { parentId });
        Set<Id> contentVersionIds = new Set<Id>();
        for(ContentDocumentLink documentLink : documentLinks) {
            if(documentLink.ContentDocument.Title.equals('Copado') ||
                documentLink.ContentDocument.Title.equals('Copado.yml')
            ) {
                contentVersionIds.add(documentLink.ContentDocument.LatestPublishedVersionId);
            }
        }
        List<ContentVersion> contentVersions = new ContentVersionsSelector().byId(contentVersionIds);
        for(ContentVersion contentVersion : contentVersions) {
            if((contentVersion.Title.equals('Copado') ||
                contentVersion.Title.equals('Copado.yml')) &&
                contentVersion.FileExtension.equals('yml')
            ) {
                return new DocumentData(contentVersion);
            }
        }
        return null;
    }

    public class DocumentData {

        public String name;
        public String body;

        public DocumentData(ContentVersion document) {
            this.name = document.PathOnClient;
            this.body = EncodingUtil.base64Encode(document.VersionData);
        }
    }

}