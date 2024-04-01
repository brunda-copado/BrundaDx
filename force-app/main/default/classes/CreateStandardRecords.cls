@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class CreateStandardRecords {
    // PUBLIC

    global static void execute(String resourceName) {
        List<StaticResource> packagedRecords = new StaticResourcesSelector().byName(resourceName);

        fflib_SObjectDomain.getTriggerEvent(Functions.class).disableAll();
        fflib_SObjectDomain.getTriggerEvent(JobStepTrigger.class).disableAll();
        fflib_SObjectDomain.getTriggerEvent(JobTemplateTrigger.class).disableAll();
        fflib_SObjectDomain.getTriggerEvent(ExtensionConfigurations.class).disableAll();

        if (!packagedRecords.isEmpty()) {
            String recordsBundleAsJSON = packagedRecords[0].Body.toString();
            if (String.isBlank(Settings.ns)) {
                recordsBundleAsJSON = recordsBundleAsJSON.replaceAll('copado__', '');
            }

            SObjectDataLoader.externalFieldByType = new SupportedObjectsSelector().all();

            SObjectDataLoader.deserialize(recordsBundleAsJSON);
        }

        fflib_SObjectDomain.getTriggerEvent(Functions.class).enableAll();
        fflib_SObjectDomain.getTriggerEvent(JobStepTrigger.class).enableAll();
        fflib_SObjectDomain.getTriggerEvent(JobTemplateTrigger.class).enableAll();
        fflib_SObjectDomain.getTriggerEvent(ExtensionConfigurations.class).enableAll();
    }

    global static String serialize(Set<Id> recordIds) {
        return SObjectDataLoader.serialize(recordIds, strategyBySObjectType());
    }

    // PRIVATE

    private static Map<Schema.SObjectType, SObjectDataLoader.SerializeConfig> strategyBySObjectType() {
        Map<Schema.SObjectType, SObjectDataLoader.SerializeConfig> result = new Map<Schema.SObjectType, SObjectDataLoader.SerializeConfig>();
        result.put(JobStep__c.getSobjectType(), new SObjectDataLoader.SerializeConfig());
        result.put(Function__c.getSobjectType(), new SObjectDataLoader.SerializeConfig());
        result.put(JobTemplate__c.getSobjectType(), new SObjectDataLoader.SerializeConfig().followChild(JobStep__c.JobTemplate__c));
        result.put(ExtensionConfiguration__c.getSobjectType(), new SObjectDataLoader.SerializeConfig());

        return result;
    }
}