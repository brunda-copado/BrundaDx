@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class CustomJobStepController {
    @AuraEnabled(cacheable=true)
    public static String getNamespace() {
        try {
            return Settings.ns;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=false)
    public static JobStep__c getStep(String stepId) {
        try {
            return new JobStepsSelector().byId(stepId);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<JobStep__c> getSteps(String parentId) {
        try {
            return steps(parentId);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static Id saveStep(JobStep__c record) {
        try {
            if (String.isBlank(record.Id)) {
                record.Order__c = getOrder(record);
            }

            JobStep__c step = (JobStep__c) Security.stripInaccessible(AccessType.UPSERTABLE, new List<JobStep__c>{ record }).getRecords()[0];
            upsert step;

            return step.Id;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<TypeOption> getTypeOptions() {
        List<TypeOption> result = new List<TypeOption>();

        try {
            for (MC_Custom_Job_Step__mdt record : [
                SELECT LWC_Name__c, Platform__c, CustomType__c, NamespacePrefix
                FROM MC_Custom_Job_Step__mdt
                ORDER BY CustomType__c NULLS FIRST
            ]) {
                result.add(new TypeOption(record.CustomType__c, record.Platform__c, lwcName(record)));
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getObservationOptions() {
        List<Option> result = new List<Option>{ new Option(Label.NONE_SELECTED, '') };

        try {
            for (PicklistEntry option : JobStep__c.Resource_Observations__c.getDescribe().getPicklistValues()) {
                result.add(new Option(option.getLabel(), option.getValue()));
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getSequenceOptions() {
        List<Option> result = new List<Option>();

        try {
            for (PicklistEntry option : JobStep__c.ExecutionSequence__c.getDescribe().getPicklistValues()) {
                result.add(new Option(option.getLabel(), option.getValue()));
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean validationEnabled(String recordId) {
        try {
            ValidateChangesCtrl.isStepCreation = true;
            return ValidateChangesCtrl.getValidationSetting(recordId).validationEnabled;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    // note: currently, toLabel() is not supported by fflib_QueryFactory and it is not possible to apply it.
    // That's why a regular SOQL query is required for this use case.
    @SuppressWarnings('PMD.ApexSOQLInjection') // passing in an Id type to a dynamic binding. No risks here.
    private static List<JobStep__c> steps(Id parentId) {
        String query =
            'SELECT Name, Type__c, CustomType__c, Order__c, Result__c, Result__r.Name, Status__c, UserStory__c, Resource_Observations__c,' +
            ' JobTemplate__c, JobExecution__c, ConfigJson__c, ResultDataJson__c, toLabel(ExecutionSequence__c), ApiName__c' +
            ' FROM JobStep__c WHERE JobExecution__c = :parentId OR JobTemplate__c = :parentId OR UserStory__c = :parentId' +
            ' WITH SECURITY_ENFORCED ORDER BY';

        if (objectType(parentId) == 'User_Story__c') {
            query += ' ExecutionSequence__c ASC,';
        }

        query += ' Order__c ASC';

        return Database.query(query);
    }

    private static String objectType(Id parentId) {
        return String.isNotBlank(parentId) ? Id.valueOf(parentId).getSObjectType().getDescribe().getLocalName() : '';
    }

    private static String lwcName(MC_Custom_Job_Step__mdt config) {
        return (String.isBlank(config.NamespacePrefix) ? 'c' : config.NamespacePrefix) + ':' + config.LWC_Name__c;
    }

    private static Id parentId(JobStep__c record) {
        return String.isNotBlank(record.JobTemplate__c)
            ? record.JobTemplate__c
            : String.isNotBlank(record.JobExecution__c) ? record.JobExecution__c : record.UserStory__c;
    }

    private static Integer getOrder(JobStep__c record) {
        Integer result = 1;
        Id parentId = parentId(record);

        try {
            List<JobStep__c> steps = [
                SELECT Order__c
                FROM JobStep__c
                WHERE
                    (JobTemplate__c = :parentId
                    OR JobExecution__c = :parentId
                    OR UserStory__c = :parentId)
                    AND Order__c != NULL
                    AND ExecutionSequence__c = :record.ExecutionSequence__c
                WITH SECURITY_ENFORCED
                ORDER BY Order__c DESC
                LIMIT 1
            ];
            if (!steps.isEmpty()) {
                result = (Integer) steps[0].Order__c + 1;
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }

        return result;
    }

    public virtual class Option {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Option() {
            // empty constructor needed for child class to extend this parent class
        }

        public Option(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class TypeOption extends Option {
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String component;

        public TypeOption(String type, String platform, String component) {
            this.type = type;
            this.label = label(platform);
            this.component = component;
        }

        private String label(String platform) {
            return type + (String.isNotBlank(platform) ? ' - ' + platform : '');
        }
    }
}