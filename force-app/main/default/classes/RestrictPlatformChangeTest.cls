@isTest
public with sharing class RestrictPlatformChangeTest {
    @isTest
    private static void updateFromSalesforceToOtherAsAdmin() {
        // Setup
        User user = (User) new User_t()
            .admin()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        // Exercise
        Deployment_Flow__c pipeline;
        String errorMessage = '';

        System.runAs(user) {
            pipeline = (Deployment_Flow__c) new Pipeline().persist();

            Test.startTest();
            try {
                pipeline.Platform__c = 'Other';
                update pipeline;
            } catch (DmlException error) {
                errorMessage = error.getDmlMessage(0);
            }
            Test.stopTest();
        }

        // Verify
        pipeline = new PipelineSelector().byId(new Set<Id>{ pipeline.Id })[0];
        System.assertEquals('Salesforce', pipeline.Platform__c, 'Invalid update on Platform field.');
        System.assert(errorMessage.contains(Label.Platform_Change_Forbidden), 'Incorrect error message returned by validation.');
    }

    @isTest
    private static void updateFromOtherToSalesforceAsAdmin() {
        // Setup
        User user = (User) new User_t()
            .admin()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        // Exercise
        Deployment_Flow__c pipeline;
        String errorMessage = '';

        System.runAs(user) {
            pipeline = (Deployment_Flow__c) new Pipeline().setPlatform('Other').persist();

            Test.startTest();
            try {
                pipeline.Platform__c = 'Salesforce';
                update pipeline;
            } catch (DmlException error) {
                errorMessage = error.getDmlMessage(0);
            }
            Test.stopTest();
        }

        // Verify
        pipeline = new PipelineSelector().byId(new Set<Id>{ pipeline.Id })[0];
        System.assertEquals('Other', pipeline.Platform__c, 'Invalid update on Platform field.');
        System.assert(errorMessage.contains(Label.Platform_Change_Forbidden), 'Incorrect error message returned by validation.');
    }

    @isTest
    private static void updateFromSalesforceToOtherAsStandardUser() {
        // Setup
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        // Exercise
        Deployment_Flow__c pipeline;
        String errorMessage = '';

        System.runAs(user) {
            pipeline = (Deployment_Flow__c) new Pipeline().persist();

            Test.startTest();
            try {
                pipeline.Platform__c = 'Other';
                update pipeline;
            } catch (DmlException error) {
                errorMessage = error.getDmlMessage(0);
            }
            Test.stopTest();
        }

        // Verify
        pipeline = new PipelineSelector().byId(new Set<Id>{ pipeline.Id })[0];
        System.assertEquals('Salesforce', pipeline.Platform__c, 'Invalid update on Platform field.');
        System.assert(errorMessage.contains(Label.Platform_Change_Forbidden), 'Incorrect error message returned by validation.');
    }

    @isTest
    private static void updateFromOtherToSalesforceAsStandardUser() {
        // Setup
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        // Exercise
        Deployment_Flow__c pipeline;
        String errorMessage = '';

        System.runAs(user) {
            pipeline = (Deployment_Flow__c) new Pipeline().setPlatform('Other').persist();

            Test.startTest();
            try {
                pipeline.Platform__c = 'Salesforce';
                update pipeline;
            } catch (DmlException error) {
                errorMessage = error.getDmlMessage(0);
            }
            Test.stopTest();
        }

        // Verify
        pipeline = new PipelineSelector().byId(new Set<Id>{ pipeline.Id })[0];
        System.assertEquals('Other', pipeline.Platform__c, 'Invalid update on Platform field.');
        System.assert(errorMessage.contains(Label.Platform_Change_Forbidden), 'Incorrect error message returned by validation.');
    }
}