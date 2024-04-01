@IsTest
private class SprintWallChartControllerTest {
    private static final String MOCK_HISTORY = '[{"attributes" : {"type" : "OBJECT_NAME","url" : "/services/data/v54.0/sobjects/OBJECT_NAME/h007Q000004Fvb7QAC"},"Id" : "h007Q000004Fvb7QAC","Sprint__c" : "RECORD_ID","ACTUAL_VELOCITY_FIELD" : 130.00,"ACTUAL_VELOCITY_FIELD" : 150.00,"PLANNED_VELOCITY_FIELD" : 200.00,"PLANNED_VELOCITY_FIELD" : 200.00}, {"attributes" : {"type" : "OBJECT_NAME","url" : "/services/data/v54.0/sobjects/OBJECT_NAME/h007Q000004FvYDQA0"},"Id" : "h007Q000004FvYDQA0","Sprint__c" : "RECORD_ID","ACTUAL_VELOCITY_FIELD" : 130.00,"ACTUAL_VELOCITY_FIELD" : 130.00,"PLANNED_VELOCITY_FIELD" : 150.00,"PLANNED_VELOCITY_FIELD" : 200.00}, {"attributes" : {"type" : "OBJECT_NAME","url" : "/services/data/v54.0/sobjects/OBJECT_NAME/h007Q000004FfGWQA0"},"Id" : "h007Q000004FfGWQA0","Sprint__c" : "RECORD_ID","ACTUAL_VELOCITY_FIELD" : 107.00,"ACTUAL_VELOCITY_FIELD" : 130.00,"PLANNED_VELOCITY_FIELD" : 150.00,"PLANNED_VELOCITY_FIELD" : 150.00} ]';
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        new User_t().assign(new PermissionSetAssignment_t().copadoUser()).standard().persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void testGetMappingConfig() {
        // Setup
        String plannedVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName();
        String actualVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName();

        // Exercise
        Test.startTest();
        SprintWallChartController.MappingConfig result = SprintWallChartController.getMappingConfig(plannedVelocityField, actualVelocityField);
        Test.stopTest();

        // Verify
        System.assert(String.isNotBlank(result.sprintPlannedVelocity), 'Sprint Planned Velocity shouldn\'t be empty');
        System.assert(String.isNotBlank(result.sprintActualVelocity), 'Sprint Actual Velocity shouldn\'t be empty');
    }

    @IsTest
    private static void testGetChartDataBurnUp() {
        // Setup
        Sprint__c s = [SELECT Id, Start_Date__c, End_Date__c FROM Sprint__c WHERE Name = 'Sprint1' LIMIT 1];

        ChartController.ChartDataRequest request = new ChartController.ChartDataRequest();
        request.objectId = s.Id;
        request.type = SprintWallChartController.BURNUP_LINE_CHART;
        request.chartFileName = 'Test Get Chart Data.json';
        request.lastDayOfWeek = 'friday';
        request.plannedVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName();
        request.actualVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName();
        request.sprintPlannedVelocityField = Schema.SObjectType.Sprint__c.fields.Planned_Velocity__c.getName();
        request.sprintActualVelocityField = Schema.SObjectType.Sprint__c.fields.Actual_Velocity__c.getName();

        SprintSnapshotRecordsCollector.mockHistory = MOCK_HISTORY
            .replaceAll('RECORD_ID', request.objectId)
            .replaceAll('OBJECT_NAME', Schema.SObjectType.Burndown_Item__c.getName())
            .replaceAll('ACTUAL_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName())
            .replaceAll('PLANNED_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName());

        // Exercise
        Test.startTest();
        ChartController.ChartDataResponse result = SprintWallChartController.getChartData(JSON.serialize(request));
        Test.stopTest();

        // Verify
        System.assert(String.isNotBlank(result.chartDataJson), 'chartData JSON shouldn\'t be empty');
        System.assert(!result.xAxisValues.isEmpty(), 'x axis shouldn\'t be empty');
        for (String sprintDay : result.xAxisValues) {
            Date d = Date.parse(sprintDay);
            System.assert(s.Start_Date__c <= d, 'Returned Date is not part of the sprint');
            System.assert(d <= s.End_Date__c, 'Returned Date is not part of the sprint');
        }
    }

    @IsTest
    private static void testGetChartDataBurnDown() {
        // Setup
        Sprint__c s = [SELECT Id, Start_Date__c, End_Date__c FROM Sprint__c WHERE Name = 'Sprint1' LIMIT 1];

        ChartController.ChartDataRequest request = new ChartController.ChartDataRequest();
        request.objectId = s.Id;
        request.type = SprintWallChartController.BURNDOWN_LINE_CHART;
        request.chartFileName = 'Test Get Chart Data.json';
        request.lastDayOfWeek = 'friday';
        request.plannedVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName();
        request.actualVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName();
        request.sprintPlannedVelocityField = Schema.SObjectType.Sprint__c.fields.Planned_Velocity__c.getName();
        request.sprintActualVelocityField = Schema.SObjectType.Sprint__c.fields.Actual_Velocity__c.getName();

        SprintSnapshotRecordsCollector.mockHistory = MOCK_HISTORY
            .replaceAll('RECORD_ID', request.objectId)
            .replaceAll('OBJECT_NAME', Schema.SObjectType.Burndown_Item__c.getName())
            .replaceAll('ACTUAL_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName())
            .replaceAll('PLANNED_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName());

        // Exercise
        Test.startTest();
        ChartController.ChartDataResponse result = SprintWallChartController.getChartData(JSON.serialize(request));
        Test.stopTest();

        // Verify
        System.assert(String.isNotBlank(result.chartDataJson), 'chartData JSON shouldn\'t be empty');
        System.assert(!result.xAxisValues.isEmpty(), 'x axis shouldn\'t be empty');
        for (String sprintDay : result.xAxisValues) {
            Date d = Date.parse(sprintDay);
            System.assert(s.Start_Date__c <= d, 'Returned Date is not part of the sprint');
            System.assert(d <= s.End_Date__c, 'Returned Date is not part of the sprint');
        }
    }

    @IsTest
    private static void testSaveChartData() {
        // Setup
        Sprint__c s = [SELECT Id, Start_Date__c, End_Date__c FROM Sprint__c WHERE Name = 'Sprint1' LIMIT 1];

        ChartController.ChartDataRequest request = new ChartController.ChartDataRequest();
        request.objectId = s.Id;
        request.type = SprintWallChartController.BURNDOWN_LINE_CHART;
        request.chartFileName = 'Test Get Chart Data.json';
        request.lastDayOfWeek = 'friday';
        request.plannedVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName();
        request.actualVelocityField = Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName();
        request.sprintPlannedVelocityField = Schema.SObjectType.Sprint__c.fields.Planned_Velocity__c.getName();
        request.sprintActualVelocityField = Schema.SObjectType.Sprint__c.fields.Actual_Velocity__c.getName();

        SprintSnapshotRecordsCollector.mockHistory = MOCK_HISTORY
            .replaceAll('RECORD_ID', request.objectId)
            .replaceAll('OBJECT_NAME', Schema.SObjectType.Burndown_Item__c.getName())
            .replaceAll('ACTUAL_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName())
            .replaceAll('PLANNED_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName());

        ChartController.ChartDataResponse resultGetData = SprintWallChartController.getChartData(JSON.serialize(request));

        // Exercise
        Test.startTest();
        SprintWallChartController.saveChartData(request.objectId, request.chartFileName, resultGetData.chartDataJson);
        Test.stopTest();

        // Verify
        ContentDocumentLink[] cdls = [
            SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE
                LinkedEntityId = :request.objectId
                AND (ContentDocument.Title = :request.chartFileName
                OR ContentDocument.Title = :request.chartFileName.substringBefore('.'))
            WITH SECURITY_ENFORCED
        ];
        System.assert(cdls != null && !cdls.isEmpty(), 'File should be linked to the record');

        ContentVersion[] cvs = [
            SELECT Id, ContentDocumentId, ContentBodyId, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :cdls[0].ContentDocumentId
            WITH SECURITY_ENFORCED
        ];
        System.assert(cvs != null && !cvs.isEmpty(), 'File should be linked to the record');

        String fileData = cvs[0].VersionData.toString();
        System.assertEquals(resultGetData.chartDataJson, fileData, 'Data from file doesn\'t match');
    }

    // PRIVATE

    private static void createData() {
        new Sprint()
            .name('Sprint1')
            .startDate(Date.today().addDays(-8))
            .endDate(Date.today().addDays(8))
            .status('In Progress')
            .add(new UserStory().title('US 1').status('Approved').storyPoints(2))
            .add(new UserStory().title('US 2').status('Draft').storyPoints(2))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}