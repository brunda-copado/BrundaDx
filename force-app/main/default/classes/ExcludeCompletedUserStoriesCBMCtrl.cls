public with sharing class ExcludeCompletedUserStoriesCBMCtrl {

    private final static String SELECT_INNER_STRING = 'Id, Promotion__r.Completed__c, Promotion__r.Source_Environment__c, Promotion__r.Destination_Environment__c, User_Story__r.Environment__c, Promotion__r.Back_Promotion__c, Promotion__r.Status__c, Promotion__r.CreatedDate, Promotion__r.Platform__c';

    @AuraEnabled
    public static List<User_Story__c> getCompletedUserStories(String recordId){
        
        try{
            String localPipelineId = recordId;
            List<User_Story__c> behindUserStoryList = new List<User_Story__c>();
            
            Set<Id> environmentIdSet = new Set<Id>();
            for(Deployment_Flow_Step__c connection: [Select Id, Destination_Environment__c, Source_Environment__c from Deployment_Flow_Step__c Where Deployment_Flow__c =: localPipelineId WITH SECURITY_ENFORCED]) {
                environmentIdSet.add(connection.Source_Environment__c);
                environmentIdSet.add(connection.Destination_Environment__c);
            }
            
            String selectString = getSelectString();
            
            String fromString = Schema.SObjectType.User_Story__c.name;
            String whereString = 'Status__c != \'Cancelled\' AND Exclude_From_CBM__c = FALSE AND Environment__c != NULL';
            whereString += ' AND (Project__r.Deployment_Flow__c = :localPipelineId OR Release__r.Project__r.Deployment_Flow__c = :localPipelineId)';
            whereString += ' AND Id IN (';
            
            String selectInnerWhereString = 'User_Story__c';
            String fromInnerwhereString = 'Promoted_User_Story__c';
            
            String selectInnerWhereQuery = String.format(
                'SELECT {0} FROM {1} WHERE {2}',
                new List<String>{ selectInnerWhereString, fromInnerwhereString, prepareInnerWhereClause(environmentIdSet) }
            );
            whereString += selectInnerWhereQuery + ')';
            whereString += ' ORDER BY Environment__c LIMIT 50000';
            
            String mainQuery = String.format('SELECT {0} FROM {1} WHERE {2}', new List<String>{ selectString, fromString, whereString });
            
            if (Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
                behindUserStoryList = (List<User_Story__c>) Database.query(mainQuery);
            }
            // get all promoted environments for all the user stories
            Map<Id, Set<Id>> pusEnvironmentMap =  new Map<Id, Set<Id>> ();
            Map<Id, User_Story__c> pusMap = new Map<Id, User_Story__c>();
            for(User_Story__c us: behindUserStoryList){
                for (Promoted_User_Story__c promotedUserStory: us.Promoted_User_Stories__r) {
                    if(pusEnvironmentMap.containsKey(us.Id)){
                        pusEnvironmentMap.get(us.Id).add(promotedUserStory.Promotion__r.Source_Environment__c);
                        pusEnvironmentMap.get(us.Id).add(promotedUserStory.Promotion__r.Destination_Environment__c);
                    } else {
                        Set<Id> lst = new Set<Id>();
                        lst.add(promotedUserStory.Promotion__r.Source_Environment__c);
                        lst.add(promotedUserStory.Promotion__r.Destination_Environment__c);
                        pusEnvironmentMap.put(us.Id, lst);
                    }
                }
                pusMap.put(us.Id, us);
            }
            
        List<User_Story__c> usPromotedToAllEnvironments = new List<User_Story__c>();
        for(Id usId: pusEnvironmentMap.keySet()) {
        if(pusMap.containsKey(usId) && pusEnvironmentMap.get(usId).size() == environmentIdSet.size()) {
		    usPromotedToAllEnvironments.add(pusMap.get(usId));	
	    }
    }
            return usPromotedToAllEnvironments;

        } catch(Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void updateUserStoryFields(String result, String recordId) {
        try{
            List<User_Story__c> updateUserStoryList = new List<User_Story__c>();
            Set<Id> userStoryIds = new Set<Id>();
            
            for(Object storyIds : (List<Object>)JSON.deserializeUntyped(result)){
                userStoryIds.add(String.valueOf(storyIds));
            }
            
            for(User_Story__c userStory : new UserStoriesSelector().byIds(userStoryIds)) {
                userStory.Exclude_From_CBM__c = true;
                userStory.Stop_Indexing_Metadata__c = true;
                updateUserStoryList.add(userStory);
            }

            if(!updateUserStoryList.isEmpty() && 
                Schema.sObjectType.User_Story__c.fields.Exclude_From_CBM__c.isUpdateable() && 
                Schema.sObjectType.User_Story__c.fields.Stop_Indexing_Metadata__c.isUpdateable()) {

                update updateUserStoryList;
            }
        } catch(Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static String prepareInnerWhereClause(Set<Id> environmentIdSet) {
        return !environmentIdSet.isEmpty() ? '(((Promotion__r.Platform__c = NULL OR Promotion__r.Platform__c = \'Salesforce\') AND Promotion__r.Status__c = \'Completed\') OR (Promotion__r.Platform__c != \'Salesforce\' AND Promotion__r.Completed__c = TRUE))'
                                        +' AND (Promotion__r.Source_Environment__c IN :environmentIdSet'
                                        +' OR Promotion__r.Destination_Environment__c IN :environmentIdSet'
                                        +' OR User_Story__r.Environment__c IN :environmentIdSet)' : null;
    }

    private static String getSelectString() {

        String selectString = 'Id, Name, User_Story_Title__c, Environment__c, Has_Apex_Code__c, Org_Credential__c,Status__c, Sprint__c, Release__c, Last_Validation_Deployment_Status__c,Project__c,Release__r.Project__c';
        String fromInnerString = 'Promoted_User_Stories__r';
            String whereInnerString = 'Status__c != \'Outdated\' AND Promotion__r.Status__c = \'Completed\' AND (Promotion__r.Source_Environment__c IN :environmentIdSet';
            whereInnerString += ' OR Promotion__r.Destination_Environment__c IN :environmentIdSet';
            whereInnerString += ' OR User_Story__r.Environment__c IN  :environmentIdSet)';
            String selectInnerQuery = String.format(
                'SELECT {0} FROM {1} WHERE {2}',
                new List<String>{ SELECT_INNER_STRING, fromInnerString, whereInnerString }
            );

            FieldSet currentFieldSet = Schema.SObjectType.User_Story__c.fieldSets.CBM_Fields;
            String fsNamespace = currentFieldSet.getNameSpace();
            fsNamespace = fsNamespace == null ? '' : fsNamespace + '__';
            for (Schema.FieldSetMember fsm : currentFieldSet.getFields()) {
                Boolean alreadyAdded = selectString.containsIgnoreCase(fsm.getFieldPath().removeStartIgnoreCase(fsNamespace)) ? true : false;
                selectString += alreadyAdded ? '' : ', ' + fsm.getFieldPath().removeStartIgnoreCase(fsNamespace);
            }
            selectString = selectString.replace(', Is_Bundle__c','');
            if(!selectString.toLowerCase().contains('exclude_from_cbm__c')){
                selectString += ', Exclude_From_CBM__c ';
            }
            if(!selectString.toLowerCase().contains('stop_indexing_metadata__c')){
                selectString += ', Stop_Indexing_Metadata__c ';
            }
            selectString += ',(' + selectInnerQuery + ')';

            return selectString;
    }
}