@IsTest
public class JobTemplate extends DomainBuilder {
    public JobTemplate() {
        super(JobTemplate__c.SObjectType);
        set(JobTemplate__c.Version__c, 1);
        name('Sample');
    }

    public JobTemplate name(String value) {
        return (JobTemplate) set(JobTemplate__c.Name, value);
    }

    public JobTemplate apiName(String apiName) {
        return (JobTemplate) set(JobTemplate__c.ApiName__c, apiName);
    }

    public JobTemplate version(Integer value) {
        return (JobTemplate) set(JobTemplate__c.Version__c, value);
    }

    public JobTemplate description(String value) {
        return (JobTemplate) set(JobTemplate__c.Description__c, value);
    }

    public JobTemplate volumeOptions(String value) {
        return (JobTemplate) set(JobTemplate__c.VolumeOptions__c, value);
    }

    public JobTemplate add(JobStep step) {
        return (JobTemplate) step.setParent(JobStep__c.JobTemplate__c, this);
    }

    public JobTemplate mockAutomation(String action) {
        if (!MultiCloudAutomationsSelector.mockAutomations.containsKey('Other')) {
            MultiCloudAutomationsSelector.mockAutomations.put('Other', new List<MultiCloudAutomation__mdt>());
        }
        MultiCloudAutomationsSelector.mockAutomations.get('Other')
            .add(
                new MultiCloudAutomation__mdt(
                    MasterLabel = action,
                    DeveloperName = action,
                    Action__c = action,
                    Job_Template__c = String.valueOf(record.get(JobTemplate__c.Name)).trim().replaceAll('[^a-zA-Z0-9]+', '_').replaceAll(' ', '_') +
                        '_' +
                        String.valueOf(record.get(JobTemplate__c.Version__c))
                )
            );
        return this;
    }
}