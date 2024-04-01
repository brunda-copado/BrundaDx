@IsTest
private class PromotedUserStoriesDatatableCtrlTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesReadOnly())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            data();
        }
    }

    @IsTest
    static void fetchDataTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Environment__c environment0 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 0' LIMIT 1];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environment0.Id).status('Draft').persist();

            // Exercise
            Test.startTest();
            List<Promoted_User_Story__c> actualPromotedUserStories = PromotedUserStoriesDatatableController.fetchData(
                promotion.Id,
                Settings.ns + 'Promoted_User_Story_Datatable'
            );
            Test.stopTest();

            // Verify
            List<Promoted_User_Story__c> expectedPromotedUserStories = [SELECT Id FROM Promoted_User_Story__c WHERE Promotion__c = :promotion.Id];
            System.assertEquals(
                expectedPromotedUserStories.size(),
                actualPromotedUserStories.size(),
                'Promoted User Story counts should be the same'
            );
        }
    }

    @IsTest
    static void availableUserStoriesTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Environment__c environment0 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 0' LIMIT 1];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environment0.Id).status('Draft').persist();

            // Exercise
            Test.startTest();
            List<User_Story__c> actualUserStories = PromotedUserStoriesDatatableController.availableUserStories(
                promotion.Id,
                Settings.ns + 'Promotion_Related_List_Datatable'
            );
            Test.stopTest();

            // Verify
            List<User_Story__c> expectedUserStories = [
                SELECT Id
                FROM User_Story__c
                WHERE Promote_Change__c = TRUE AND Project__c = :project.Id AND Environment__c = :environment0.Id
            ];

            System.assertEquals(expectedUserStories.size(), actualUserStories.size(), 'User Story counts should be the same');
        }
    }

    @IsTest
    static void availableUserStoriesBackPromotionTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Environment__c environment0 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 0' LIMIT 1];
            Environment__c environment1 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 1' LIMIT 1];
            Org__c org1 = [SELECT Id FROM Org__c WHERE Environment__r.Name = 'Environment 1' LIMIT 1];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            User_Story__c userStory = [SELECT Id FROM User_Story__c WHERE Environment__c = :environment0.Id LIMIT 1];

            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environment0.Id).status('Completed').persist();
            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });

            UserStories.bypassTrigger = true;
            userStory.Org_Credential__c = org1.Id;
            userStory.Environment__c = environment1.Id;
            update userStory;
            UserStories.bypassTrigger = false;

            Promotion__c backPromotion = (Promotion__c) new Promotion()
                .projectId(project.Id)
                .destinationEnvId(environment1.Id)
                .status('Draft')
                .backPromotion(true)
                .persist();

            // Exercise
            Test.startTest();
            List<User_Story__c> actualUserStories = PromotedUserStoriesDatatableController.availableUserStories(
                backPromotion.Id,
                Settings.ns + 'Promotion_Related_List_Datatable'
            );
            Test.stopTest();

            // Verify
            List<User_Story__c> expectedUserStories = [
                SELECT Id
                FROM User_Story__c
                WHERE Project__c = :project.Id AND Environment__c = :environment1.Id
            ];

            System.assertEquals(expectedUserStories.size(), actualUserStories.size(), 'User Story counts should be the same');
        }
    }

    @IsTest
    static void addSelectedUserStoriesToPromotionTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Environment__c environment0 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 0' LIMIT 1];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environment0.Id).status('Draft').persist();
            User_Story__c userStory = [SELECT Id FROM User_Story__c WHERE Environment__c = :environment0.Id LIMIT 1];

            // Exercise
            Test.startTest();
            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });
            Test.stopTest();

            // Verify
            List<Promoted_User_Story__c> actualPromotedUserStories = [
                SELECT Id
                FROM Promoted_User_Story__c
                WHERE Promotion__c = :promotion.Id AND User_Story__c = :userStory.Id
            ];

            System.assertEquals(1, actualPromotedUserStories.size(), 'Only one Promoted User Story should be created');
        }
    }

    @IsTest
    static void validateSelectedUserStoriesToPromotionTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Environment__c environment0 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 0' LIMIT 1];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environment0.Id).status('Draft').persist();
            List<Id> userStoryIds = getUserStoriesWithDifferentReleases();

            // Exercise
            Test.startTest();
            String exceptionMessage;
            try {
                PromotedUserStoriesDatatableController.validateSelectedUserStoriesToPromotion(promotion.Id, userStoryIds);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assert(
                exceptionMessage.contains(Label.Add_User_Stories_Different_Releases_Validation),
                'User Stories belongs to different Releases.'
            );
        }
    }

    @IsTest
    static void updateReleaseOnPromotionTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Environment__c environment0 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 0' LIMIT 1];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environment0.Id).status('Draft').persist();
            List<Id> userStoryIds = getUserStoriesWithSameRelease();

            // Exercise
            Test.startTest();
            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, userStoryIds);
            Test.stopTest();

            // Verify
            List<Promoted_User_Story__c> actualPromotedUserStories = [
                SELECT Id, User_Story__r.Release__c
                FROM Promoted_User_Story__c
                WHERE Promotion__c = :promotion.Id
            ];
            promotion = [SELECT Id, Release__c FROM Promotion__c WHERE ID = :promotion.Id LIMIT 1];

            System.assertEquals(4, actualPromotedUserStories.size(), '4 Promoted User Story should be created');
            System.assertEquals(
                actualPromotedUserStories[0].User_Story__r.Release__c,
                promotion.Release__c,
                'Release should be updated on promotion.'
            );
        }
    }

    @IsTest
    static void removeSelectedPromotedUserStoriesTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Environment__c environment0 = [SELECT Id FROM Environment__c WHERE Name = 'Environment 0' LIMIT 1];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environment0.Id).status('Draft').persist();
            User_Story__c userStory = [SELECT Id FROM User_Story__c WHERE Environment__c = :environment0.Id LIMIT 1];
            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });
            Map<Id, Promoted_User_Story__c> actualPromotedUserStoriesByIds = new Map<Id, Promoted_User_Story__c>(
                [SELECT Id FROM Promoted_User_Story__c WHERE Promotion__c = :promotion.Id AND User_Story__c = :userStory.Id]
            );

            // Exercise
            Test.startTest();
            PromotedUserStoriesDatatableController.removeSelectedPromotedUserStories(new List<Id>(actualPromotedUserStoriesByIds.keyset()), null);
            Test.stopTest();

            // Verify
            List<Promoted_User_Story__c> expectedPromotedUserStories = [
                SELECT Id
                FROM Promoted_User_Story__c
                WHERE Promotion__c = :promotion.Id AND User_Story__c = :userStory.Id
            ];
            System.assertEquals(0, expectedPromotedUserStories.size(), 'There should not be any Promoted User Stories');
        }
    }

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        //Environment creation
        for (Integer i = 0; i < 3; i++) {
            new Environment().name('Environment ' + i).type('Production/Developer').platform('Other');
        }
        new Environment().name('Test Environment 3').type('Production/Developer').platform('Other').persist();
        List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c ORDER BY CreatedDate];

        // Org Credential validation
        List<Org__c> credentials = [
            SELECT Id, Name, Environment__c, Platform__c, Oauth_Signature__c, Validated_Date__c, Disable_Validation__c, SFDC_Org_ID__c
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

        // Function creation
        String namespace = namespacePrefix();
        new Function()
            .name('mulePromotion')
            .apiName('mulePromotion')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                '{"name": "gitUsername", "value": "", "sensitive": true},' +
                '{"name": "gitPassword", "value": "", "sensitive": true},' +
                '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .callbackType('ApexClass')
            .apexClass(namespace + 'FunctionStepExecutionCallback');

        new Function()
            .name('muleDeployment')
            .apiName('muleDeployment')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                '{"name": "gitUsername", "value": "", "sensitive": true},' +
                '{"name": "gitPassword", "value": "", "sensitive": true},' +
                '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .callbackType('ApexClass')
            .apexClass(namespace + 'FunctionStepExecutionCallback')
            .persist();

        new JobTemplate()
            .name('JOB_TEMPLATE_PROMOTION')
            .mockAutomation('Promotion')
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'));
        new JobTemplate()
            .name('JOB_TEMPLATE_DEPLOYMENT')
            .mockAutomation('PromotionDeployment')
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
            .persist();

        // Deployment flow creation
        new Pipeline()
            .active(true)
            .mainBranch('master')
            .setPlatform('Other')
            .add(new Connection().sourceId(environments[0].Id).destinationId(environments[2].Id).branch('dev1'))
            .add(new Connection().sourceId(environments[1].Id).destinationId(environments[2].Id).branch('dev2'))
            .add(new Project().add(new UserStory().status('Approved').credentialId(credentials[0].Id)))
            .add(new Project().name('project1').add(new Release()))
            .add(new Project().name('project2').add(new Release()))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }

    private static List<Id> getUserStoriesWithDifferentReleases() {
        Org__c credential = [SELECT Id FROM Org__c LIMIT 1];

        for (Release__c release : [SELECT Id, Project__c FROM Release__c]) {
            new UserStory().credentialId(credential.Id).releaseId(release.Id).persist();
        }

        Map<Id, User_Story__c> userStoryById = new Map<Id, User_Story__c>([SELECT Id FROM User_Story__c WHERE Release__c != NULL]);
        return new List<Id>(userStoryById.keyset());
    }

    private static List<Id> getUserStoriesWithSameRelease() {
        Org__c credential = [SELECT Id FROM Org__c LIMIT 1];
        Release__c release = [SELECT Id, Project__c FROM Release__c LIMIT 1];
        for (Integer index = 0; index < 4; index++) {
            new UserStory().credentialId(credential.Id).releaseId(release.Id).persist();
        }

        Map<Id, User_Story__c> userStoryById = new Map<Id, User_Story__c>([SELECT Id FROM User_Story__c WHERE Release__c != NULL]);
        return new List<Id>(userStoryById.keyset());
    }
}