public with sharing class GeneratePreFetchedVolume implements MCCallback, Queueable, Finalizer, Database.AllowsCallouts {
    private Id repoId;
    private Id pipelineId;
    private Map<String, Object> valueMap = new Map<String, Object>();
    private List<PreFetchedVolumes__c> prefetchedVolumes;


    // CONSTRUCTOR

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public GeneratePreFetchedVolume() {}


    public GeneratePreFetchedVolume(Id repoId, Id pipelineId) {
        this.repoId = repoId;
        this.pipelineId = pipelineId;
        List<System_Property__c> systemProperties = [SELECT Id,ParentId__c,Value__c
                                                        FROM System_Property__c
                                                        WHERE API_Name__c = 'PreFetchedRepository'
                                                        AND ParentId__c = :pipelineId
                                                        WITH USER_MODE
                                                        LIMIT 1
                                                    ];

        if(!systemProperties.isEmpty()) {
            this.valueMap = (Map<String, Object>) JSON.deserializeUntyped(systemProperties[0].Value__c.stripHtmlTags());
        }
    }


    private GeneratePreFetchedVolume(List<PreFetchedVolumes__c> prefetchedVolumes, Id pipelineId, Map<String, Object> valueMap) {
        this.valueMap = valueMap;
        this.pipelineId = pipelineId;
        this.prefetchedVolumes = prefetchedVolumes;
    }


    // PUBLIC

    public void execute() {
        Integer requestedVolumes = valueMap.containsKey('volumeAmount') ? (Integer)valueMap.get('volumeAmount') : 1;
        Integer existingVolumes = [SELECT count() from PreFetchedVolumes__c where Pipeline_Id__c = :this.pipelineId WITH SYSTEM_MODE];
        prefetchedVolumes = createPrefetchedVolumes(requestedVolumes - existingVolumes);

        if (Test.isRunningTest() || prefetchedVolumes.size() == 1) {
            CopadoFunctions.execute(asRequest(prefetchedVolumes[0].Id));
        } else {
            System.enqueueJob(this);
        }
    }


    public void execute(QueueableContext context) {
        if(prefetchedVolumes.isEmpty()) {
            return;
        }

        PreFetchedVolumes__c prefetchedVolume = prefetchedVolumes.remove(0);
        preFetchedVolume.Expiration_Date__c = Datetime.now().addSeconds(Integer.valueOf(valueMap.get('ttl')));
        update as system preFetchedVolume;

        CopadoFunctions.execute(asRequest(prefetchedVolume.Id));

        if(!prefetchedVolumes.isEmpty()) {
            System.attachFinalizer(this);
        }
    }


    public void execute(FinalizerContext ctx) {
        System.enqueueJob(this);
    }


    public void execute(Function__c function, Result__c result, String status) {
        if(status == 'Success') {
            try {
                VolumeResult volumeResult = (VolumeResult) JSON.deserialize(result.Result_Data__c, VolumeResult.class);
                PreFetchedVolumes__c volCs = [SELECT Id, Volume_Id__c FROM PreFetchedVolumes__c WHERE Id = :volumeResult.settingId WITH SYSTEM_MODE LIMIT 1];
                volCs.Volume_Id__c = volumeResult.volumeId;
                DML.updateAsSystem(volCs, '');
            } catch(Exception ex) {
                result.Status__c = 'Error';
                result.Error_Message__c = ex.getStackTraceString();
            }
        }
    }


    // PRIVATE

    private CopadoFunctions.ExecuteRequest asRequest(Id volumeId) {
        CopadoFunctions.ExecuteRequest request = new CopadoFunctions.ExecuteRequest();
        request.contextId = pipelineId;
        request.functionApiName = 'create_prefetched_volume';
        request.parameters = new List<CopadoFunctions.FunctionParameter> {
            new CopadoFunctions.FunctionParameter('volumeId', volumeId),
            new CopadoFunctions.FunctionParameter('settingId', volumeId)
        };
        request.options = new List<CopadoFunctions.FunctionParameter> {
            new CopadoFunctions.FunctionParameter('killVolume', 'false'),
            new CopadoFunctions.FunctionParameter('volumeEnabled', 'true'),
            new CopadoFunctions.FunctionParameter('volumeId', volumeId),
            new CopadoFunctions.FunctionParameter('transactionId', volumeId),
            new CopadoFunctions.FunctionParameter('volumettl', String.valueOf(valueMap.get('ttl'))),
            new CopadoFunctions.FunctionParameter('volumeSize', String.valueOf(valueMap.get('volumeSize')))
        };

        return request;
    }


    private List<PreFetchedVolumes__c> createPrefetchedVolumes(Integer count) {
        List<PreFetchedVolumes__c> result = new List<PreFetchedVolumes__c>();

        for(Integer i = 0; i < count; i++) {
            PreFetchedVolumes__c preFetchedVolume = new PreFetchedVolumes__c();
            preFetchedVolume.Pipeline_Id__c = pipelineId;
            preFetchedVolume.Name = repoId + '-' + Integer.valueof((Math.random() * 1000)) + '-' + i;
            preFetchedVolume.Expiration_Date__c = Datetime.now().addSeconds(Integer.valueOf(valueMap.get('ttl')));

            result.add(preFetchedVolume);
        }

        DML.insertAsSystem(result, '');

        return result;
    }


    private class VolumeResult {
        private String volumeId;
        private String settingId;
    }
}