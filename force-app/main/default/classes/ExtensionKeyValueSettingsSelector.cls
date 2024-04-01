public inherited sharing class ExtensionKeyValueSettingsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static List<ExtensionKeyValueSetting__mdt> mock = new List<ExtensionKeyValueSetting__mdt>();

    // PUBLIC

    public Schema.SObjectType getSObjectType() {
        return ExtensionKeyValueSetting__mdt.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ ExtensionKeyValueSetting__mdt.Key__c, ExtensionKeyValueSetting__mdt.Value__c };
    }

    public List<ExtensionKeyValueSetting__mdt> byPlatformAndKey(String platform, String key) {
        return Test.isRunningTest()
            ? filterRecords(mock, platform, key)
            : Database.query(newQueryFactory().setCondition('Extension__r.Platform__c = :platform AND Key__c = :key').setLimit(1).toSOQL());
    }

    public List<ExtensionKeyValueSetting__mdt> byKey(String key) {
        return Test.isRunningTest()
            ? filterRecords(mock, key)
            : Database.query(
                  newQueryFactory().selectFields(new List<String>{ 'Label', 'Extension__r.DeveloperName' }).setCondition('Key__c = :key').toSOQL()
              );
    }

    // PRIVATE

    private List<ExtensionKeyValueSetting__mdt> filterRecords(List<ExtensionKeyValueSetting__mdt> records, String platform, String key) {
        List<ExtensionKeyValueSetting__mdt> result = new List<ExtensionKeyValueSetting__mdt>();
        for (ExtensionKeyValueSetting__mdt record : records) {
            if (record.Extension__r.Platform__c == platform && record.Key__c == key) {
                result.add(record);
            }
        }
        return result;
    }

    private List<ExtensionKeyValueSetting__mdt> filterRecords(List<ExtensionKeyValueSetting__mdt> records, String key) {
        List<ExtensionKeyValueSetting__mdt> result = new List<ExtensionKeyValueSetting__mdt>();
        for (ExtensionKeyValueSetting__mdt record : records) {
            if (record.Key__c == key) {
                result.add(record);
            }
        }
        return result;
    }
}