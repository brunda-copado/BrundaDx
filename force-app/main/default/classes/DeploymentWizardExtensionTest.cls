@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
@IsTest
private class DeploymentWizardExtensionTest {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    @IsTest
    static void scheduleDeployLaterFailure() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Apex', 'Apex', 'Draft', 1, null, '{"testLevel":"NoTestRun","replacements":[]}');
            insert step;

            PageReference pReference = Page.DeploymentWizard;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReference);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(deployment));
            credentials[2].SFDC_Org_ID__c = 'TESTNOTEXISTING';
            credentials[2].Validated_Date__c = null;
            update credentials;
            String responseBody =
                '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
                credentials[2].sfdc_org_id__c +
                '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(responseBody, null));
            System.assertEquals(true, ext.getScheduleOptions().size() == 2);
            ext.deployment.Schedule__c = 'Deploy later';
            ext.scheduleShowDate();
            System.assert(TestMethodUtilities.hasMessage(Label.CUSTOMER_ORG_NOT_EXISTS));
            Test.stopTest();
        }
    }
    @IsTest
    static void confirmAndClose() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Apex', 'Apex', 'Draft', 1, null, '{"testLevel":"NoTestRun","replacements":[]}');
            insert step;

            PageReference pReferendce = Page.DeploymentWizard;
            pReferendce.getParameters().put('id', deployment.Id);
            pReferendce.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReferendce);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(deployment));

            String creditsJSON = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(creditsJSON, null));
            ext.deployment.Date__c = null;
            ext.deployment.Schedule__c = 'Deploy later';
            pReferendce = ext.confirmAll();
            System.assertEquals(0, ApexPages.getMessages().size());
            System.assertEquals(null, pReferendce);
            Test.stopTest();
        }
    }
    @IsTest
    static void notEnoughCredits() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c apexStep = TestDataFactory.createStep(
                deployment.Id,
                'Apex',
                'Apex',
                'Not started',
                1,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c customSettingStep = TestDataFactory.createStep(
                deployment.Id,
                'Custom Settings',
                'Custom Settings',
                'Not started',
                2,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c userStep = TestDataFactory.createStep(
                deployment.Id,
                'Users',
                'Users',
                'Not started',
                3,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c metadataStep = TestDataFactory.createStep(
                deployment.Id,
                'MetaData',
                'MetaData',
                'Not started',
                4,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c translationStep = TestDataFactory.createStep(
                deployment.Id,
                'Translations',
                'Translations',
                'Not started',
                5,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            insert new List<Step__c>{ apexStep, customSettingStep, userStep, metadataStep, translationStep };

            // Attachment creation
            String customSettingBody = '{"fromSuffix":"","toSuffix":"","settings":["Apex Test","Branch Management","Continuous Integration","Full Permission Sets step","Full Profiles step","Git Backup","Git MetaData","Org Difference","Selenium Testing","Snapshot Difference","Translations step"],"sco":"Feature (Feature__c)","csName":"Feature__c","prevRes":[{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Apex Test","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Branch Management","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Continuous Integration","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Permission Sets step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Profiles step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git Backup","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git MetaData","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Org Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Selenium Testing","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Snapshot Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Translations step","s":true}]}';
            Attachment customSettingAttachment = TestDataFactory.createAttachment('Custom Settings', customSettingStep.Id, customSettingBody);
            Attachment userAttachment = TestDataFactory.createAttachment('Users', userStep.Id, customSettingBody);
            String metadataBody = '[{"n":"MarketingProfile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Support Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Sales Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Persona_Permission_Manager","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_View","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_Manage","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"}]';
            Attachment metadataAttachment = TestDataFactory.createAttachment('MetaData', metadataStep.Id, metadataBody);
            String translationBody = '[{"t":"Translations","n":"en_US","s":true},{"t":"Translations","n":"es","s":true}]';
            Attachment translationAttachment = TestDataFactory.createAttachment('MetaData', translationStep.Id, translationBody);
            insert new List<Attachment>{ customSettingAttachment, userAttachment, metadataAttachment, translationAttachment };

            PageReference pReference = Page.DeploymentWizard;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReference);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(deployment));
            ext.deployment.Date__c = System.today().addDays(1);
            ext.deployment.Schedule__c = 'Deploy later';

            List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
            estimations = ext.getEstimations();
            System.assertEquals(1, ext.destinationOrgs.size());
            System.assertEquals(21, ext.totalEstimations);
            System.assert(estimations.size() > 0);
            System.assertEquals(1, estimations[0].credits);
            String responseBody = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":0,"credits":0,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(responseBody, null));
            ext.deployment.Schedule__c = 'Deploy now';
            ext.deployment.Date__c = System.today().addDays(0);
            ext.creditCheckAndValidations();
            ext.confirmAll();
            ext.confirm();
            ext.deployCall();
            System.assertEquals(false, ext.goToDeployment);
            Integer messageCount = ext.getPageMessageSize();
            System.assertEquals(1, messageCount);
        }
    }
    @IsTest
    static void autoRechargeNotEnabled() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Apex', 'Apex', 'Draft', 1, null, '{"testLevel":"NoTestRun","replacements":[]}');
            insert step;

            PageReference pReferendce = Page.DeploymentWizard;
            pReferendce.getParameters().put('id', deployment.Id);
            pReferendce.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReferendce);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(deployment));
            ext.deployment.Date__c = System.today();
            ext.deployment.Schedule__c = 'Deploy now';
            String responseBody = '{"' + step.Id + '":"1"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(responseBody, null));

            List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
            estimations = ext.getEstimations();
            System.assert(estimations.size() > 0);
            System.assertEquals(1, estimations[0].credits);

            // AUTO RECHARGE NOT ENABLED
            responseBody = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":1000,"credits":1348,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(responseBody, null));
            ext.creditCheckAndValidations();
            ext.confirmOutstanding();
            ext.confirm();
            ext.deployCall();
            System.assertEquals(false, ext.goToDeployment);
            Integer messageCount = ext.getPageMessageSize();
            System.assertEquals(1, messageCount);
        }
    }
    @IsTest
    static void estimateDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c apexStep = TestDataFactory.createStep(
                deployment.Id,
                'Apex',
                'Apex',
                'Not started',
                1,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c customSettingStep = TestDataFactory.createStep(
                deployment.Id,
                'Custom Settings',
                'Custom Settings',
                'Not started',
                2,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c userStep = TestDataFactory.createStep(
                deployment.Id,
                'Users',
                'Users',
                'Not started',
                3,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c metadataStep = TestDataFactory.createStep(
                deployment.Id,
                'MetaData',
                'MetaData',
                'Not started',
                4,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c translationStep = TestDataFactory.createStep(
                deployment.Id,
                'Translations',
                'Translations',
                'Not started',
                5,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c gitMetadataStep = TestDataFactory.createStep(
                deployment.Id,
                'Git MetaData',
                'Git MetaData',
                'Not started',
                6,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c deleteMetadataStep = TestDataFactory.createStep(
                deployment.Id,
                'Delete MetaData',
                'Delete MetaData',
                'Not started',
                7,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            insert new List<Step__c>{ apexStep, customSettingStep, userStep, metadataStep, translationStep, gitMetadataStep, deleteMetadataStep };

            // Attachment creation
            String customSettingBody = '{"fromSuffix":"","toSuffix":"","settings":["Apex Test","Branch Management","Continuous Integration","Full Permission Sets step","Full Profiles step","Git Backup","Git MetaData","Org Difference","Selenium Testing","Snapshot Difference","Translations step"],"sco":"Feature (Feature__c)","csName":"Feature__c","prevRes":[{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Apex Test","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Branch Management","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Continuous Integration","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Permission Sets step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Profiles step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git Backup","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git MetaData","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Org Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Selenium Testing","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Snapshot Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Translations step","s":true}]}';
            Attachment customSettingAttachment = TestDataFactory.createAttachment('Custom Settings', customSettingStep.Id, customSettingBody);
            Attachment userAttachment = TestDataFactory.createAttachment('Users', userStep.Id, customSettingBody);
            String metadataBody = '[{"n":"MarketingProfile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Support Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Sales Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Persona_Permission_Manager","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_View","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_Manage","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"}]';
            Attachment metadataAttachment = TestDataFactory.createAttachment('MetaData', metadataStep.Id, metadataBody);
            String translationBody = '[{"t":"Translations","n":"en_US","s":true},{"t":"Translations","n":"es","s":true}]';
            Attachment translationAttachment = TestDataFactory.createAttachment('MetaData', translationStep.Id, translationBody);
            String gitMetadataBody = '[';
            Integer metadataSize = 20;
            for (Integer i = 1; i <= metadataSize; i++) {
                gitMetadataBody = gitMetadataBody + '{"t":"CustomObject","n":"Account' + i + '","cmm":"updated"}';
                if (i != metadataSize) {
                    gitMetadataBody = gitMetadataBody + ',';
                }
                if (i == metadataSize) {
                    gitMetadataBody = gitMetadataBody + ']';
                }
            }
            Attachment gitMetadataAttachment = TestDataFactory.createAttachment('MetaData', gitMetadataStep.Id, gitMetadataBody);
            String deleteMetadataBody = '[';
            metadataSize = 6;
            for (Integer i = 1; i <= metadataSize; i++) {
                deleteMetadataBody = deleteMetadataBody + '{"t":"ApexClass","n":"AccountOperations' + i + '","s":true}';
                if (i != metadataSize) {
                    deleteMetadataBody = deleteMetadataBody + ',';
                }
                if (i == metadataSize) {
                    deleteMetadataBody = deleteMetadataBody + ']';
                }
            }
            Attachment deleteMetadataAttachment = TestDataFactory.createAttachment('Delete MetaData', deleteMetadataStep.Id, deleteMetadataBody);
            insert new List<Attachment>{
                customSettingAttachment,
                userAttachment,
                metadataAttachment,
                translationAttachment,
                gitMetadataAttachment,
                deleteMetadataAttachment
            };

            PageReference pReference = Page.DeploymentWizard;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReference);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(deployment));
            ext.deployment.Date__c = System.today().addDays(1);
            ext.deployment.Schedule__c = 'Deploy later';

            List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
            estimations = ext.getEstimations();
            System.assertEquals(1, ext.destinationOrgs.size());
            System.assertEquals(47, ext.totalEstimations);
            System.assert(estimations.size() > 0);
            System.assertEquals(11, estimations[1].credits);
            Test.stopTest();
        }
    }
    @IsTest
    static void deployAll() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                environments[0].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep1.Branch__c = 'dev1';
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep1.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // Promotion creation
            Promotion__c promotion = TestDataFactory.createPromotion(
                project.Id,
                credentials[2].Id,
                environments[2].Id,
                credentials[1].Id,
                environments[1].Id,
                'Draft'
            );
            insert promotion;

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c apexStep = TestDataFactory.createStep(
                deployment.Id,
                'Apex',
                'Apex',
                'Not started',
                1,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c customSettingStep = TestDataFactory.createStep(
                deployment.Id,
                'Custom Settings',
                'Custom Settings',
                'Not started',
                2,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c userStep = TestDataFactory.createStep(
                deployment.Id,
                'Users',
                'Users',
                'Not started',
                3,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c metadataStep = TestDataFactory.createStep(
                deployment.Id,
                'MetaData',
                'MetaData',
                'Not started',
                4,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            Step__c translationStep = TestDataFactory.createStep(
                deployment.Id,
                'Translations',
                'Translations',
                'Not started',
                5,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            insert new List<Step__c>{ apexStep, customSettingStep, userStep, metadataStep, translationStep };

            // Attachment creation
            String customSettingBody = '{"fromSuffix":"","toSuffix":"","settings":["Apex Test","Branch Management","Continuous Integration","Full Permission Sets step","Full Profiles step","Git Backup","Git MetaData","Org Difference","Selenium Testing","Snapshot Difference","Translations step"],"sco":"Feature (Feature__c)","csName":"Feature__c","prevRes":[{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Apex Test","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Branch Management","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Continuous Integration","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Permission Sets step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Profiles step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git Backup","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git MetaData","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Org Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Selenium Testing","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Snapshot Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Translations step","s":true}]}';
            Attachment customSettingAttachment = TestDataFactory.createAttachment('Custom Settings', customSettingStep.Id, customSettingBody);
            Attachment userAttachment = TestDataFactory.createAttachment('Users', userStep.Id, customSettingBody);
            String metadataBody = '[{"n":"MarketingProfile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Support Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Sales Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Persona_Permission_Manager","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_View","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_Manage","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"}]';
            Attachment metadataAttachment = TestDataFactory.createAttachment('MetaData', metadataStep.Id, metadataBody);
            String translationBody = '[{"t":"Translations","n":"en_US","s":true},{"t":"Translations","n":"es","s":true}]';
            Attachment translationAttachment = TestDataFactory.createAttachment('MetaData', translationStep.Id, translationBody);
            insert new List<Attachment>{ customSettingAttachment, userAttachment, metadataAttachment, translationAttachment };

            PageReference pReference = Page.DeploymentWizard;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReference);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(deployment));
            ext.deployment.Date__c = System.today().addDays(1);
            ext.deployment.Schedule__c = 'Deploy later';

            List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
            estimations = ext.getEstimations();
            System.assertEquals(1, ext.destinationOrgs.size());
            System.assertEquals(21, ext.totalEstimations);
            System.assert(estimations.size() > 0);
            System.assertEquals(1, estimations[0].credits);
            String responseBody = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":0,"credits":0,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(responseBody, null));
            ext.deployment.Schedule__c = 'Deploy now';
            ext.deployment.Date__c = System.today().addDays(0);
            ext.confirmAll();
            ext.confirm();
            ext.deployCall();
            System.assertEquals(false, ext.goToDeployment);
            Integer messageCount = ext.getPageMessageSize();
            System.assertEquals(1, messageCount);
        }
    }

    @IsTest
    static void deployAllNonSalesforcePlatform() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 3; i++) {
                Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
                environment.Platform__c = 'Other';
                environments.add(environment);
            }
            insert environments;

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            deploymentFlow.Platform__c = 'Other';
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                environments[0].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep1.Branch__c = 'dev1';
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep1.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Org Credential creation
            List<Org__c> credentials = [
                SELECT Id, Name, Platform__c, Oauth_Signature__c, Validated_Date__c, Disable_Validation__c, SFDC_Org_ID__c
                FROM Org__c
                WHERE Platform__c = 'Other'
            ];
            for (Org__c org : credentials) {
                org.Username__c = UserInfo.getUserName();
                org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
                org.Oauth_Signature__c = org.Name;
                org.Validated_Date__c = System.now();
                org.Disable_Validation__c = true;
                break;
            }
            update credentials;

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // Promotion creation
            Promotion__c promotion = TestDataFactory.createPromotion(
                project.Id,
                credentials[2].Id,
                environments[2].Id,
                credentials[1].Id,
                environments[1].Id,
                'Draft'
            );
            insert promotion;

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Function creation
            Function__c function = new Function__c(
                Name = 'muleDeploy',
                API_Name__c = 'muleDeploy',
                Script__c = 'echo hello world $par1',
                Type__c = 'Custom',
                Parameters__c = '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                    '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                    '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                    '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                    '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]',
                Options__c = '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                    '{"name": "gitUsername", "value": "", "sensitive": true},' +
                    '{"name": "gitPassword", "value": "", "sensitive": true},' +
                    '{"name": "branchName", "value": "", "sensitive": false}]',
                Callback_Type__c = 'ApexClass',
                ApexClass__c = namespacePrefix() + 'FunctionStepExecutionCallback'
            );
            insert function;

            // Step creation
            Step__c functionStep = TestDataFactory.createStep(
                deployment.Id,
                'Function',
                'Function',
                'Not started',
                1,
                null,
                '{"functionId":"' +
                function.Id +
                '","functionAPIName":"' +
                function.API_Name__c +
                '","functionParameters":[{"name":"SourceDBName","value":"11"},{"name":"DestinationDBProvider","value":"22"},{"name":"PipelineUsername","value":"33"},{"name":"UserEmail","value":"44"},{"name":"LogLevel","value":"ERROR"}]}'
            );
            insert new List<Step__c>{ functionStep };

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Test.startTest();
            PageReference pReference = Page.DeploymentWizard;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReference);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(deployment));
            ext.deployment.Date__c = System.today().addDays(1);
            ext.deployment.Schedule__c = 'Deploy later';

            List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
            estimations = ext.getEstimations();
            System.assertEquals(1, ext.destinationOrgs.size());
            System.assertEquals(0, ext.totalEstimations);
            System.assert(estimations.size() > 0);
            System.assertEquals(0, estimations[0].credits);
            ext.deployment.Schedule__c = 'Deploy now';
            ext.deployment.Date__c = System.today().addDays(0);
            ext.confirmAll();
            ext.confirm();
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(
                200,
                'Complete',
                '{"id": "123123123", "status": "pending", "messages": ["function received and Queued", "executin will start shortly"]}',
                null
            );
            Test.setMock(HttpCalloutMock.class, mockResponse);

            ext.deployCall();
            Integer messageCount = ext.getPageMessageSize();
            System.assertEquals(0, messageCount);
            System.assertEquals(true, ext.goToDeployment);

            Result__c result = new Result__c();
            result.Function__c = function.Id;
            result.Job_Type__c = 'function';
            insert result;

            EventBus.publish(
                new MC_Result__e(
                    ResultId__c = result.Id,
                    isFinished__c = true,
                    isSuccess__c = true,
                    Progress_Status__c = 'Job enqueued on the backend'
                )
            );

            Test.stopTest();
        }
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }
}