public inherited sharing class MultiCloudAutomationsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static Map<String, List<MultiCloudAutomation__mdt>> mockAutomations = new Map<String, List<MultiCloudAutomation__mdt>>();

    // PUBLIC

    public Schema.SObjectType getSObjectType() {
        return MultiCloudAutomation__mdt.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            MultiCloudAutomation__mdt.Id,
            MultiCloudAutomation__mdt.Action__c,
            MultiCloudAutomation__mdt.Platform_Configuration__c,
            MultiCloudAutomation__mdt.Job_Template__c
        };
    }

    public Map<String, List<MultiCloudAutomation__mdt>> byExtensionPlatform(Set<String> platforms) {
        Map<String, List<MultiCloudAutomation__mdt>> result = new Map<String, List<MultiCloudAutomation__mdt>>();

        List<MultiCloudAutomation__mdt> automations = Database.query(selectFields().setCondition('Platform_Configuration__r.Platform__c IN :platforms').toSOQL());

        if (Test.isRunningTest()) {
            result = includeEmptyPlatforms(platforms, mockAutomations);
        } else {
            result = includeEmptyPlatforms(platforms, groupByExtensionPlatform(automations));
        }

        return result;
    }

    // PRIVATE

    private Map<String, List<MultiCloudAutomation__mdt>> includeEmptyPlatforms(
        Set<String> platforms,
        Map<String, List<MultiCloudAutomation__mdt>> result
    ) {
        for (String platform : platforms) {
            if (!result.containsKey(platform)) {
                result.put(platform, new List<MultiCloudAutomation__mdt>());
            }
        }

        return result;
    }

    private Map<String, List<MultiCloudAutomation__mdt>> groupByExtensionPlatform(List<MultiCloudAutomation__mdt> records) {
        Map<String, List<MultiCloudAutomation__mdt>> result = new Map<String, List<MultiCloudAutomation__mdt>>();

        for (MultiCloudAutomation__mdt record : records) {
            String platform = record.Platform_Configuration__r.Platform__c;

            if (!result.containsKey(platform)) {
                result.put(platform, new List<MultiCloudAutomation__mdt>());
            }

            result.get(platform).add(record);
        }

        return result;
    }

    private fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectFields(new List<String>{ 'Action__c', 'Job_Template__c', 'Platform_Configuration__c', 'Platform_Configuration__r.Platform__c' });
    }
}