public with sharing class SystemProperties extends fflib_SObjectDomain {
    private static Map<Integer, String> sensitivePropertyValuesToPreserveByIdx = new Map<Integer, String>();
    private final static String HIDDEN = '<HIDDEN>';

    @TestVisible
    private static Boolean disableCRUDSecurity = false;

    // CONSTRUCTOR
    @SuppressWarnings('PMD.ApexDangerousMethods')
    public SystemProperties(List<System_Property__c> records) {
        super(records);

        // Note: CRUD Security is disabled only in test context
        if (disableCRUDSecurity) {
            Configuration.disableTriggerCRUDSecurity();
        }
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new SetPropertyParents(records).execute();

        preserveSensitiveValuesForAfterTriggerAndClearValues();
    }

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new SetPropertyParents(records, (Map<Id, System_Property__c>) old).execute();

        preserveSensitiveValuesForAfterTriggerAndClearValues();
        clearPlaceholderForSensitiveRecords((Map<Id, System_Property__c>) old);
    }

    public override void onAfterInsert() {
        insertSensitiveInformationRecords(records);
        new SetSystemPropertySharing(records).execute();
    }

    public override void onAfterUpdate(Map<Id, SObject> old) {
        deleteOutdatedSensitiveInformationRecords(records, old, false);
        insertSensitiveInformationRecords(records);
        new SetSystemPropertySharing(records, (Map<Id, System_Property__c>) old).execute();
    }

    public override void onAfterDelete() {
        deleteOutdatedSensitiveInformationRecords(records, new Map<Id, System_Property__c>(), true);
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new SystemProperties(records);
        }
    }

    // preserve the senstive property values for the AFTER operations
    // and clear its value, so it is not inserted/updated
    private void preserveSensitiveValuesForAfterTriggerAndClearValues() {
        Integer recordIdx = 0;
        for (SObject s : records) {
            if (((System_Property__c) s).Is_Sensitive__c) {
                if (((System_Property__c) s).Value__c == null) {
                    s.addError(Label.ValueRequiredForSystemProperty);
                } else {
                    sensitivePropertyValuesToPreserveByIdx.put(recordIdx, ((System_Property__c) s).Value__c);
                    ((System_Property__c) s).Value__c = HIDDEN;
                }
            }
            recordIdx++;
        }
    }

    // called when updating or after deleting.
    // delete all Multi_Cloud_Sensitive_Information__c records for properties that:
    // are sensitive and we want to delete, were sensitive and are not, or properties whose value was set
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void deleteOutdatedSensitiveInformationRecords(List<System_Property__c> properties, Map<Id, SObject> oldMap, boolean isDelete) {
        Set<Id> propertyIdsWithSIRecords = new Set<Id>();
        Integer recordIdx = 0;
        for (System_Property__c property : properties) {
            System_Property__c oldProperty = (System_Property__c) oldMap.get(property.Id);
            String preservedValue = sensitivePropertyValuesToPreserveByIdx.get(recordIdx++); // retrieve the preserved value on *Before
            Boolean sensitiveInformationNeedsDeletion =
                (property.Is_Sensitive__c && isDelete) ||
                (!property.Is_Sensitive__c && (oldProperty != null && oldProperty.Is_Sensitive__c)) ||
                (property.Is_Sensitive__c && preservedValue != null);
            if (sensitiveInformationNeedsDeletion) {
                propertyIdsWithSIRecords.add(property.Id);
            }
        }
        if (!propertyIdsWithSIRecords.isEmpty()) {
            List<Multi_Cloud_Sensitive_Information__c> deleteSISRecords = [
                SELECT Id
                FROM Multi_Cloud_Sensitive_Information__c
                WHERE SystemPropertyId__c IN :propertyIdsWithSIRecords OR Name IN :propertyIdsWithSIRecords
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
            ];
            delete deleteSISRecords;
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void insertSensitiveInformationRecords(List<System_Property__c> properties) {
        List<Multi_Cloud_Sensitive_Information__c> insertSIRecords = new List<Multi_Cloud_Sensitive_Information__c>();

        integer recordIdx = 0;
        for (System_Property__c property : properties) {
            String preservedValue = sensitivePropertyValuesToPreserveByIdx.get(recordIdx++); // retrieve the preserved value on *Before
            if (!property.Is_Sensitive__c || String.isEmpty(preservedValue)) {
                continue;
            }
            // Cut values in pieces. Remember that the field of 255 chars  needs to store the ENCRYPTED
            // value (~35% longer than the original), so we split by 150, to avoid string too long exceptions
            integer chunkCount = 0;
            for (integer i = 0; i < preservedValue.length(); i += 150) {
                Multi_Cloud_Sensitive_Information__c r = new Multi_Cloud_Sensitive_Information__c(
                    Name = property.Id + ' ' + ('0000' + (chunkCount++)).right(4),
                    SystemPropertyId__c = property.Id,
                    Value__c = DeployAPI.encryptAPIKey(preservedValue.substring(i, Math.min(i + 150, preservedValue.length())))
                );
                insertSIRecords.add(r);
            }
        }
        insert insertSIRecords;
    }

    private void clearPlaceholderForSensitiveRecords(Map<Id, System_Property__c> old) {
        for (SObject property : records) {
            if (
                old?.get(property.Id).Is_Sensitive__c &&
                !((System_Property__c) property).Is_Sensitive__c &&
                ((System_Property__c) property).Value__c == HIDDEN
            ) {
                ((System_Property__c) property).Value__c = null;
            }
        }
    }

    // NOTE: to be used only in SystemPropertiesSelector.cls
    // Read and decrypte the value of any hidden system property in the required list
    public static Map<String, System_Property__c> fetchDecryptedValues(List<System_Property__c> properties) {
        Map<String, System_Property__c> propertiesById = new Map<String, System_Property__c>(properties);
        Map<String, System_Property__c> propertiesByUId = new Map<String, System_Property__c>();
        for (System_Property__c property : propertiesById.values()) {
            propertiesByUId.put(property.UID__c, property);
        }

        // expects Name IN ( 'a1c7Q000000gaZ4QAI', 'a1c7Q000000gaZ4QAI' ) due to legacy behavior
        // or SystemPropertyId__c IN ('a1c7Q000000gaZ4QAI', 'a1c7Q000000gaZ4QAI' ) and Name = 'a1c7Q000000gaZ4QAI 0000', 'a1c7Q000000gaZ4QAI 0001', ... 'a1c7Q000000gaZ4QAI 9999'
        // whoever creates the Multi_Cloud_Sensitive_Information__c records must split using the same algorithm
        // and must add to the Name the sequence padded with zeroes and up to 9999 ( storage limit per sensitive property = 249kb )
        List<Multi_Cloud_Sensitive_Information__c> sis = [
            SELECT SystemPropertyId__c, Name, Value__c
            FROM Multi_Cloud_Sensitive_Information__c
            WHERE SystemPropertyId__c IN :propertiesById.keySet() OR Name IN :propertiesById.keySet()
            WITH SECURITY_ENFORCED
            ORDER BY Name ASC
        ];

        // collect the values of one or more Multi_Cloud_Sensitive_Information__c into a single System_Property__c
        // this will indirectly affect propertiesByUId, which is what we will return
        for (Multi_Cloud_Sensitive_Information__c si : sis) {
            String propertyId = String.isEmpty(si.SystemPropertyId__c) ? si.Name : si.SystemPropertyId__c;
            System_Property__c property = propertiesById.get(propertyId);
            if (!property.Is_Sensitive__c) {
                continue;
            }
            property.Value__c =
                (String.isEmpty(property.Value__c) || property.Value__c == HIDDEN ? '' : property.Value__c) + DeployAPI.decryptAPIKey(si.Value__c);
        }
        return propertiesByUId;
    }
}