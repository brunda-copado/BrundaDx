public with sharing class ManualTestsAcceptanceCriteriaCtrl {
    @testVisible
    private static List<User> mockUsers;

    // PUBLIC

    @AuraEnabled
    public static void storeAcceptanceCriteria(String body, Id recordId) {
        try {
            String sObjectName = getSobjectName(recordId);

            switch on sObjectName {
                when 'ExtensionConfiguration__c' {
                    updateExtensionConfigurationInformation(recordId, body);
                }
                when 'Test__c' {
                    updateTestInformation(recordId, body);
                }
                when 'Quality_Gate_Rule_Condition__c' {
                    updateQgrcInformation(recordId, body);
                }
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static String fetchAcceptanceCriteria(Id recordId) {
        try {
            String acceptanceCriteria = '{}';

            if (recordId != null || !QualityGateRuleConditionsSelector.getMock().isEmpty()) {
                String sObjectName = getSobjectName(recordId);

                switch on sObjectName {
                    when 'ExtensionConfiguration__c' {
                        acceptanceCriteria = new ExtensionConfigurationsSelector().byIds(new Set<Id>{ recordId })[0].AcceptanceCriteria__c;
                    }
                    when 'Test__c' {
                        acceptanceCriteria = new TestsSelector().byIds(new Set<Id>{ recordId })[0].AcceptanceCriteria__c;
                    }
                    when 'Quality_Gate_Rule_Condition__c' {
                        acceptanceCriteria = new QualityGateRuleConditionsSelector().byIds(new Set<Id>{ recordId })[0].AcceptanceCriteria__c;
                    }
                }
            }

            return acceptanceCriteria;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> getRecentlyViewedUsers() {
        List<sObject> recentlyViewed;

        if (!Test.isRunningTest()) {
            recentlyViewed = [
                SELECT Name
                FROM User
                WHERE UserType = 'Standard'
                WITH SECURITY_ENFORCED
                ORDER BY LastViewedDate DESC NULLS LAST
                LIMIT 5
            ];
        } else {
            recentlyViewed = mockUsers;
        }

        List<LookupSearchResult> result = new List<LookupSearchResult>();

        for (SObject obj : recentlyViewed) {
            String name = String.valueOf(obj.get('Name'));
            String subtitle = Schema.User.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel() + ' • ' + name;
            result.add(new LookupSearchResult(obj.Id, 'User', 'standard:user', name, subtitle));
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> getRecentlyModifiedGroups() {
        List<sObject> recentlyViewed;

        if (!Test.isRunningTest()) {
            recentlyViewed = [SELECT Name FROM Group WHERE Type = 'Regular' WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC NULLS LAST LIMIT 5];
        } else {
            recentlyViewed = new List<Group>{ new Group(Name = 'Mock Group') };
        }

        List<LookupSearchResult> result = new List<LookupSearchResult>();

        for (SObject obj : recentlyViewed) {
            String name = String.valueOf(obj.get('Name'));
            String subtitle = Schema.Group.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel() + ' • ' + name;
            result.add(new LookupSearchResult(obj.Id, 'Group', 'standard:groups', name, subtitle));
        }

        return result;
    }

    // PRIVATE

    private static String getSobjectName(Id recordId) {
        if (!QualityGateRuleConditionsSelector.getMock().isEmpty()) {
            return 'Quality_Gate_Rule_Condition__c';
        } else {
            return recordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName().replace('copado__', '');
        }
    }

    private static void updateExtensionConfigurationInformation(Id recordId, String criteria) {
        ExtensionConfiguration__c extConfig = new ExtensionConfiguration__c(Id = recordId, AcceptanceCriteria__c = criteria);

        if (Schema.sObjectType.ExtensionConfiguration__c.isUpdateable()) {
            update extConfig;
        }
    }

    private static void updateTestInformation(Id recordId, String criteria) {
        Test__c testRecord = new Test__c(Id = recordId, AcceptanceCriteria__c = criteria);

        if (Schema.sObjectType.Test__c.isUpdateable()) {
            update testRecord;
        }
    }

    private static void updateQgrcInformation(Id recordId, String criteria) {
        Quality_Gate_Rule_Condition__c condition = new Quality_Gate_Rule_Condition__c(Id = recordId, AcceptanceCriteria__c = criteria);

        if (Schema.sObjectType.Quality_Gate_Rule_Condition__c.isUpdateable()) {
            update condition;
        }
    }
}