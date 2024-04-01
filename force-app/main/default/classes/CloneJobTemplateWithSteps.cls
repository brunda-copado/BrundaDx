public with sharing class CloneJobTemplateWithSteps {

    // PUBLIC

    @AuraEnabled
    public static Id cloneTemplate(Id templateId, JobTemplate__c newTemplate) {
        try {
            fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
                new List<SObjectType>{
                    JobTemplate__c.SObjectType,
                    JobStep__c.SObjectType
                }
            );

            JobTemplate__c existingTemplate = new JobTemplatesSelector().byIdWithSteps(templateId);
            newTemplate.Type__c = 'Custom';
            newTemplate.VolumeOptions__c = existingTemplate.VolumeOptions__c;
            uow.registerNew(newTemplate);

            for (JobStep__c step : existingTemplate.JobSteps__r) {
                JobStep__c clonedStep = step.clone();
                uow.registerNew(clonedStep, JobStep__c.JobTemplate__c, newTemplate);
            }

            uow.commitWork();

            return newTemplate.Id;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}