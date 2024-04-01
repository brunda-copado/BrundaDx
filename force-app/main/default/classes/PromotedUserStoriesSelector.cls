public with sharing class PromotedUserStoriesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Promoted_User_Story__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Promoted_User_Story__c.User_Story__c, Promoted_User_Story__c.Promotion__c };
    }

    public List<Promoted_User_Story__c> byId(Set<Id> ids) {
        return (List<Promoted_User_Story__c>) selectSObjectsById(ids);
    }

    public List<Promoted_User_Story__c> byPromotionId(Set<Id> ids) {
        return (List<Promoted_User_Story__c>) Database.query(selectFields().setCondition(Promoted_User_Story__c.Promotion__c + ' IN :ids').toSOQL());
    }

    public List<Promoted_User_Story__c> byPromotionAndNotExcluded(Set<Id> ids) {
        return (List<Promoted_User_Story__c>) Database.query(
            newQueryFactory().setCondition(Promoted_User_Story__c.Promotion__c + ' IN :ids AND User_Story__r.Exclude_From_CBM__c = FALSE').toSOQL()
        );
    }

    public Map<Id, List<Promoted_User_Story__c>> byUserStoryId(Set<Id> ids, Set<Id> backPromotionSourceEnvSet, String finalEnvironmentId) {
        Map<Id, List<Promoted_User_Story__c>> result = new Map<Id, List<Promoted_User_Story__c>>();
        Integer queryRowThreshold = Limits.getLimitQueryRows() - Limits.getQueryRows();

        List<Promoted_User_Story__c> promotedUserStories = (List<Promoted_User_Story__c>) Database.query(
            selectFields()
                .setCondition(
                    'Promoted_User_Story__c.User_Story__c IN :ids AND Promoted_User_Story__c.User_Story__r.Exclude_From_CBM__c = FALSE AND Status__c != \'Outdated\' AND Promotion__r.Status__c = \'Completed\' AND User_Story__r.Status__c != \'Cancelled\' AND (Promotion__r.Destination_Environment__c IN :backPromotionSourceEnvSet OR Promotion__r.Source_Environment__c IN :backPromotionSourceEnvSet OR User_Story__r.Environment__c IN :backPromotionSourceEnvSet OR Promotion__r.Destination_Environment__c =: finalEnvironmentId)'
                )
                .setLimit(queryRowThreshold)
                .toSOQL()
        );

        for (Promoted_User_Story__c record : promotedUserStories) {
            if (!result.containsKey(record.User_Story__c)) {
                result.put(record.User_Story__c, new List<Promoted_User_Story__c>());
            }
            result.get(record.User_Story__c).add(record);
        }

        return result;
    }

    public List<Promoted_User_Story__c> byPromotionIdWithFields(Set<Id> ids, Set<String> fields) {
        return new List<Promoted_User_Story__c>(
            (List<Promoted_User_Story__c>) Security.stripInaccessible(
                    AccessType.READABLE,
                    Database.query(
                        newQueryFactory()
                            .setEnforceFLS(false)
                            .selectFields(fields)
                            .setCondition(Promoted_User_Story__c.Promotion__c + ' IN :ids')
                            .toSOQL()
                    )
                )
                .getRecords()
        );
    }

    public List<Promoted_User_Story__c> byBundleUSPromotions(Set<Id> promotionIds) {
        return (List<Promoted_User_Story__c>) Database.query(
            selectFields()
                .setCondition(
                    'Promotion__c IN :promotionIds AND Promotion__r.Back_Promotion__c = FALSE AND Promotion__r.Status__c = \'Completed\' AND User_Story__r.Is_Bundle__c = TRUE AND User_Story__r.RecordType.Name = \'Utility\''
                )
                .toSOQL()
        );
    }

    private fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectFields(
                new List<String>{
                    'User_Story__r.Name',
                    'Promotion__r.CreatedDate',
                    'Promotion__r.Destination_Environment__c',
                    'Promotion__r.Source_Environment__c',
                    'Promotion__r.Destination_Org_Credential__c',
                    'Promotion__r.Back_Promotion__c',
                    'Promotion__r.Source_Org_Credential__c',
                    'Promotion__r.Order_By__c',
                    'Promotion__r.Release__r.Version__c'
                }
            );
    }
}