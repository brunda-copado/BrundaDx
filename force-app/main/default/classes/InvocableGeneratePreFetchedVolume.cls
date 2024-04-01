public inherited sharing class InvocableGeneratePreFetchedVolume {
    public class InvocableVariables {
        @InvocableVariable(label='Git Repository Id' required=true)
        public String repoId;
        @InvocableVariable(label='Pipeline Id' required=true)
        public String pipelineId;
        @InvocableVariable(label='Number of Volumes' required=false)
        public Integer numberOfVolumes;
        @InvocableVariable(label='Volume Config' required=false)
        public String volumeConfig;
    }


    @InvocableMethod(label='Generate Pre-Fetched Volume')
    public static void execute(List<InvocableVariables> variables) {
        assertInput(variables[0]);
        Savepoint sp = Database.setSavepoint();

        try {
            fflib_SObjectDomain.getTriggerEvent(Functions.class).disableAll();
            fflib_SObjectDomain.getTriggerEvent(JobStepTrigger.class).disableAll();
            fflib_SObjectDomain.getTriggerEvent(JobTemplateTrigger.class).disableAll();

            System_Property__c systemProperty = new System_Property__c();
            systemProperty.API_Name__c = 'PreFetchedRepository';
            systemProperty.Name = 'PreFetchedRepository';
            systemProperty.Pipeline__c = variables[0].pipelineId;
            systemProperty.Value__c = variables[0].volumeConfig;

            DML.safeInsert(systemProperty, '');

            if(!prefetchFunctionExists()) {
                createPrefetchFunction();
            }

            List<String> actionNames = new List<String> { 'Commit', 'Promotion', 'PromotionDeployment'};
            addPreFetchVolumeStepsOnActionTemplates(variables[0].pipelineId, actionNames);

            new GeneratePreFetchedVolume(variables[0].repoId, variables[0].pipelineId).execute();

            fflib_SObjectDomain.getTriggerEvent(Functions.class).enableAll();
            fflib_SObjectDomain.getTriggerEvent(JobStepTrigger.class).enableAll();
            fflib_SObjectDomain.getTriggerEvent(JobTemplateTrigger.class).enableAll();
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new ApplicationException(ex.getMessage());
        }
    }


    private static Boolean prefetchFunctionExists() {
        List<Function__c> result = [SELECT Id FROM Function__c WHERE API_Name__c = 'create_prefetched_volume' WITH USER_MODE];

        return !result.isEmpty();
    }


	private static void createPrefetchFunction() {
        Function__c function = new Function__c();
        function.Type__c = 'Standard';
        function.Worker_Size__c = 'M';
        function.Callback_Type__c = 'ApexClass';
        function.Name = 'create_prefetched_volume';
        function.ApexClass__c = String.isNotBlank(Settings.ns) ? 'copado.GeneratePreFetchedVolume' : 'GeneratePreFetchedVolume';
        function.API_Name__c = 'create_prefetched_volume';
        function.Image_Name__c = 'copado-function-core:v1';
        function.Description__c = 'A generic function to prefetch and initiate a Git Repository';
        function.Parameters__c = '[ { "required" : true, "name" : "git_json", "defaultValue" : "{$Context.Repository.Credential}" }, { "name" : "volumeId", "defaultValue" : "" }, { "name" : "settingId", "defaultValue" : "" }, {"name" : "branches", "defaultValue" : "{$Context.Apex.PipelineBranches}"} ]';
        function.Script__c = script();

        insert as user function;
	}


    private static String script() {
        String result = 'mkdir -p /app/repository  \n' +
                        'cd /app/repository  \n' +
                        'git config --global core.preloadindex true || true \n' +
                        'git config --global checkout.workers 8 || true \n' +
                        'git config --global core.checkStat minimal || true \n' +
                        'git config --global core.trustctime true || true \n' +
                        'echo $branches \n' +
                        '# fetch all branches and silently ignore in case the remote branch does not exists \n'+
                        'for branch in ${branches//,/ } \n' +
                        'do \n' +
                        '    time copado-git-get $branch || true \n' +
                        'done \n' +
                        'RESULT_JSON=$(cat <<-END \n' +
                            '{ \n' +
                                '"volumeId": "${volumeId}", \n' +
                                '"settingId": "${settingId}" \n' +
                            '} \n' +
                            'END ) \n' +
                        'git config --local core.preloadindex true || true \n' +
                        'git config --local checkout.workers 8 || true \n' +
                        'git config --local core.checkStat minimal || true \n' +
                        'git config --local core.trustctime true || true \n' +
                        'copado -p "Finished" --result-data "$RESULT_JSON"';

        return result;
    }


	private static void addPreFetchVolumeStepsOnActionTemplates(Id pipelineId, List<String> actionNames) {
        List<Pipeline_Action__c> actions = [SELECT Id, Job_Template__c, Action__c, Pipeline__c FROM Pipeline_Action__c where Pipeline__c = :pipelineId AND Action__c IN :actionNames WITH USER_MODE];

        Map<Id, Boolean> hasPrefetchedStepByTemplateId = hasPrefetchedStepByTemplateId(actions);

        List<JobStep__c> prefetchVolumeSteps = new List<JobStep__c>();

        for(Pipeline_Action__c action : actions) {
            if(hasPrefetchedStepByTemplateId.get(action.Job_Template__c) != true) {
                hasPrefetchedStepByTemplateId.put(action.Job_Template__c, true);
                prefetchVolumeSteps.add(asPrefetchStep(action.Job_Template__c));
            }
        }

        DML.insertAsSystem(prefetchVolumeSteps, '');
	}


	private static JobStep__c asPrefetchStep(Id templateId) {
        String flowName = String.isNotBlank(Settings.ns) ? 'copado.Add_Pre_fetched_volume' : 'Add_Pre_fetched_volume';
        JobStep__c result = new JobStep__c();
        result.Order__c = 0;
        result.Type__c = 'Flow';
        result.JobTemplate__c = templateId;
        result.Name = 'Use Prefetched Volume';
        result.CustomType__c = 'Salesforce Flow';
        result.ConfigJson__c = '{"flowName":"' + flowName + '","parameters":[]}';

        return result;
	}

	private static Map<Id, Boolean> hasPrefetchedStepByTemplateId(List<Pipeline_Action__c> actions) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();

        Set<Id> templateIds = new Set<Id>();

        for(Pipeline_Action__c action : actions) {
            templateIds.add(action.Job_Template__c);
        }

        for(JobStep__c step : [SELECT Id, JobTemplate__c FROM JobStep__c WHERE JobTemplate__c IN :templateIds AND Name = 'Use Prefetched Volume' WITH USER_MODE]) {
            result.put(step.JobTemplate__c, true);
        }

        return result;
	}

	private static void assertInput(InvocableGeneratePreFetchedVolume.InvocableVariables input) {
        Map<String, Object> valueMap = (Map<String, Object>) JSON.deserializeUntyped(input.volumeConfig);

        Integer TWO_HOURS = 7200;
        Integer TWENTY_FOUR_HOURS = 86400;

        Integer ttl = (Integer) valueMap.get('ttl');
        Integer volumeSize = (Integer) valueMap.get('volumeSize');
        Integer volumeAmount = (Integer) valueMap.get('volumeAmount');
        List<InvocableGetPrefetchedVolumeLimit.PreFetchLimit> limits = InvocableGetPrefetchedVolumeLimit.execute();

        if(volumeSize < 2 || volumeSize > 24) {
            throw new ApplicationException('Storage size is out of range. Supported values are 2 GB to 24 GB.');
        }

        if(ttl < TWO_HOURS || ttl > TWENTY_FOUR_HOURS) {
            throw new ApplicationException('Expiration time is out of range. Supported values are 2 Hrs to 24 Hrs.');
        }

        if(volumeAmount < 1 || volumeAmount > limits[0].availableVolumes) {
            throw new ApplicationException('Amount of pre-cloned workers exceeds the limits available in the organization, Supported values are 1 to ' + limits[0].availableVolumes + ' workers.');
        }
    }
}