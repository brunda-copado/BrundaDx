@IsTest
private with sharing class DatatableServiceCtrlTest {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    private static final String STANDARD_USER_NO_PERMISSION = 'test2@test2.com';

    @TestSetup
    private static void makeData() {
        Map<String, RecordTypeInfo> deploymentRecordTypes = SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        TestDataFactory.createUsers();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
            
            new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(
                    Deployment__c.SObjectType,
                    Deployment__c.RecordTypeId,
                    deploymentRecordTypes.get('Metadata_Deployment').getRecordTypeId()
                )
                .setDataSize(Deployment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
                .setFieldValue(Step__c.SObjectType, Step__c.DataJson__c, '{"flowApiName": "TestFlow","type":"wait","flowParameters":[]}')
                .setDataSize(Step__c.SObjectType, 10)
                .setSObjectRelation(
                    Step__c.SObjectType,
                    Deployment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 }
                )
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    private static void getTableInfo() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            // Setup
            Deployment__c deployment = [SELECT Id FROM Deployment__c];

            String namespace = Settings.ns;
            String pageType = 'RecordPage';
            String objectName = namespace + 'Deployment__c';
            String childObjectLabel = 'Step';
            String desiredFieldSet = 'Deployment_Steps';

            Map<String, String> availableChildObjects = new Map<String, String>();
            RelatedListVisualPicklist picklistHandler = new RelatedListVisualPicklist(pageType, objectName);
            System.assertEquals(null, picklistHandler.getDefaultValue(), 'There should not be a default value');
            VisualEditor.DynamicPickListRows relatedObjects = picklistHandler.getValues();
            List<VisualEditor.DataRow> rows = relatedObjects.getDataRows();
            for (VisualEditor.DataRow row : rows) {
                availableChildObjects.put(row.getLabel(), String.valueOf(row.getValue()));
            }
            System.assertEquals('Step__c', availableChildObjects.get(childObjectLabel), 'Step__c should be available');

            DatatableColumnsConfiguration columnsConfiguration = new DatatableColumnsConfiguration();
            columnsConfiguration.objectApiName = availableChildObjects.get(childObjectLabel);
            columnsConfiguration.fieldSetName = desiredFieldSet;
            columnsConfiguration.hideDefaultColumnsActions = true;
            columnsConfiguration.sortable = true;
            columnsConfiguration.editable = true;
            columnsConfiguration.searchable = true;

            DatatableQueryConfiguration queryConfig = new DatatableQueryConfiguration();
            queryConfig.selectFieldSet = desiredFieldSet;
            queryConfig.fromObject = availableChildObjects.get(childObjectLabel);
            queryConfig.relationshipField = objectName;
            queryConfig.parentId = deployment.Id;
            queryConfig.orderBy = 'Order__c';
            queryConfig.recordsLimit = 20;
            queryConfig.recordsOffset = 0;

            // Exercise
            Test.startTest();

            List<DatatableServiceColumnConfig> columnsConfig = DatatableServiceCtrl.fetchColumnsConfiguration(columnsConfiguration);

            List<SObject> data = DatatableServiceCtrl.fetchData(queryConfig);

            // If relationshipField is not provided, it tries to find the default
            queryConfig.relationshipField = null;
            List<SObject> data2 = DatatableServiceCtrl.fetchData(queryConfig);

            Test.stopTest();

            // Verify
            System.assertEquals(2, columnsConfig.size(), 'columnsConfig size should match the number of fields in the field set');
            System.assertEquals(10, data.size(), 'There should be 10 steps related to the deployment');
            System.assertEquals(10, data2.size(), 'There should be 10 steps related to the deployment');
        }
    }

    @IsTest
    private static void fetchDataException() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            // Setup
            Deployment__c deployment = [SELECT Id FROM Deployment__c];

            String namespace = Settings.ns;
            String objectName = namespace + 'Deployment__c';
            String desiredFieldSet = 'Deployment_Steps';

            DatatableQueryConfiguration queryConfig = new DatatableQueryConfiguration();
            queryConfig.selectFieldSet = desiredFieldSet;
            queryConfig.fromObject = namespace + 'Step__c';
            queryConfig.relationshipField = objectName;
            queryConfig.parentId = deployment.Id;
            queryConfig.orderBy = 'Order__c';
            queryConfig.recordsLimit = 20;
            queryConfig.recordsOffset = 0;

            // Exercise
            String ex;
            try {
                queryConfig.fromObject = 'Acc';
                DatatableServiceCtrl.fetchData(queryConfig);
                System.assert(false, 'fetchData should have thrown an exception due to invalid object api name');
            } catch (Exception e) {
                ex = e.getMessage();
            }

            // Verify
            System.assert(String.isNotBlank(ex), 'fetchData should have thrown an exception due to invalid object api name');
        }
    }

    @IsTest
    private static void updateRecords() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
        // Setup
            User_Story__c userStory = new User_Story__c(User_Story_Title__c = 'test1');
            insert userStory;

        // Exercise
            userStory.User_Story_Title__c = 'test2';
            DatatableServiceCtrl.updateRecords(new List<SObject>{ userStory });

        // Verify
            System.assertEquals('test2', [SELECT User_Story_Title__c FROM User_Story__c WHERE Id = :userStory.Id].User_Story_Title__c, 'User story Title should have been updated');
        }
    }



    @IsTest
    private static void fetchColumnsConfigurationException() {
        String ex = '';
        List<DatatableServiceColumnConfig> columnsConfig = new List<DatatableServiceColumnConfig> ();
        try{
            User standardUser = [SELECT Id, Username FROM User WHERE Email = :STANDARD_USER_NO_PERMISSION LIMIT 1];
            System.runAs(standardUser) {
                // Setup
                DatatableColumnsConfiguration columnsConfiguration = new DatatableColumnsConfiguration();
                columnsConfiguration.objectApiName = 'User_Story__c';
                columnsConfiguration.fieldSetName = 'Sprint_Wall_Column';
                columnsConfiguration.hideDefaultColumnsActions = true;
                columnsConfiguration.sortable = true;
                columnsConfiguration.editable = true;
                columnsConfiguration.searchable = true;

                // Exercise
                columnsConfig = DatatableServiceCtrl.fetchColumnsConfiguration(columnsConfiguration);
            }
        } catch (Exception e) {
            ex = e.getMessage();
        }

        // Verify
        System.assertEquals(0,columnsConfig.size(), 'There should not be any columnsConfig');
        System.assertNotEquals('',ex, 'fetchColumnsConfiguration should have thrown an exception');
    }

    @IsTest
    private static void fetchRelationalRecords() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            // Setup
            prepareSprintWall();

            Sprint__c sprint = [SELECT Id FROM Sprint__c];

            DatatableColumnsConfiguration columnsConfiguration = new DatatableColumnsConfiguration();
            columnsConfiguration.objectApiName = 'User_Story__c';
            columnsConfiguration.fieldSetName = 'Sprint_Wall_Columns';
            columnsConfiguration.hideDefaultColumnsActions = true;
            columnsConfiguration.sortable = true;
            columnsConfiguration.editable = true;
            columnsConfiguration.searchable = true;

            DatatableQueryConfiguration queryConfig = new DatatableQueryConfiguration();
            queryConfig.selectFieldSet = 'Sprint_Wall_Columns';
            queryConfig.fromObject = 'User_Story__c';
            queryConfig.relationshipField = 'Sprint__c	';
            queryConfig.parentId = sprint.Id;
            queryConfig.orderBy = 'Name';
            queryConfig.recordsLimit = 20;
            queryConfig.recordsOffset = 0;

            // Exercise
            Test.startTest();

            List<DatatableServiceColumnConfig> columnsConfig = DatatableServiceCtrl.fetchColumnsConfiguration(columnsConfiguration);

            List<SObject> data = DatatableServiceCtrl.fetchData(queryConfig);

            // If relationshipField is not provided, it tries to find the default
            queryConfig.relationshipField = null;
            queryConfig.parentIds = new List<Id>{sprint.Id};
            List<SObject> data2 = DatatableServiceCtrl.fetchData(queryConfig);
            DatatableColumnsConfiguration config = new DatatableColumnsConfiguration();
            Test.stopTest();

            // Verify
            System.assertNotEquals(0, columnsConfig.size(), 'There should be Column config exist');
            System.assertEquals('Sprint__c', config.field('Sprint__r.Name'), 'Id field should be returned');
            System.assertEquals('StandardObjectId', config.field('StandardObject.Name'), 'Id field should be returned');
            System.assertEquals(5, data.size(), 'There should be 5 User Story related to the Sprint');
            System.assertEquals(5, data2.size(), 'There should be 5 User Story related to the Sprint');
        }
    }

    private static void prepareSprintWall() {
        TestUtilities tu = new TestUtilities();
        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
            'Name' => 'Sprint 2',
            'Start_Date__c' => Date.today().addDays(-8),
            'End_Date__c' => Date.today().addDays(8)
        });

        // Create 5 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 5, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2
        });
    }
}