@IsTest
private with sharing class UnifyTestsTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    static void unifyTests() {
        System.runAs(getRunAsUser()) {
            // Setup
            mockTestTool(MockUserStoryBundleTestUnifier.class.getName());
            List<User_Story__c> originUserStories = getOriginUserStories();
            User_Story__c destinationUserStory = getDestinationUserStory();

            // Exercise
            Test.startTest();
            new UnifyTests(new List<Id>(new Map<Id, User_Story__c>(originUserStories).keySet()), destinationUserStory.Id).execute();
            Test.stopTest();

            // Verify
            List<Test__c> unifiedTests = [SELECT Id FROM Test__c WHERE User_Story__c = :destinationUserStory.Id];
            System.assertEquals(1, unifiedTests.size());
        }
    }

    @IsTest
    static void cloneTests() {
        System.runAs(getRunAsUser()) {
            // Setup
            mockTestTool(null);
            createFiles([SELECT Id FROM Test__c]);
            List<User_Story__c> originUserStories = getOriginUserStories();
            User_Story__c destinationUserStory = getDestinationUserStory();

            // Exercise
            Test.startTest();
            new UnifyTests(new List<Id>(new Map<Id, User_Story__c>(originUserStories).keySet()), destinationUserStory.Id).execute();
            Test.stopTest();

            // Verify
            List<Test__c> clonedTests = [SELECT Id FROM Test__c WHERE User_Story__c = :destinationUserStory.Id];
            System.assertEquals(2, clonedTests.size(), 'Tests should be cloned to the destination user story');
            Set<Id> linkIds = new Map<Id, Test__c>(clonedTests).keySet();
            List<ContentDocumentLink> files = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :linkIds];
            System.assertEquals(2, files.size(), 'Files attached to the original tests should be cloned to the new tests');
        }
    }

    private static void createData() {
        mockTestTool(MockUserStoryBundleTestUnifier.class.getName());
        ExtensionConfiguration extensionConfiguration = new ExtensionConfiguration().application('Test').tool('Manual Tests').active((true));
        new JobTemplate().name('Test_Tool_Template').add(new JobStep());

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, dev2).branch('dev1'))
            .add(
                new Project()
                    .add(
                        new UserStory()
                            .title('Origin US - 1')
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
                            .add(new Test_t().name('Test1').extensionConfiguration(extensionConfiguration))
                    )
                    .add(
                        new UserStory()
                            .title('Origin US - 2')
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name('TestClass 1').type('ApexClass'))
                            .add(new Test_t().name('Test2').extensionConfiguration(extensionConfiguration))
                    )
                    .add(
                        new UserStory()
                            .title('Destination US')
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name('TestClass 2').type('ApexClass'))
                    )
            )
            .persist();
    }

    private static List<User_Story__c> getOriginUserStories() {
        return [SELECT Id FROM User_Story__c WHERE User_Story_Title__c LIKE '%Origin US%'];
    }

    private static User_Story__c getDestinationUserStory() {
        return [SELECT Id FROM User_Story__c WHERE User_Story_Title__c LIKE '%Destination US%' LIMIT 1];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void mockTestTool(String unifierLogic) {
        TestToolsSelector.mock(
            new List<TestTool__mdt>{
                new TestTool__mdt(
                    MasterLabel = 'Manual Tests',
                    JobTemplate__c = 'Test_Tool_Template_1',
                    TestType__c = 'Mock Type',
                    UserStoryBundleTestsUnifierLogic__c = unifierLogic
                )
            }
        );
    }

    private static void createFiles(List<Test__c> parentTests) {
        List<ContentVersion> versionsToInsert = new List<ContentVersion>();
        for (Test__c test : parentTests) {
            versionsToInsert.add(
                new ContentVersion(
                    Title = 'ApexClasses',
                    PathOnClient = 'ApexClasses',
                    VersionData = Blob.valueOf('[TestClass]'),
                    ContentLocation = 'S'
                )
            );
        }
        insert versionsToInsert;
        Set<Id> versionIds = new Map<Id, ContentVersion>(versionsToInsert).keySet();
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :versionIds];
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for (Integer i = 0; i < contentVersions.size(); i++) {
            linksToInsert.add(
                new ContentDocumentLink(LinkedEntityId = parentTests[i].Id, ContentDocumentId = contentVersions[i].ContentDocumentId, ShareType = 'I')
            );
        }
        insert linksToInsert;
    }
}