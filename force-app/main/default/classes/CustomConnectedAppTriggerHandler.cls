public without sharing class CustomConnectedAppTriggerHandler implements ITrigger{
    public CustomConnectedAppTriggerHandler(){
    }
    
    public void bulkBefore(){
    }
    
    public void bulkAfter(){
        if(Trigger.isUpdate || Trigger.isInsert){
            new CustomConnectedAppTriggerHelper().callBackend();
        }
    }
    
    public void beforeInsert(SObject so){
    }
    
    public void beforeUpdate(SObject oldSo, SObject so){
        
    }
    public void beforeDelete(SObject so){
    }
    
    public void afterInsert(SObject so){
    }
    
    public void afterUpdate(SObject oldSo, SObject so){   
    }
    
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
        
    }
}