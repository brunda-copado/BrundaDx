@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class AdditionalStep {
    @InvocableVariable
    global String state;

    @InvocableVariable
    global List<JobStep__c> preSteps = new List<JobStep__c>();

    @InvocableVariable
    global List<JobStep__c> postSteps = new List<JobStep__c>();

    global AdditionalStep(String state) {
        this.state = state;
    }

    global AdditionalStep(String state, List<JobStep__c> preSteps, List<JobStep__c> postSteps) {
        this.state = state;
        this.preSteps = preSteps;
        this.postSteps = postSteps;
    }
}