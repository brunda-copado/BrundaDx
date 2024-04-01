public with sharing class InvocableAddPrefetchedVolume {

    @InvocableMethod(label='Add Pre fetched volume')
    public static void execute(List<Id> resultIds) {
        JobStep__c step = [SELECT Id, Git_Repository__c, PipelineId__c, JobExecution__c, JobExecution__r.VolumeOptions__c FROM JobStep__c WHERE Result__c = :resultIds[0] WITH USER_MODE];

        if(!isPrefetchedVolumeEnabled(step)) {
            return;
        }

        String volumeId = getVolumeIdAndRefreshExpiredVolumes(step.Git_Repository__c, step.PipelineId__c);

        if(String.isBlank(volumeId)) {
            return;
        }

        List<CopadoFunctions.FunctionParameter> parameters = (List<CopadoFunctions.FunctionParameter>) JSON.deserialize(step.JobExecution__r.VolumeOptions__c, List<CopadoFunctions.FunctionParameter>.class);
        Map<String, CopadoFunctions.FunctionParameter> parametersByName = groupbyName(parameters);
        parametersByName.put('volumeId', new CopadoFunctions.FunctionParameter('volumeId', volumeId));

        update as User new JobExecution__c(Id = step.JobExecution__c, VolumeOptions__c = JSON.serialize(parametersByName.values()));
    }


    // PRIVATE

    private static Map<String, CopadoFunctions.FunctionParameter> groupbyName(List<CopadoFunctions.FunctionParameter> parameters) {
        Map<String, CopadoFunctions.FunctionParameter> result = new Map<String, CopadoFunctions.FunctionParameter>();

        for(CopadoFunctions.FunctionParameter parameter : parameters) {
            result.put(parameter.name, parameter);
        }

        return result;
    }

    private static String getVolumeIdAndRefreshExpiredVolumes(Id repositoryId, Id pipelineId) {
        String result;

        try {
            List<PreFetchedVolumes__c> volumes = [SELECT Id, Volume_Id__c, Expiration_Date__c FROM PreFetchedVolumes__c WHERE Pipeline_Id__c = :pipelineId WITH SYSTEM_MODE ORDER BY Expiration_Date__c];

            List<PreFetchedVolumes__c> expiredVolumes = new List<PreFetchedVolumes__c>();

            for(PreFetchedVolumes__c volume : volumes) {
                if(volume.Expiration_Date__c <= Datetime.now()) {
                    expiredVolumes.add(volume);
                } else if(volume.Volume_Id__c != null) {
                    result = volume.Volume_Id__c;
                    expiredVolumes.add(volume);
                    break;
                }
            }

            if(!expiredVolumes.isEmpty()) {
                DML.deleteAsSystem(expiredVolumes, '');
                new GeneratePreFetchedVolume(repositoryId, pipelineId).execute();
            }
        } catch (Exception ex) {
            // Note: silently ignore any exception to avoid failing the job execution
            Logger.error(pipelineId, 'getVolumeIdAndRefreshExpiredVolumes', ex.getMessage(), null, ex);
        }

        return result;
    }

    private static Boolean isPrefetchedVolumeEnabled(JobStep__c step) {
        Boolean result;

        try {
            String uid = step.PipelineId__c + '-PreFetchedRepository';
            List<System_Property__c> properties = [SELECT Id, Value__c FROM System_Property__c WHERE UID__c = :uid];
            result = !properties.isEmpty();
        } catch(Exception ex) {
            result = false;
        }

        return result;
    }
}