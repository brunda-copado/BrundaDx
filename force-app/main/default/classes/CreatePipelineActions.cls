public with sharing class CreatePipelineActions {
    private List<Deployment_Flow__c> records;

    // CONSTRUCTOR

    public CreatePipelineActions(List<Deployment_Flow__c> records) {
        this.records = records;
    }

    // PUBLIC

    public void run() {
        try {
            List<Pipeline_Action__c> actions = new List<Pipeline_Action__c>();

            Map<String, List<MultiCloudAutomation__mdt>> automationsByPlatform = new MultiCloudAutomationsSelector().byExtensionPlatform(platforms());
            Map<String, JobTemplate__c> templates = templatesByApiName(automationsByPlatform.values());

            for (Deployment_Flow__c record : records) {
                if (!isSalesforce(record.Platform__c)) {
                    actions.addAll(pipelineActions(record.Id, automationsByPlatform.get(record.Platform__c), templates));
                }
            }

            insert Security.stripInaccessible(AccessType.CREATABLE, actions).getRecords();
        } catch (Exception error) {
            throw new ApplicationException(error.getMessage());
        }
    }

    // PRIVATE

    private Set<String> platforms() {
        Set<String> result = new Set<String>();

        for (Deployment_Flow__c record : records) {
            if (!isSalesforce(record.Platform__c)) {
                result.add(record.Platform__c);
            }
        }

        return result;
    }

    private Boolean isSalesforce(String platform) {
        return String.isBlank(platform) || platform == 'Salesforce';
    }

    private Map<String, JobTemplate__c> templatesByApiName(List<List<MultiCloudAutomation__mdt>> automations) {
        Map<String, JobTemplate__c> result = new Map<String, JobTemplate__c>();

        Set<String> names = templateApiNames(automations);

        if (!names.isEmpty()) {
            for (JobTemplate__c template : new JobTemplatesSelector().byApiName(names)) {
                result.put(template.ApiName__c, template);
            }
        }

        return result;
    }

    private Set<String> templateApiNames(List<List<MultiCloudAutomation__mdt>> automations) {
        Set<String> result = new Set<String>();

        for (List<MultiCloudAutomation__mdt> sublist : automations) {
            for (MultiCloudAutomation__mdt automation : sublist) {
                result.add(automation.Job_Template__c);
            }
        }

        return result;
    }

    private List<Pipeline_Action__c> pipelineActions(
        Id pipelineId,
        List<MultiCloudAutomation__mdt> automations,
        Map<String, JobTemplate__c> templates
    ) {
        List<Pipeline_Action__c> result = new List<Pipeline_Action__c>();

        for (MultiCloudAutomation__mdt automation : automations) {
            if (automation.Action__c != ActionConstants.SUBMIT_USER_STORIES && automation.Action__c != ActionConstants.Run_QG) {
                result.add(pipelineAction(pipelineId, automation, templates.get(automation.Job_Template__c)));
            }
        }

        return result;
    }

    private Pipeline_Action__c pipelineAction(Id pipelineId, MultiCloudAutomation__mdt automation, JobTemplate__c template) {
        return new Pipeline_Action__c(Action__c = automation.Action__c, Default__c = true, Job_Template__c = template?.Id, Pipeline__c = pipelineId);
    }
}