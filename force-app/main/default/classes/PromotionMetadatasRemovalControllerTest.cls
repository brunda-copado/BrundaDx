@IsTest
private class PromotionMetadatasRemovalControllerTest {
    @TestSetup
    private static void setupData() {
        User user = getRemoveMetadataFromPromotionUser();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    static void testSaveIgnoreChanges() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = createPromotion();
            String fileData = JSON.serialize(getIgnoredFileDataString(), true);

            // Exercise
            Test.startTest();
            PromotionMetadatasRemovalController.saveIgnoreChanges(promotion.Id, fileData);
            Test.stopTest();

            // Verify
            String fileVersionData = readFileContent(promotion.Id, PromotionConstants.IGNORED_CHANGES_FILE_NAME);
            System.assertEquals(
                true,
                fileVersionData.length() > 0,
                'There should be content version data associated to newly created Ignored Changes file.'
            );
        }
    }

    @IsTest
    static void testSaveIgnoreChangesException() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = createPromotion();
            String exceptionMessage;

            // Exercise
            Test.startTest();
            try {
                PromotionMetadatasRemovalController.saveIgnoreChanges(promotion.Id, null);
            } catch (Exception e) {
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(
                true,
                exceptionMessage != null,
                'There should not be content version data associated since json file format is not correct.'
            );
        }
    }

    @IsTest
    static void testGetMetadataDetails() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Id> metadataIds = new List<Id>();
            for (User_Story_Metadata__c metadata : [SELECT Id FROM User_Story_Metadata__c]) {
                metadataIds.add(metadata.Id);
            }

            // Exercise
            Test.startTest();
            List<User_Story_Metadata__c> userStoryMetadatas = PromotionMetadatasRemovalController.getMetadataDetails(metadataIds);
            Test.stopTest();

            // Verify
            System.assertEquals(4, userStoryMetadatas.size(), 'There should be metadata changes associated to user stories.');
        }
    }

    // HELPERS

    private static void createData() {
        Credential source = new Credential();

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().platform('Other').add(new Credential())
                    )
                    .branch('dev1')
            )
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
                    .branch('dev2')
            )
            .add(
                new Project()
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass1').type('ApexClass')))
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass2').type('ApexClass')))
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass1').type('ApexClass')))
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass3').type('ApexClass')))
            )
            .persist();

        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
    }

    private static String getIgnoredFileDataString() {
        String fileData = '[{"u":"US-0444098","t":"ApexClass","n":"AccountHandler1","m":"force-app/main/default/","a":"Add"},{"u":"US-0444099","t":"ApexClass","n":"AccountHandler2","m":"force-app/main/default/","a":"Add"},{"u":"US-0444099","t":"ApexClass","n":"AccountHandler3","m":"force-app/main/default/","a":"Add"}]';
        return fileData;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
    }

    private static Promotion__c createPromotion() {
        User_Story__c userStory = getUserStory();
        Promotion__c promotion = (Promotion__c) new Promotion()
            .projectId(userStory.Project__c)
            .sourceEnvId(userStory.Environment__c)
            .add(new PromotedUserStory().userStory(userStory.Id))
            .persist();
        return promotion;
    }

    private static User getRemoveMetadataFromPromotionUser() {
        return (User) new User_t()
            .assign(getCopadoUserPermissionSetAssignment())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
    }

    private static PermissionSetAssignment_t getCopadoUserPermissionSetAssignment() {
        PermissionSetAssignment_t copadoUserPermissionSetAssignment = new PermissionSetAssignment_t().copadoUser();
        if (!customPermissionAlreadyAssigned()) {
            copadoUserPermissionSetAssignment.add(new CustomPermission_t().removeMetadataFromPromotion());
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
                        WHERE DeveloperName = :CustomPermissionConstants.REMOVE_METADATA_FROM_PROMOTION_CUSTOM_PERMISSION
                    )
                    AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Copado_User')
            ] > 0;
    }

    private static String readFileContent(Id parentId, String name) {
        return getContentFromFile(parentId, name);
    }

    private static String getContentFromFile(Id parentId, String name) {
        Set<String> contentDocumentIds = new Set<String>();

        // PMD False positive, as WITH USER_MODE is not supported yet
        for (ContentDocumentLink contentDocumentLink : [
            SELECT Id, ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentId AND ContentDocument.Title = :name.substringBeforeLast('.')
            WITH USER_MODE
        ]) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }

        if (contentDocumentIds.isEmpty()) {
            return '';
        }

        // PMD False positive, as WITH USER_MODE is not supported yet
        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId, ContentBodyId, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds AND PathOnClient = :name
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return contentVersions == null || contentVersions.isEmpty() ? '' : contentVersions[0].VersionData.toString();
    }
}