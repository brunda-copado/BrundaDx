// Note: These parameters are returned to a javascript controller so they need to be public
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class FilterComponentController {
    @AuraEnabled
    public static List<FieldListWrapper> getFields(){
        List<FieldListWrapper> fieldWrappers = new List<FieldListWrapper>();
        Map <String, Schema.SObjectField> mapOfDesiredObject = fflib_SObjectDescribe.getDescribe(FilterConstant.USER_STORY).getFieldsMap();
        for(Schema.SObjectField sObjectfield : mapOfDesiredObject.Values())
        {
            Schema.describefieldresult dfield = sObjectfield.getDescribe();
            FieldListWrapper fieldWrapperObj = new FieldListWrapper( dfield);
            fieldWrapperObj.createFieldList(dfield,mapOfDesiredObject);
            fieldWrappers.add(fieldWrapperObj);
        }
        return fieldWrappers;
    }

    @AuraEnabled
    public static List<User_Story__c> filterUserStoryRecord(String config){
        FilterConfiguration configuration =(FilterConfiguration) System.JSON.deserialize(config, FilterConfiguration.class);
        String fields = getSelectFields(configuration.selectFieldSet);
        List<User_Story__c> userStories = new List<User_Story__c>();
        List<FilterComponentQueryConfiguration> queryConfigurations = (List<FilterComponentQueryConfiguration>) System.JSON.deserialize(configuration.filterString, List<FilterComponentQueryConfiguration>.class);
        String currentLoggedInuser = UserInfo.getUserId() ;
        String query;
        if(configuration.ownerString == 'My User Stories'){
            query = 'SELECT '+String.escapeSingleQuotes(fields)+ ' FROM User_Story__c WHERE Sprint__c = \''+String.escapeSingleQuotes(configuration.recordId )+'\' AND ownerid=\''+String.escapeSingleQuotes(currentLoggedInuser )+'\'';    
        }else{
            query = 'SELECT '+ +String.escapeSingleQuotes(fields) +' FROM User_Story__c  WHERE Sprint__c = \''+String.escapeSingleQuotes(configuration.recordId )+'\'';
        }
        List<String> whereClauses = new List<String>();
        whereClauses=getWhereClauses(queryConfigurations);
        for(String stringobject : whereClauses){
            if(stringobject != '\'\''){
                query += ' AND ' +stringobject;
            }
        }
        userStories = Database.query(query + ' LIMIT '+String.escapeSingleQuotes(configuration.recordLimit ));
        return userStories;
    }

    @TestVisible
    private static  List<FieldSetMember> getFieldSetFields(String selectFieldSet) {
        String fromObject= FilterConstant.USER_STORY;
        return fflib_SObjectDescribe.getDescribe(fromObject).getFieldSets().get(selectFieldSet).getFields();
    }

    @TestVisible
    private static String getSelectFields(String selectFieldSet) {
        Set<String> fields = new Set<String>();
        for (FieldSetMember field : getFieldSetFields(selectFieldSet)) {
            String fieldToAdd = field.getFieldPath();
            if (field.getType() == DisplayType.REFERENCE) {
                if (field.getFieldPath().endsWith(DatatableConstants.CUSTOM_FIELD_PATH_END)) {
                    fieldToAdd = field.getFieldPath().replace(DatatableConstants.CUSTOM_FIELD_PATH_END, DatatableConstants.CUSTOM_REFERENCE_FIELD_NAME);
                } else if (field.getFieldPath().endsWith(DatatableConstants.ID)) {
                    // Trick to no to replace other possible appearances of 'Id' in the field name
                    fieldToAdd = field.getFieldPath() + DatatableConstants.DOUBLE_UNDERSCORE;
                    fieldToAdd = fieldToAdd.replace(DatatableConstants.ID + DatatableConstants.DOUBLE_UNDERSCORE, DatatableConstants.STANDARD_REFERENCE_FIELD_NAME);
                }
            }
            fields.add(fieldToAdd);
        }
        return String.join(new List<String>(fields), DatatableConstants.COMMA);
        
    }

    @TestVisible
    private static List<String> getWhereClauses(List<FilterComponentQueryConfiguration> queryConfigurations ){
        List<String> whereClauses = new List<String>();
        for(FilterComponentQueryConfiguration queryConfiguration :queryConfigurations){
            whereClauses.add(queryConfiguration.getWhereClause());
        }
        return whereClauses;

    }

    public class FieldListWrapper{
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldApi;
        @AuraEnabled public String type;
        @AuraEnabled public List<String> options = new List<String>(); 

        public FieldListWrapper(Schema.describefieldresult dField){
            fieldName=dfield.getLabel();
            fieldApi=dfield.getname();
            type=String.Valueof(dfield.getType());
        } 
        
        public void createFieldList(Schema.describefieldresult dfield,Map <String, Schema.SObjectField> mapOfDesiredObject){
            if(String.Valueof(dfield.getType()) ==FilterConstant.FIELDTYPE_PICKLIST){
                String fieldName = dfield.getname();
                Schema.DescribeFieldResult fieldResult = mapOfDesiredObject.get(fieldName).getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                    options.add(pickListVal.getLabel());
                }
            }else if(String.Valueof(dfield.getType()) == DatatableConstants.FIELDTYPE_REFERENCE){
                String fieldApiToAdd='';
                String fieldLabelToAdd='';
                if (dfield.getname().endsWith(DatatableConstants.CUSTOM_FIELD_PATH_END)) {
                    fieldApiToAdd = dfield.getname().replace(DatatableConstants.CUSTOM_FIELD_PATH_END, DatatableConstants.CUSTOM_REFERENCE_FIELD_NAME);
                    fieldLabelToAdd=dfield.getLabel()+' ' + DatatableConstants.NAME;
                } else if (dfield.getname().endsWith(DatatableConstants.ID)) {
                    // Trick to no to replace other possible appearances of 'Id' in the field name
                    fieldApiToAdd = dfield.getname() + DatatableConstants.DOUBLE_UNDERSCORE;
                    fieldApiToAdd = fieldApiToAdd.replace(DatatableConstants.ID + DatatableConstants.DOUBLE_UNDERSCORE, DatatableConstants.STANDARD_REFERENCE_FIELD_NAME);
                    fieldLabelToAdd=dfield.getLabel()+' ' + DatatableConstants.NAME;
                } 
                fieldApi=fieldApiToAdd;
                fieldName=fieldLabelToAdd;
            }        
        }
    }

    public class FilterConfiguration{
        @AuraEnabled
        public String filterString { get; set; }
        @AuraEnabled
        public String ownerString { get; set; }
        @AuraEnabled
        public String recordId { get; set; }
        @AuraEnabled
        public String selectFieldSet { get; set; }
        @AuraEnabled
        public String recordLimit { get; set; }

    }
}