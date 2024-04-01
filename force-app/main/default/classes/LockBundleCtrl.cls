public with sharing class LockBundleCtrl {
    private static final Set<SObjectField> PREFILL_FIELDS = new Set<SObjectField>{
        User_Story__c.Release__c,
        User_Story__c.Project__c,
        User_Story__c.Environment__c,
        User_Story__c.Org_Credential__c
    };

    //PUBLIC

    @AuraEnabled(cacheable=true)
    public static Boolean isPlatformBundle(Id bundleId) {
        for (Bundled_Story__c bus : [
            SELECT Id, User_Story__r.Platform__c
            FROM Bundled_Story__c
            WHERE Package_Version__c = :bundleId
            WITH SECURITY_ENFORCED
        ]) {
            if (String.isNotBlank(bus.User_Story__r.Platform__c) && bus.User_Story__r.Platform__c != 'Salesforce') {
                return true;
            }
        }

        return false;
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldsFromFieldSet(String objectName, String fieldSet) {
        List<String> result = new List<String>();

        for (FieldSetMember field : fflib_SObjectDescribe.getDescribe(objectName).getDescribe().fieldSets.getMap().get(fieldSet).getFields()) {
            result.add(field.getFieldPath());
        }

        return result;
    }

    @AuraEnabled
    public static BundlingProcess.BundlingResult lockBundle(User_Story__c story, Id bundleId) {
        BundlingProcess.BundlingResult result;

        try {
            Boolean isPlatform = isPlatformBundle(bundleId);

            if (isPlatform) {
                Actions.ExecuteUserStoryBundleRequest request = new Actions.ExecuteUserStoryBundleRequest();
                request.packageVersionId = bundleId;
                request.bundleUserStory = story;
                Actions.ExecuteUserStoryBundleResult actionResult = Actions.UserStoryBundleService.execute(request);
                List<Id> commitIds = new List<Id>();
                if (actionResult.commitResult != null) {
                    commitIds.add(actionResult.commitResult.userStorycommit.Id);
                }
                result = new BundlingProcess.BundlingResult(actionResult.bundleUserStory.Id, bundleId, commitIds).isPlatform();
            } else {
                result = new BundlingProcess(bundleId, story).execute();
            }
        } catch (DMLException ex) {
            new ApplicationException(ex.getDMLMessage(0)).throwAuraHandled();
        } catch (Exception ex) {
            new ApplicationException(ex.getMessage()).throwAuraHandled();
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getLockedChildStories(Id version) {
        Set<String> result = new Set<String>();

        try {
            Set<Id> childStories = getBundledChildStories(version);
            for (Bundled_Story__c junction : new BundledStorySelector().byStoryIdsAndVersionStatus(childStories, new Set<String>{ 'Locked' })) {
                result.add(junction.User_Story__r.Name);
            }
        } catch (Exception ex) {
            new ApplicationException(ex.getMessage()).throwAuraHandled();
        }

        return new List<String>(result);
    }

    @AuraEnabled(cacheable=true)
    public static User_Story__c createPrefilledStory(Id version) {
        User_Story__c result = new User_Story__c();

        try {
            List<User_Story__c> stories = new UserStoriesSelector().byBundlePackageVersions(new Set<Id>{ version });

            Map<SObjectField, Set<Object>> valuesByField = Utilities.groupValuesByField(stories, PREFILL_FIELDS, false);

            result = createRecord(valuesByField);

            result.User_Story_Title__c = new ArtifactVersionsSelector().byIds(new Set<Id>{ version }).get(0).Name;

            if (result.Org_Credential__c == null) {
                result.Org_Credential__c = getDefaultOrgCred(result.Environment__c);
            }
        } catch (Exception ex) {
            new ApplicationException(ex.getMessage()).throwAuraHandled();
        }

        return result;
    }

    // PRIVATE

    private static Set<Id> getBundledChildStories(Id version) {
        return (Set<Id>) Utilities.getFieldValues(
            new BundledStorySelector().byPackageVersion(new Set<Id>{ version }),
            Bundled_Story__c.User_Story__c,
            Set<Id>.class,
            false
        );
    }

    private static User_Story__c createRecord(Map<SObjectField, Set<Object>> valuesByField) {
        User_Story__c result = new User_Story__c();

        for (SObjectField field : valuesByField.keySet()) {
            if (valuesByField.get(field).size() == 1) {
                result.put(field, new List<Object>(valuesByField.get(field))[0]);
            }
        }

        return result;
    }

    private static Id getDefaultOrgCred(Id environment) {
        Id result = null;

        List<Org__c> defaultOrg = new OrgsSelector().byEnvironmentAndIsDefault(new Set<Id>{ environment }, true);
        if (!defaultOrg.isEmpty()) {
            result = defaultOrg[0].Id;
        }

        return result;
    }
}