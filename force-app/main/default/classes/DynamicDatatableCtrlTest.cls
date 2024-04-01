@IsTest
private with sharing class DynamicDatatableCtrlTest {
    private static final String STANDARD_USER = 'test_user@myorg.com';

    @TestSetup
    private static void makeData() {
        Map<String, RecordTypeInfo> deploymentRecordTypes = SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        
            ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(
                    Deployment__c.SObjectType,
                    Deployment__c.RecordTypeId,
                    deploymentRecordTypes.get('Automation_Template').getRecordTypeId()
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
        // Setup
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
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

            Schema.FieldSet promotedUserStoryFieldSet = Schema.SObjectType.Promoted_User_Story__c.fieldSets.getMap().values().get(0);
            DynamicDatatableColumnsConfiguration columnsConfiguration = new DynamicDatatableColumnsConfiguration();
            columnsConfiguration.objectApiName = Schema.SObjectType.Promoted_User_Story__c.getName();
            columnsConfiguration.fieldSetName = promotedUserStoryFieldSet.getName();
            columnsConfiguration.hideDefaultColumnsActions = true;
            columnsConfiguration.sortable = true;
            columnsConfiguration.editable = true;
            columnsConfiguration.searchable = true;

            DynamicDatatableQueryConfiguration queryConfig = new DynamicDatatableQueryConfiguration();
            queryConfig.selectFieldSet = desiredFieldSet;
            queryConfig.fromObject = availableChildObjects.get(childObjectLabel);
            queryConfig.relationshipField = objectName;
            queryConfig.parentId = deployment.Id;
            queryConfig.orderBy = 'Order__c';
            queryConfig.recordsLimit = 20;
            queryConfig.recordsOffset = 0;

            // Exercise
            Test.startTest();

            List<ColumnConfig> columnsConfig = DynamicDatatableCtrl.fetchColumnsConfig(columnsConfiguration);

            List<SObject> data = DynamicDatatableCtrl.fetchData(queryConfig);

            // If relationshipField is not provided, it tries to find the default
            queryConfig.relationshipField = null;
            List<SObject> data2 = DynamicDatatableCtrl.fetchData(queryConfig);

            Test.stopTest();

            // Verify
            System.assertEquals(promotedUserStoryFieldSet.getFields().size(), columnsConfig.size(), 'columnsConfig size should match the number of fields in the field set');
            System.assertEquals(10, data.size(), 'There should be 10 steps related to the deployment');
            System.assertEquals(10, data2.size(), 'There should be 10 steps related to the deployment');
        }
    }

    @IsTest
    private static void fetchDataException() {
        // Setup
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            Deployment__c deployment = [SELECT Id FROM Deployment__c];

            String namespace = Settings.ns;
            String objectName = namespace + 'Deployment__c';
            String desiredFieldSet = 'Deployment_Steps';

            DynamicDatatableQueryConfiguration queryConfig = new DynamicDatatableQueryConfiguration();
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
                DynamicDatatableCtrl.fetchData(queryConfig);
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
        // Setup
        Account acc = new Account(Name = 'test1');
        insert acc;

        // Exercise
        acc.Name = 'test2';
        DynamicDatatableCtrl.updateRecords(new List<SObject>{ acc });

        // Verify
        System.assertEquals('test2', [SELECT Name FROM Account WHERE Id = :acc.Id].Name, 'Account name should have been updated');
    }
}