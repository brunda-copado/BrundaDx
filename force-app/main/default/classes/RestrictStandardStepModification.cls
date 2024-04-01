public with sharing class RestrictStandardStepModification {
    private List<JobStep__c> steps;

    // CONSTRUCTOR

    public RestrictStandardStepModification(List<JobStep__c> steps) {
        this.steps = steps;
    }

    // PUBLIC

    public void execute() {
        Logger.trace('', 'RestrictStandardStepModification.execute', 'Steps: ', steps);
        if (!isStandardEditAllowed()) {
            Map<Id, JobTemplate__c> standardTemplatesById = getStandardTemplates();

            for (JobStep__c step : steps) {
                if (standardTemplatesById.containsKey(step.JobTemplate__c)) {
                    step.addError(Label.StandardTemplateModificationNotAllowed);
                }
            }
        }
    }

    // PRIVATE

    private Map<Id, JobTemplate__c> getStandardTemplates() {
        Set<Id> templateIds = templateIds();

        return new Map<Id, JobTemplate__c>([SELECT Id FROM JobTemplate__c WHERE Id IN :templateIds AND Type__c = 'Standard' WITH SECURITY_ENFORCED]);
    }

    private Set<Id> templateIds() {
        Set<Id> result = new Set<Id>();

        for (JobStep__c step : steps) {
            result.add(step.JobTemplate__c);
        }

        return result;
    }

    private Boolean isStandardEditAllowed() {
        Settings__c setting = Settings__c.getOrgDefaults();

        return Boolean.valueOf(setting.Enable_Standard_Job_Template_Edit__c);
    }
}