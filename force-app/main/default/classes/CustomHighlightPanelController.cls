public with sharing class CustomHighlightPanelController {
    
    @AuraEnabled(cacheable=true)
    public static List<FieldDefinition> getFieldList(Id recordId, String fieldSetName) {

        if(String.isBlank(fieldSetName)){
            return new List<FieldDefinition>();
        }
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        
        Schema.FieldSet fieldSetObj = Schema.getGlobalDescribe().get(objectApiName).getDescribe().FieldSets.getMap().get(fieldSetName);
        
        if(fieldSetObj != null){
            List<Schema.FieldSetMember> fieldSetMembers = fieldSetObj.getFields();
            List<FieldDefinition> fieldDescriptions = new List<FieldDefinition>(); 
            
            for(Schema.FieldSetMember field : fieldSetMembers) {
                FieldDefinition fieldDef = new FieldDefinition();
                fieldDef.apiFieldName = field.getFieldPath();
                if (fieldDescriptions.size() < 7){
                    fieldDescriptions.Add(fieldDef);
                }           
            } 
            
            return fieldDescriptions;
        }else{
            throw new ApplicationException(label.UnableToFindFieldset);
        }

        
    }

    @AuraEnabled(cacheable=true)
    public static String getObjectPluralName(Id recordId){
        return recordId.getSObjectType().getDescribe().getLabelPlural();
    }
    
    @AuraEnabled(cacheable=true)
    public static String getRecordTypeName(Id recordId){
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT Id, RecordTypeId FROM '+objectApiName+ ' WHERE Id = :recordId Limit 1';
        SObject sObj = Database.query(query);
        return Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfosById().get(String.valueOf(sObj.get('RecordTypeId'))).getName();
    }
    
    public class FieldDefinition {
        @AuraEnabled
        public String apiFieldName {get;set;}
    }
}