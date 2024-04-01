public with sharing class SetDefaultAutomationTemplate {
    /* private List<Deployment_Flow__c> pipelines;

    private static final Map<Schema.SObjectField, Schema.SObjectField> TEMPLATE_BY_PIPELINE_FIELDS = new Map<Schema.SObjectField, Schema.SObjectField>{
        Deployment_Flow__c.Deployment_Job_Template__c => MultiCloudAutomation__mdt.DeployAPIName__c,
        Deployment_Flow__c.Promotion_Job_Template__c => MultiCloudAutomation__mdt.PromoteAPIName__c
    };

    // CONSTRUCTOR

    public SetDefaultAutomationTemplate(List<Deployment_Flow__c> pipelines) {
        this.pipelines = filterNonSalesforce(pipelines);
    }

    // PUBLIC

    public void execute() {
        if (!pipelines.isEmpty()) {
            Map<String, MultiCloudAutomation__mdt> defaultTemplatesByPlatform = new MultiCloudAutomationsSelector().byPlatform(platformNames());
            Set<String> templateNames = getTemplateNames(defaultTemplatesByPlatform.values());

            Map<String, Id> jobTemplateIdByName = groupByName(
                [SELECT ApiName__c FROM JobTemplate__c WHERE ApiName__c IN :templateNames AND ApiName__c != NULL]
            );

            for (Deployment_Flow__c pipeline : pipelines) {
                MultiCloudAutomation__mdt defaultTemplates = defaultTemplatesByPlatform.get(pipeline.Platform__c);

                for (SObjectField pipelineField : TEMPLATE_BY_PIPELINE_FIELDS.keySet()) {
                    String currentTemplate = (String) pipeline.get(pipelineField);

                    if (String.isBlank(currentTemplate)) {
                        SObjectField templateField = TEMPLATE_BY_PIPELINE_FIELDS.get(pipelineField);

                        String jobTemplateName = (String) defaultTemplates?.get(templateField);
                        String jobTemplateId = (String) jobTemplateIdByName?.get(jobTemplateName);

                        pipeline.put(pipelineField, jobTemplateId);
                    }
                }
            }
        }
    }

    // PRIVATE

    private Map<String, Id> groupByName(List<JobTemplate__c> templates) {
        Map<String, Id> result = new Map<String, Id>();

        for (JobTemplate__c template : templates) {
            result.put(template.ApiName__c, template.Id);
        }

        return result;
    }

    private List<Deployment_Flow__c> filterNonSalesforce(List<Deployment_Flow__c> pipelines) {
        List<Deployment_Flow__c> result = new List<Deployment_Flow__c>();

        for (Deployment_Flow__c pipeline : pipelines) {
            if (isNonSalesforce(pipeline.Platform__c)) {
                result.add(pipeline);
            }
        }

        return result;
    }

    private Set<String> getTemplateNames(List<MultiCloudAutomation__mdt> defaultTemplates) {
        Set<String> result = new Set<String>();

        for (MultiCloudAutomation__mdt template : defaultTemplates) {
            for (SObjectField field : TEMPLATE_BY_PIPELINE_FIELDS.values()) {
                result.add((String) template.get(field));
            }
        }

        return result;
    }

    private Set<String> platformNames() {
        Set<String> result = new Set<String>();

        for (Deployment_Flow__c pipeline : pipelines) {
            result.add(pipeline.Platform__c);
        }

        return result;
    }

    private Boolean isNonSalesforce(String platform) {
        return String.isNotBlank(platform) && platform != 'Salesforce';
    } */
}