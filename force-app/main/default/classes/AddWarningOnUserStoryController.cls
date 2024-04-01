public with sharing class AddWarningOnUserStoryController {

    //Constants

    private static final String BLOCKING = 'blocking';
    private static final String WARNING_VARIANT = 'warning';
    private static final String TEAM_DEPENDENCY = 'Team_Dependency';
    private static final String QUERY_TEMPLATE = 'SELECT {0} FROM {1} WHERE {2} = \'\'{3}\'\' AND {4} =\'\'{5}\'\' AND {6} = false   WITH SECURITY_ENFORCED ';
    private static final String RELATIONSHIP_TYPE_FIELD = Schema.SObjectType.Team_Dependency__c.fields.Relationship_Type__c.getName();
    private static final String DEPENDENT_USER_STORY_ID = Schema.SObjectType.Team_Dependency__c.fields.Dependent_User_Story__c.getName();
    private static final String SKIP_DEPENDENCY = Schema.SObjectType.Team_Dependency__c.fields.Skip_Dependency__c.getName();
    private static final String USER_STORY_DEPENDENCY_OBJECT = Schema.SObjectType.Team_Dependency__c.getName();
    private static final Set<String> USER_STORY_DEPENDENCY_FIELDS = new Set<String> {
        Schema.SObjectType.Team_Dependency__c.fields.Id.getName(),
        Schema.SObjectType.Team_Dependency__c.fields.Name.getName()
    };

    //Non Constant

    private static Id currentUserStoryId; 
    private static String decidingField='';

    @AuraEnabled
    public static List<UIDesignHelper.AlertWrapper> getUserStoryDependenciesBlockingAlerts(String userStoryId){
        List<UIDesignHelper.AlertWrapper> alerts = new List<UIDesignHelper.AlertWrapper>();  
        currentUserStoryId=userStoryId;
        decidingField =getCustomMetadataValues(TEAM_DEPENDENCY) ;
        String queryString = getFormattedQuery();
        List<Team_Dependency__c> userStoryDependencies = Database.query(queryString);
        if(userStoryDependencies.size()>0){
            UIDesignHelper.AlertWrapper alert = new UIDesignHelper.AlertWrapper(WARNING_VARIANT,System.Label.DependencyWarning,false);
            alerts.add(alert);
        }
        return alerts;
    }

    private static String getCustomMetadataValues(String devName) {
        Copado_Setting__mdt metadataRecord = Copado_Setting__mdt.getInstance(devName);
        if(metadataRecord.Text_Field__c != null && String.isNotBlank( metadataRecord.Text_Field__c.trim())){
            return metadataRecord.Text_Field__c;
        } else{
            return SKIP_DEPENDENCY;
        }
    }

    private static String getFormattedQuery() {
        return String.format(QUERY_TEMPLATE, getParameters());
    }

    private static List<Object> getParameters() {
        return new List<Object>{ getSelectFields(USER_STORY_DEPENDENCY_FIELDS), USER_STORY_DEPENDENCY_OBJECT, RELATIONSHIP_TYPE_FIELD, BLOCKING, DEPENDENT_USER_STORY_ID,toSoqlString(currentUserStoryId), decidingField };
    }

    private static String getSelectFields(Set<String> fields) {
        return String.join(new List<String>(fields), ',');
    }

    private static String toSoqlString(String str) {
        return String.escapeSingleQuotes(str);
    }

}