@IsTest
private class UserStoryBundleValidatorTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = getUserStoryBundleUser();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void noCustomPermission() {
        System.runAs(getUserWithoutUSBPermission()) {
            // Setup
            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'dev1', 'int' })) {
                userStoryIds.add(userStory.Id);
            }

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.USB_Error_No_Custom_Permission, errorMessage, 'Custom Permission is required to create USB');
        }
    }

    @IsTest
    private static void userStorySize() {
        System.runAs(getRunAsUser()) {
            // Setup
            createData(true);

            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'dev1' })) {
                userStoryIds.add(userStory.Id);
                break;
            }

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.USB_WARNING_NO_US_SELECTED, errorMessage, 'At least 2 user story needed for bundle');
        }
    }

    @IsTest
    private static void differentEnvironments() {
        System.runAs(getRunAsUser()) {
            // Setup
            createData(true);

            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'dev1', 'int' })) {
                userStoryIds.add(userStory.Id);
            }

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.USB_WARNING_DIFFERENT_ENVIRONMENTS, errorMessage, 'User Stories should be under same environment');
        }
    }

    @IsTest
    private static void differentProject() {
        System.runAs(getRunAsUser()) {
            // Setup
            createData(true);

            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'int' })) {
                userStoryIds.add(userStory.Id);
            }

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.USB_WARNING_DIFFERENT_PROJECTS, errorMessage, 'User Stories should be under same project');
        }
    }

    @IsTest
    private static void noMetadataOrTask() {
        System.runAs(getRunAsUser()) {
            // Setup
            createData(true);

            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'uat' })) {
                userStoryIds.add(userStory.Id);
            }

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.No_Metadata_Or_Deployment_Task, errorMessage, 'User Stories should have metadata or deployment task');
        }
    }

    @IsTest
    private static void tooManyMetadata() {
        System.runAs(getRunAsUser()) {
            // Setup
            createData(true);

            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'dev2' })) {
                userStoryIds.add(userStory.Id);
            }

            List<User_Story_Metadata__c> metadatas = new List<User_Story_Metadata__c>();
            for (Integer i = 0; i < 8000; i++) {
                User_Story_Metadata__c metadata = new User_Story_Metadata__c();
                metadata.Metadata_API_Name__c = 'TestClass extra ' + i;
                metadata.Type__c = 'ApexClass';
                metadata.User_Story__c = userStoryIds[0];
                metadatas.add(metadata);
            }
            insert metadatas;

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.Bundle_Metadata_Limit, errorMessage, 'More then 8000 metadata included');
        }
    }

    @IsTest
    private static void actionNotDefined() {
        System.runAs(getRunAsUser()) {
            // Setup
            createData(false);

            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'dev2' })) {
                userStoryIds.add(userStory.Id);
            }

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.No_Action_For_Bundle, errorMessage, 'Commit action is not created on pipeline');
        }
    }

    @IsTest
    private static void bundleLocked() {
        System.runAs(getRunAsUser()) {
            // Setup
            createData(true);

            String errorMessage = '';
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories(new Set<String>{ 'dev2' })) {
                userStoryIds.add(userStory.Id);
            }

            Actions.AddUserStoryBundleRequest request = new Actions.AddUserStoryBundleRequest();
            request.packageVersionId = getPackageVersion().Id;
            request.userStoryIds = userStoryIds;

            Actions.UserStoryBundleService.add(request);

            Artifact_Version__c packageVersion = getPackageVersion();
            packageVersion.Status__c = 'Locked';
            update packageVersion;

            // Exercise
            Test.startTest();
            try {
                new UserStoryBundleValidator(userStoryIds).run();
            } catch (Exception ex) {
                errorMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.User_Story_Part_Of_Other_Bundle, errorMessage, 'Package version is already locked');
        }
    }

    // HELPERS

    private static void createData(Boolean createActionTemplate) {
        if (createActionTemplate) {
            new JobTemplate().name('Commit Template').apiName('Commit Template_1').version(1).mockAutomation('Commit').add(new JobStep()).persist();
        }

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Credential dev2Credential = new Credential();
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(dev2Credential);
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Credential uatCredential = new Credential();
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(uatCredential);

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(
                new Project()
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 1').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 2').type('ApexClass')))
                    .add(new UserStory().credential(intCredential).add(new UserStoryMetadata().name('TestClass 3').type('ApexClass')))
                    .add(new UserStory().credential(intCredential).add(new UserStoryMetadata().name('TestClass 4').type('ApexClass')))
            )
            .add(
                new Project()
                    .add(new UserStory().credential(intCredential).add(new UserStoryMetadata().name('TestClass 5').type('ApexClass')))
                    .add(new UserStory().credential(intCredential).add(new UserStoryMetadata().name('TestClass 6').type('ApexClass')))
            );

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('integration'))
            .add(
                new Project()
                    .add(new UserStory().credential(uatCredential))
                    .add(new UserStory().credential(uatCredential))
                    .add(new UserStory().credential(uatCredential))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 3').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 4').type('ApexClass')))
                    .add(new UserStory().credential(dev2Credential).add(new UserStoryMetadata().name('TestClass 5').type('ApexClass')))
                    .add(new UserStory().credential(dev2Credential).add(new UserStoryMetadata().name('TestClass 6').type('ApexClass')))
            );

        Id recordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId();
        new Package_t().name('Test').recordTypeId(recordTypeId).add(new PackageVersion()).persist();
    }

    private static Artifact_Version__c getPackageVersion() {
        return [SELECT Id, Status__c FROM Artifact_Version__c LIMIT 1];
    }

    private static List<User_Story__c> getUserStories(Set<String> environmentName) {
        return [SELECT Id, Environment__r.Name FROM User_Story__c WHERE Environment__r.Name IN :environmentName];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserWithoutUSBPermission() {
        User user = (User) new User_t().persist();
        deletePermissionIfExists(user.Id);
        return user;
    }

    private static void deletePermissionIfExists(String userId) {
        delete [
            SELECT Id
            FROM SetupEntityAccess
            WHERE
                SetupEntityId IN (
                    SELECT Id
                    FROM CustomPermission
                    WHERE DeveloperName = :CustomPermissionConstants.USER_STORY_BUNDLE_CUSTOM_PERMISSION
                )
                AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
        ];
    }

    private static User getUserStoryBundleUser() {
        return (User) new User_t()
            .assign(getCopadoUserPermissionSetAssignment())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
    }

    private static PermissionSetAssignment_t getCopadoUserPermissionSetAssignment() {
        PermissionSetAssignment_t copadoUserPermissionSetAssignment = new PermissionSetAssignment_t().copadoUser();
        if (!customPermissionAlreadyAssigned()) {
            copadoUserPermissionSetAssignment.add(new CustomPermission_t().userStoryBundles());
        }
        return copadoUserPermissionSetAssignment;
    }

    private static Boolean customPermissionAlreadyAssigned() {
        return [
                SELECT COUNT()
                FROM SetupEntityAccess
                WHERE
                    SetupEntityId IN (
                        SELECT Id
                        FROM CustomPermission
                        WHERE DeveloperName = :CustomPermissionConstants.USER_STORY_BUNDLE_CUSTOM_PERMISSION
                    )
                    AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Copado_User')
            ] > 0;
    }
}