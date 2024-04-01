public with sharing class AppDetectorController {
    @AuraEnabled(cacheable=true)
    public static ApplicationContext getContext(String recordId, String platformFieldApiName) {
        ApplicationContext result;

        try {
            result = new ApplicationContext(recordId, platformFieldApiName);
        } catch (Exception e) {
            result = new ApplicationContext();
        }

        return result;
    }

    @AuraEnabled
    public static void updateDefaultAppForUser(Id newAppId) {
        try {
            // NOTE: using NavigationMixin from LWC does not update the default app for user which is needed to detect the right context
            List<UserAppInfo> userApps = getUserApps();
            if (!userApps.isEmpty()) {
                UserAppInfo defaultAppToUpdate = new UserAppInfo(Id = userApps[0].Id, AppDefinitionId = newAppId);
                DML.safeUpdate(defaultAppToUpdate, 'Failed to update default app for user');
            }
        } catch (Exception e) {
            Logger.error(newAppId, 'updateDefaultAppForUser failed', '', null, e);
        }
    }

    // PRIVATE

    private static List<UserAppInfo> getUserApps() {
        return [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
    }

    // INNER

    public inherited sharing class ApplicationContext {
        private Id recordId;
        private String platformFieldName;

        @AuraEnabled
        public Id currentAppId;

        @AuraEnabled
        public Id expectedAppId;

        @AuraEnabled
        public String platform;

        private ApplicationContext(Id recordId, String platformFieldApiName) {
            this.recordId = recordId;
            this.platformFieldName = getPlatformField(platformFieldApiName);

            this.platform = platform();
            this.currentAppId = currentAppId();
            this.expectedAppId = expectedAppId();
        }

        @SuppressWarnings('PMD.EmptyStatementBlock')
        private ApplicationContext() {
            // Note: Default constructor for cases where no default app is defined
        }

        // PRIVATE

        // Note: in case the new property is not set, try to maintain backward compatibility
        private String getPlatformField(String platformFieldApiName) {
            String result = platformFieldApiName;

            if (String.isBlank(result)) {
                Map<String, String> platformFieldByObjectName = new Map<String, String>{
                    'Artifact__c' => 'Pipeline__r.Platform__c',
                    'Artifact_Version__c' => 'Artifact__r.Pipeline__r.Platform__c'
                };
                result = platformFieldByObjectName.get(this.recordId.getSObjectType().getDescribe(SObjectDescribeOptions.FULL).getLocalName());
            }

            return result;
        }

        private String platform() {
            String result;

            if (String.isNotBlank(this.platformFieldName)) {
                String query = 'SELECT {0} FROM {1} WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1';

                String objectApiName = this.recordId.getSObjectType().getDescribe(SObjectDescribeOptions.FULL).getName();

                List<sObject> records = Database.query(String.format(query, new List<String>{ this.platformFieldName, objectApiName }));

                if (!records.isEmpty()) {
                    result = getValue(records[0], this.platformFieldName);
                }
            }

            return result;
        }

        // Note: taken from DynamicExpression
        private String getValue(SObject record, String fieldName) {
            if (record != null && fieldName.contains('.')) {
                return getValue((SObject) record?.getSobject(fieldName.substringBefore('.')), fieldName.substringAfter('.'));
            } else if (record != null) {
                return String.valueOf(record.get(fieldName));
            } else {
                return '';
            }
        }

        private Id currentAppId() {
            List<UserAppInfo> activeApps = getUserApps();
            return !activeApps.isEmpty() ? activeApps[0].AppDefinitionId : null;
        }

        private Id expectedAppId() {
            String appName = customAppNameFor(platform);
            List<AppDefinition> apps = [SELECT DurableId FROM AppDefinition WHERE DeveloperName = :appName WITH SECURITY_ENFORCED LIMIT 1];
            return !apps.isEmpty() ? apps[0].DurableId : null;
        }

        private String customAppNameFor(String platform) {
            List<ExtensionKeyValueSetting__mdt> settings = new ExtensionKeyValueSettingsSelector().byPlatformAndKey(platform, 'CustomAppName');
            return !settings.isEmpty() ? settings[0].Value__c : '';
        }
    }
}