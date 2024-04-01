public with sharing class InvocableGetPrefetchedVolumeLimit {

    @InvocableMethod(label='Get Pre-fetched volume limits')
    public static List<PreFetchLimit> execute() {
        Integer usedVolumes = [SELECT count() FROM PreFetchedVolumes__c WITH SYSTEM_MODE];
        Integer totalLimit = FeatureManagement.checkPackageIntegerValue('PreFetched_Volume_Limit');

        return new List<PreFetchLimit> {
            new PreFetchLimit(usedVolumes, totalLimit)
        };
    }


    public class PreFetchLimit {
        @InvocableVariable(label='Used Volumes')
        public Integer usedVolumes;
        @InvocableVariable(label='PrefetchedVolume Limit')
        public Integer totalLimit;
        @InvocableVariable(label='Available Volumes')
        public Integer availableVolumes;


        public PreFetchLimit(Integer usedVolumes, Integer totalLimit) {
            this.usedVolumes = usedVolumes;
            this.totalLimit = totalLimit;
            this.availableVolumes = totalLimit - usedVolumes;
        }
    }
}