public with sharing class PromotionMetadatasRemovalController {
    @AuraEnabled
    public static void saveIgnoreChanges(String promotionId, String fileData) {
        try {
            new Files().deleteContent(false).upsertFile(promotionId, PromotionConstants.IGNORED_CHANGES_FILE_NAME, fileData);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<User_Story_Metadata__c> getMetadataDetails(List<Id> metadataIds) {
        return [
            SELECT Id, Action__c, ModuleDirectory__c, Type__c, Metadata_API_Name__c, User_Story__c, Name, User_Story__r.Name
            FROM User_Story_Metadata__c
            WHERE Id IN :metadataIds
            WITH USER_MODE
        ];
    }
}