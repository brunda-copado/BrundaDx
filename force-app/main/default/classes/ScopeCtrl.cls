public with sharing class ScopeCtrl {
    @AuraEnabled(cacheable=true)
    public static ScopeData getData(Id recordId) {
        ScopeData result = new ScopeData();

        Id pipelineId = getPipeline(recordId);
        if (pipelineId != null) {
            PipelineDescriptor pipelineDescriptor = new PipelineDescriptor(pipelineId);
            result.stagesById = pipelineDescriptor.stages();
            result.environmentsById = pipelineDescriptor.environments();
        }

        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Id getPipeline(Id recordId) {
        Id result;
        Schema.sObjectType objectType = recordId.getSObjectType();
        if (objectType == Schema.SObjectType.User_Story__c.getSObjectType()) {
            User_Story__c userStory = [
                SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                FROM User_Story__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];
            result = new FindPipeline().fromObject(userStory);
        } else if (objectType == Schema.SObjectType.JobExecution__c.getSObjectType()) {
            JobExecution__c jobExecution = [SELECT Pipeline__c FROM JobExecution__c WHERE Id = :recordId WITH USER_MODE LIMIT 1];
            result = jobExecution.Pipeline__c;
        } else if (objectType == Schema.SObjectType.JobStep__c.getSObjectType()) {
            JobStep__c jobStep = [
                SELECT JobExecution__r.Pipeline__c, UserStory__r.Project__r.Deployment_Flow__c, UserStory__r.Release__r.Project__r.Deployment_Flow__c
                FROM JobStep__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];
            result = new FindPipeline().fromObject(jobStep);
        }
        return result;
    }

    public with sharing class ScopeData {
        @AuraEnabled
        public Map<Id, PipelineDescriptor.Stage> stagesById;
        @AuraEnabled
        public Map<Id, Environment__c> environmentsById;

        public ScopeData() {
            this.stagesById = new Map<Id, PipelineDescriptor.Stage>();
            this.environmentsById = new Map<Id, Environment__c>();
        }
    }
}