public with sharing class CloneFunctionHandler {
    
    // PUBLIC

    @AuraEnabled
    public static Id cloneFunction(Id recordId, Function__c newFunction) {
        try {
            Function__c currentFunc = new FunctionsSelector().byId(recordId);

            Function__c clonedFunc = currentFunc.clone();
            clonedFunc.Name = newFunction.Name;
            clonedFunc.Type__c = 'Custom';
            clonedFunc.API_Name__c = newFunction.API_Name__c;
            clonedFunc.Description__c = newFunction.Description__c;

            DML.safeInsert(clonedFunc, 'Cloning function record failed ( CloneFunctionHandler.cloneFunction class )');

            return clonedFunc.Id;
        } catch (Exception ex) {
            Logger.error(recordId, 'CloneFunctionHandler.cloneFunction', null, newFunction, ex);
            throw new ApplicationException().auraHandled(ex);
        }
    }
}