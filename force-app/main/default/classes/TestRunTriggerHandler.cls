public with sharing class TestRunTriggerHandler implements ITrigger{
    public void bulkBefore(){
        if (Trigger.new != null) {
            TestRunTriggerHelper.prepareData(Trigger.new);
        }
    }
 
    public void bulkAfter(){
        TestRunTriggerHelper.insertTestRunSteps();
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        TestRunTriggerHelper.updateTestRunInformation(so);
    }
    
    //Not implemented

    public void afterUpdate(SObject oldSo, SObject so) {//NOPMD
    }
 
    public void afterDelete(SObject so) {//NOPMD
    }
 
    public void afterUndelete(SObject so) {//NOPMD
    }
 
    public void andFinally() {//NOPMD
    }

    public TestRunTriggerHandler() {//NOPMD
    }

    public void beforeInsert(SObject so) {//NOPMD
    }

    public void beforeDelete(SObject so) {//NOPMD
    }

    public void afterInsert(SObject so) {//NOPMD
    }
}