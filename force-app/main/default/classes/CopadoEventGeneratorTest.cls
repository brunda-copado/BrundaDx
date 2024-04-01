@IsTest
public with sharing class CopadoEventGeneratorTest {
    private static String namespace = Settings.ns;

    @TestSetup
    public static void setUpData() {
        createUserSetup();
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        System.runAs(sysUser) {
            createSettings();
            createEventConditionsAndItems();
        }
    }

    @IsTest
    public static void returnEventDecisionForThirdPartyUsage(){
        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        User_Story__c userStory = getUserStory(bugRecordTypeId, 'In Progress');
        insert userStory;
        Map<Id, SObject> newMap = (Map<Id, SObject>)Json.deserialize('{"'+userStory.Id+'":{"attributes":{"type":"'+namespace+'User_Story__c","url":"/services/data/v52.0/sobjects/'+namespace+'User_Story__c/a171n00000DAag0AAD"},"'+namespace+'Manual_Tests_Passed__c":false,"LastModifiedDate":"2021-07-14T14:20:11.000+0000","'+namespace+'Promote_Change__c":true,"'+namespace+'Minimum_Apex_Code_Coverage__c":75,"'+namespace+'Data_Privacy__c":false,"'+namespace+'Compliance__c":false,"'+namespace+'Is_Bundle__c":false,"'+namespace+'Progress__c":15,"Name":"US-0068692","'+namespace+'Total_Story_Points__c":0,"OwnerId":"0050Y000003zoJsQAI","CreatedById":"0050Y000003zoJsQAI","RecordTypeId":"'+bugRecordTypeId+'","'+namespace+'Promotion_Test_Level__c":"NoTestRun","'+namespace+'Apex_Tests_Passed__c":false,"'+namespace+'Exclude_From_CBM__c":false,"IsDeleted":false,"'+namespace+'QR_Code__c":"_IM1_https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl=https%3A%2F%2Fcopado-dev-10-dev-ed.my.salesforce.com/a171n00000DAag0_IM2_Scan the QR code to create contact in your mobile_IM3_","SystemModstamp":"2021-07-14T14:20:11.000+0000","'+namespace+'User_Story_Title__c":"Hello","'+namespace+'Validate_Only__c":false,"'+namespace+'Stop_Indexing_Metadata__c":false,"'+namespace+'Progress_Status__c":"_IM1_/img/samples/color_green.gif_IM2_Completed_IM3__15_IM4_30.00_IM5__IM1_/img/samples/color_yellow.gif_IM2_white_IM3__15_IM4_170.00_IM5_","'+namespace+'Pull_Requests_Approved__c":false,"'+namespace+'Legal__c":false,"'+namespace+'Documentation_Complete__c":false,"'+namespace+'Has_Apex_Code__c":false,"CreatedDate":"2021-05-20T13:18:49.000+0000","'+namespace+'Manual_Step_Required__c":false,"'+namespace+'Promote_as_Single_Step__c":false,"Id":"'+userStory.Id+'","'+namespace+'Promote_and_Deploy__c":false,"'+namespace+'Status__c":"Backburner","LastModifiedById":"0050Y000003zoJsQAI","'+namespace+'View_in_Git__c":"_HL_ENCODED_ _HL_feature/US-0068692_HL__blank_HL_"}}', Map<Id, Sobject>.class);
        Map<Id, SObject> oldMap = (Map<Id, SObject>)Json.deserialize('{"'+userStory.Id+'":{"attributes":{"type":"'+namespace+'User_Story__c","url":"/services/data/v52.0/sobjects/'+namespace+'User_Story__c/a171n00000DAag0AAD"},"'+namespace+'Manual_Tests_Passed__c":false,"LastModifiedDate":"2021-07-14T14:15:34.000+0000","'+namespace+'Promote_Change__c":true,"'+namespace+'Minimum_Apex_Code_Coverage__c":75,"'+namespace+'Data_Privacy__c":false,"'+namespace+'Compliance__c":false,"'+namespace+'Is_Bundle__c":false,"'+namespace+'Progress__c":15,"Name":"US-0068692","'+namespace+'Total_Story_Points__c":0,"OwnerId":"0050Y000003zoJsQAI","CreatedById":"0050Y000003zoJsQAI","RecordTypeId":"'+bugRecordTypeId+'","'+namespace+'Promotion_Test_Level__c":"NoTestRun","'+namespace+'Apex_Tests_Passed__c":false,"'+namespace+'Exclude_From_CBM__c":false,"IsDeleted":false,"'+namespace+'QR_Code__c":"_IM1_https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl=https%3A%2F%2Fcopado-dev-10-dev-ed.my.salesforce.com/a171n00000DAag0_IM2_Scan the QR code to create contact in your mobile_IM3_","SystemModstamp":"2021-07-14T14:15:34.000+0000","'+namespace+'User_Story_Title__c":"Hello","'+namespace+'Validate_Only__c":false,"'+namespace+'Stop_Indexing_Metadata__c":false,"'+namespace+'Progress_Status__c":"_IM1_/img/samples/color_green.gif_IM2_Completed_IM3__15_IM4_30.00_IM5__IM1_/img/samples/color_yellow.gif_IM2_white_IM3__15_IM4_170.00_IM5_","'+namespace+'Pull_Requests_Approved__c":false,"'+namespace+'Legal__c":false,"'+namespace+'Documentation_Complete__c":false,"'+namespace+'Has_Apex_Code__c":false,"CreatedDate":"2021-05-20T13:18:49.000+0000","'+namespace+'Manual_Step_Required__c":false,"'+namespace+'Promote_as_Single_Step__c":false,"Id":"'+userStory.Id+'","'+namespace+'Promote_and_Deploy__c":false,"'+namespace+'Status__c":"Awaiting Approval","LastModifiedById":"0050Y000003zoJsQAI","'+namespace+'View_in_Git__c":"_HL_ENCODED_ _HL_feature/US-0068692_HL__blank_HL_"}}', Map<Id, SObject>.class);
        List<Object> objects = CopadoEventDecisionClassifier.getEventDecisions(newMap, oldMap, 'AFTER_UPDATE');
        System.assertEquals(1, objects.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!'); 
    }

    @IsTest
    public static void generateEventForUserStory() {
        Test.startTest();
        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        insert getUserStory(bugRecordTypeId, 'Draft');
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        Test.stopTest();
    }

    @IsTest
    public static void generateEventForUserStoryWhiteSpaceRemovalFix() {
        Test.startTest();
        String name = namespace + 'User_Story__c';
        Data_Change_Event_Condition__c eventCondition = [SELECT Id, Name, Condition_Logic__c FROM Data_Change_Event_Condition__c WHERE Name = :name];
        eventCondition.Condition_Logic__c = '1 AND ((2 AND 3) OR (4 and 5))';
        update eventCondition;
        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        insert getUserStory(bugRecordTypeId, 'In Progress');
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        Test.stopTest();
    }

    @IsTest
    public static void doNotGenerateEventForUserStoryWithoutValidCriteriaItems() {
        Test.startTest();
        String name = namespace + 'User_Story__c';
        Data_Change_Event_Condition__c eventCondition = [SELECT Id, Name, Condition_Logic__c FROM Data_Change_Event_Condition__c WHERE Name = :name];
        eventCondition.Condition_Logic__c = '1 AND ((2 AND 3) OR (4 AND 5)) AND 7';
        update eventCondition;
        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        insert getUserStory(bugRecordTypeId, 'In Progress');
        System.assertEquals(null, CopadoEventGenerator.eventsToPublish, 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        Test.stopTest();
    }

    @IsTest
    public static void doNotGenerateEventForUserStoryWithInvalidConditionLogic() {
        Test.startTest();
        String name = namespace + 'User_Story__c';
        Data_Change_Event_Condition__c eventCondition = [SELECT Id, Name, Condition_Logic__c FROM Data_Change_Event_Condition__c WHERE Name = :name];
        eventCondition.Condition_Logic__c = '1 AND 2 OR 3 AND (4 OR 5)';
        update eventCondition;
        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        insert getUserStory(bugRecordTypeId, 'In Progress');
        System.assertEquals(null, CopadoEventGenerator.eventsToPublish, 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        Test.stopTest();
    }
    
    @IsTest
    public static void generateEventForUserStoryNotEqualsAddition() {
        String name = namespace + 'User_Story__c';
        Data_Change_Event_Condition__c eventCondition = [SELECT Id, Name, Condition_Logic__c FROM Data_Change_Event_Condition__c WHERE Name = :name];
        eventCondition.Condition_Logic__c = '1 AND ((2 AND 3) OR (4 AND 5))';
        update eventCondition;
        Data_Change_Event_Condition_Items__c conditionItem = [SELECT Id, Filter_Condition__c FROM Data_Change_Event_Condition_Items__c WHERE Event_Condition_Id__c = : eventCondition.Id AND Filter_Order__c = 1];
        conditionItem.Filter_Condition__c = namespace + 'Status__c,notequals,In progress';
        update conditionItem;

        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        insert getUserStory(bugRecordTypeId, 'Draft');
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void generateEventForProject() {
        insert new Project__c(
            Name = 'JIRA Project',
            Status__c = 'In Progress'
        );
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void generateEventForRelease() {
        insert new Release__c(
            Name = 'v1',
            Version__c = '1.0.0',
            Status__c = 'Planned'
        );
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void doNotGenerateEventForRelease() {
        insert new Release__c(
            Name = 'v1',
            Version__c = '1.0.0'
        );
        System.assertEquals(null, CopadoEventGenerator.eventsToPublish, 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void generateEventForEpic() {
        insert new Epic__c(
            Epic_Title__c = 'JIRA Kickoff',
            Status__c = 'In progress'
        );
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void generateEventForSprint() {
        insert new Sprint__c(
            Name = 'Sprint 1(current)',
            Status__c = 'In progress'
        );
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void doNotGenerateEventForSprint() {
        insert new Sprint__c(
            Name = 'Sprint 1(current)',
            Status__c = null
        );
        System.assertEquals(null, CopadoEventGenerator.eventsToPublish, 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void generateEventForPipeline() {
        insert new Deployment_Flow__c(
            Name = 'JIRA Project',
            Active__c = true
        );
        System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }   

    @IsTest
    public static void generateEventForPipelineConnections(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        System.runAs(sysUser) {
            List<Deployment_Flow_Step__c> pipelineConnections = getpipelineConnectionsData(sysUser.Username).pipelineConnections;
            insert pipelineConnections;
            System.assertEquals(2, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        }
    }

    @IsTest
    public static void generateEventForOrgCredentials(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = getEnvironmentData();
            insert environments;

            // Org Credential creation
            TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);
            System.assertEquals(3, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        }
    }

    @IsTest
    public static void generateEventForEnvironment(){
        insert getEnvironmentData();
        System.assertEquals(3, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }

    @IsTest
    public static void generateEventForPromotion(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        System.runAs(sysUser) {
            insert getPromotionData();
             System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        }
    }

    @IsTest 
    public static void generateEventForDeployment(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        System.runAs(sysUser) {
            TestDataDTO data = getpipelineConnectionsData(sysUser.Username);
            insert data.pipelineConnections;
            Promotion__c promotion = getPromotionDataViaTestDataDTO(data);
            insert promotion;
            Deployment__c deployment = getDeployment(promotion, data.orgCredentials[1]);
            insert deployment;
            System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
            
            deployment.Name = 'Test';
            update deployment;
            System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        }
    }

    @IsTest
    public static void generateEventForDeploymentStep(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        System.runAs(sysUser) {
            String expectedName = namespace + 'Deployment__c';
            changeConditionActivation(expectedName, false);
            
            TestDataDTO data = getpipelineConnectionsData(sysUser.Username);
            insert data.pipelineConnections;
            Promotion__c promotion = getPromotionDataViaTestDataDTO(data);
            insert promotion;
            Deployment__c deployment = getDeployment(promotion, data.orgCredentials[1]);
            insert deployment;
            
            insert getDeploymentSteps(deployment);
            System.assertEquals(200, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        }
    }
    
    @IsTest 
    public static void generateEventsForPromotedUserStories(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        User_Story__c userStory = getUserStory(bugRecordTypeId, 'Draft');
        insert userStory;
        System.runAs(sysUser) {
            String expectedName = namespace + 'Promotion__c';
            changeConditionActivation(expectedName, false);
            Promotion__c promotion = getPromotionData();
            insert promotion;
            
            insert new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id);
            System.assertEquals(1, CopadoEventGenerator.eventsToPublish.size(), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        }
    }

    @IsTest
    public static void doNotGenerateEvent() {
        Settings__c setting = Settings__c.getOrgDefaults();
        setting.Disable_All_Copado_Events__c = true;
        update setting;

        Id bugRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        try{
        insert new User_Story__c(
            RecordTypeId = bugRecordTypeId,
            User_Story_Title__c = 'User Story Insert', 
            Story_Points_SFDC__c = 3,
            Priority__c = 3, 
            Status__c = 'Draft',
            Developer__c = UserInfo.getUserId()
        );
        } catch(Exception ex){
            System.assertEquals(TRUE, ex.getMessage().contains('Event generation is disabled on the organization level. Please contact with your admin!'), 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
        }
        System.assertEquals(null, CopadoEventGenerator.eventsToPublish, 'There is something wrong in either CopadoEventGenerator or CopadoEventDecisionClassifier!');
    }


    //Helper methods
    private static void createSettings(){
        Settings__c setting = new Settings__c(
            Namespace__c = 'none',
            CCM_Licenses__c = 50,
            Copado_Licenses__c = 50,
            CST_Licenses__c = 50,
            Server_URL__c = 'https://na.api.copado.com',
            SetupOwnerId = UserInfo.getOrganizationId(),
            Disable_All_Copado_Events__c = false
        );
        insert setting;
    }

    private static void createEventConditionsAndItems(){
        List<Data_Change_Event_Condition__c> conditions = new List<Data_Change_Event_Condition__c>();
        Data_Change_Event_Condition__c userStoryCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'User_Story__c',
            Allow_All_Data__c = false,
            Object_Api_Name__c = namespace + 'User_Story__c',
            Record_Type_Developer_Name__c = 'Bug',
            Subscriber_Code__c = 'JIRA',
            Condition_Logic__c = '1 OR ((2 AND 3) OR (4 AND 5))',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(userStoryCondition);
        Data_Change_Event_Condition__c projectCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Project__c',
            Allow_All_Data__c = false,
            Object_Api_Name__c = namespace + 'Project__c',
            Subscriber_Code__c = 'JIRA',
            Condition_Logic__c = '1 OR (2 AND 3)',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(projectCondition);
        Data_Change_Event_Condition__c sprintCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Sprint__c',
            Allow_All_Data__c = false,
            Object_Api_Name__c = namespace + 'Sprint__c',
            Subscriber_Code__c = 'JIRA',
            Condition_Logic__c = '1 OR (2 AND 3)',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(sprintCondition);
        Data_Change_Event_Condition__c epicCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Epic__c',
            Allow_All_Data__c = false,
            Object_Api_Name__c = namespace + 'Epic__c',
            Subscriber_Code__c = 'JIRA',
            Condition_Logic__c = '1 OR (2 AND 3)',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(epicCondition);
        Data_Change_Event_Condition__c releaseCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Release__c',
            Allow_All_Data__c = false,
            Object_Api_Name__c = namespace + 'Release__c',
            Subscriber_Code__c = 'JIRA',
            Condition_Logic__c = '1 OR (2 AND 3)',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(releaseCondition);
        Data_Change_Event_Condition__c pipelineCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Deployment_Flow__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Deployment_Flow__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(pipelineCondition);
        Data_Change_Event_Condition__c pipelineConnectionCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Deployment_Flow_Step__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Deployment_Flow_Step__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(pipelineConnectionCondition);
        Data_Change_Event_Condition__c promotionCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Promotion__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Promotion__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(promotionCondition);
        Data_Change_Event_Condition__c deploymentCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Deployment__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Deployment__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(deploymentCondition);
        Data_Change_Event_Condition__c stepCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Step__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Step__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(stepCondition);
        Data_Change_Event_Condition__c promotedUserStoryCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Promoted_User_Story__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Promoted_User_Story__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(promotedUserStoryCondition);
        Data_Change_Event_Condition__c environmentCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Environment__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Environment__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(environmentCondition);
        Data_Change_Event_Condition__c orgCredentialCondition = new Data_Change_Event_Condition__c(
            Name = namespace + 'Org__c',
            Allow_All_Data__c = true,
            Object_Api_Name__c = namespace + 'Org__c',
            Subscriber_Code__c = 'Copado',
            Insert__c = true,
            Update__c = true,
            Delete__c = true,
            Undelete__c = true
        );
        conditions.add(orgCredentialCondition);
        for(Data_Change_Event_Condition__c condition : conditions){
            condition.Condition_Key__c = condition.Object_Api_Name__c + '-' + condition.Record_Type_Developer_Name__c + '-' + condition.Subscriber_Code__c;
        }
        insert conditions;

        //User Story Condition Items
        List<Data_Change_Event_Condition_Items__c> conditionItems = new List<Data_Change_Event_Condition_Items__c>();
        Data_Change_Event_Condition_Items__c userStoryConditionItem1 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = userStoryCondition.Id,
            Filter_Order__c = 1,
            Filter_Condition__c = namespace + 'Promote_Change__c,equals,true'
        ); 
        conditionItems.add(userStoryConditionItem1);
        Data_Change_Event_Condition_Items__c userStoryConditionItem2 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = userStoryCondition.Id,
            Filter_Order__c = 2,
            Filter_Condition__c = namespace + 'Status__c,isnull,false'
        ); 
        conditionItems.add(userStoryConditionItem2);
        Data_Change_Event_Condition_Items__c userStoryConditionItem3 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = userStoryCondition.Id,
            Filter_Order__c = 3,
            Filter_Condition__c = namespace + 'Status__c,ischanged,true'
        ); 
        conditionItems.add(userStoryConditionItem3);
        Data_Change_Event_Condition_Items__c userStoryConditionItem4 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = userStoryCondition.Id,
            Filter_Order__c = 4,
            Filter_Condition__c = namespace + 'Story_Points_SFDC__c,greater,3'
        ); 
        conditionItems.add(userStoryConditionItem4);
        Data_Change_Event_Condition_Items__c userStoryConditionItem5 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = userStoryCondition.Id,
            Filter_Order__c = 5,
            Filter_Condition__c = namespace + 'Priority__c,less,3'
        ); 
        conditionItems.add(userStoryConditionItem5);
        
        //Project Condition Items
        Data_Change_Event_Condition_Items__c projectConditionItem1 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = projectCondition.Id,
            Filter_Order__c = 1,
            Filter_Condition__c = namespace + 'Status__c,equals,In progress'
        ); 
        conditionItems.add(projectConditionItem1);
        Data_Change_Event_Condition_Items__c projectConditionItem2 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = projectCondition.Id,
            Filter_Order__c = 2,
            Filter_Condition__c = namespace + 'Status__c,isnull,false'
        ); 
        conditionItems.add(projectConditionItem2);
        Data_Change_Event_Condition_Items__c projectConditionItem3 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = projectCondition.Id,
            Filter_Order__c = 3,
            Filter_Condition__c = namespace + 'Status__c,ischanged,true'
        ); 
        conditionItems.add(projectConditionItem3);
        
        //Release Condition Items
        Data_Change_Event_Condition_Items__c releaseConditionItem1 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = releaseCondition.Id,
            Filter_Order__c = 1,
            Filter_Condition__c = namespace + 'Status__c,equals,Planned'
        ); 
        conditionItems.add(releaseConditionItem1);
        Data_Change_Event_Condition_Items__c releaseConditionItem2 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = releaseCondition.Id,
            Filter_Order__c = 2,
            Filter_Condition__c = namespace + 'Status__c,isnull,false'
        ); 
        conditionItems.add(releaseConditionItem2);
        Data_Change_Event_Condition_Items__c releaseConditionItem3 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = releaseCondition.Id,
            Filter_Order__c = 3,
            Filter_Condition__c = namespace + 'Status__c,ischanged,true'
        ); 
        conditionItems.add(releaseConditionItem3);
        
        //Sprint Condition Items
        Data_Change_Event_Condition_Items__c sprintConditionItem1 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = sprintCondition.Id,
            Filter_Order__c = 1,
            Filter_Condition__c = namespace + 'Status__c,equals,In Progress'
        ); 
        conditionItems.add(sprintConditionItem1);
        Data_Change_Event_Condition_Items__c sprintConditionItem2 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = sprintCondition.Id,
            Filter_Order__c = 2,
            Filter_Condition__c = namespace + 'Status__c,isnull,false'
        ); 
        conditionItems.add(sprintConditionItem2);
        Data_Change_Event_Condition_Items__c sprintConditionItem3 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = sprintCondition.Id,
            Filter_Order__c = 3,
            Filter_Condition__c = namespace + 'Status__c,ischanged,true'
        ); 
        conditionItems.add(sprintConditionItem3);

        //Epic Condition Items
        Data_Change_Event_Condition_Items__c epicConditionItem1 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = epicCondition.Id,
            Filter_Order__c = 1,
            Filter_Condition__c = namespace + 'Status__c,equals,In Progress'
        ); 
        conditionItems.add(epicConditionItem1);
        Data_Change_Event_Condition_Items__c epicConditionItem2 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = epicCondition.Id,
            Filter_Order__c = 2,
            Filter_Condition__c = namespace + 'Status__c,isnull,false'
        ); 
        conditionItems.add(epicConditionItem2);
        Data_Change_Event_Condition_Items__c epicConditionItem3 = new Data_Change_Event_Condition_Items__c(
            Event_Condition_Id__c = epicCondition.Id,
            Filter_Order__c = 3,
            Filter_Condition__c = namespace + 'Status__c,ischanged,true'
        ); 
        conditionItems.add(epicConditionItem3);
        for(Data_Change_Event_Condition_Items__c conditionItem : conditionItems){
            conditionItem.Name = conditionItem.Event_Condition_Id__c + conditionItem.Filter_Order__c;
        }
        insert conditionItems;
    }

    private static void createUserSetup(){
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User','Copado_Function','Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    private static User_Story__c getUserStory(Id recordTypeId, String status){
        return new User_Story__c(
            RecordTypeId = recordTypeId,
            User_Story_Title__c = 'User Story Insert', 
            Story_Points_SFDC__c = 3,
            Promote_Change__c = true,
            Priority__c = 3, 
            Status__c = status,
            Developer__c = UserInfo.getUserId()
        );
    }

    private static List<Environment__c> getEnvironmentData(){
        List<Environment__c> environments = new List<Environment__c>();
        for (Integer i = 0; i < 3; i++) {
            Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
            environments.add(environment);
        }
        return environments;
    }   

    private static TestDataDTO getpipelineConnectionsData(String username) {
        //Environment creation
        List<Environment__c> environments = getEnvironmentData();
        insert environments;

        // Org Credential creation
        List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, username, environments);

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
        deploymentFlowStep2.Branch__c = 'dev2';

        TestDataDTO data = new TestDataDTO(
            new List<Deployment_Flow_Step__c>{deploymentFlowStep1, deploymentFlowStep2},
            deploymentFlow,
            environments,
            credentials
        );
        return data;
    }

    private static Promotion__c getPromotionData(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        System.runAs(sysUser) {
            TestDataDTO data = getpipelineConnectionsData(sysUser.Username);

            insert data.pipelineConnections;

            
            return getPromotionDataViaTestDataDTO(data);
        }
        return null;
    }

    private static Promotion__c getPromotionDataViaTestDataDTO(TestDataDTO data){
        // Project creation
        Project__c project = TestDataFactory.createProject('My project', data.pipeline.Id, false);
        insert project;

        // Promotion creation
        Promotion__c promotion = TestDataFactory.createPromotion(
            project.Id,
            data.orgCredentials[2].Id,
            data.environments[2].Id,
            data.orgCredentials[1].Id,
            data.environments[1].Id,
            'Draft'
        );

        return promotion;
    }

    private static Deployment__c getDeployment(Promotion__c promotion, Org__c orgCredential){
        // Deployment creation
        String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
        .get('Advanced_multi_step')
        .getRecordTypeId();
        Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, orgCredential.Id);
        deployment.Date__c = System.now();
        deployment.Deployment_command_sent__c = System.now();
        deployment.Schedule__c = 'Deploy now';
        deployment.Status__c = 'Pending';
        deployment.Promotion__c = promotion.Id;
        return deployment;
    }

    private static List<Step__c> getDeploymentSteps(Deployment__c deployment){
        List<Step__c> steps = new List<Step__c>();
        for (Integer i = 0; i < 200; i++) {
            Step__c step = TestMethodUtilities.create('Step ' + i, 'attId', 'JSONString', deployment.Id, 0, 'Not started', 'Manual Task');
            steps.add(step);
        }
        return steps;
    }

    private static void changeConditionActivation(String ObjectName, Boolean activationStatus){
        Data_Change_Event_Condition__c deploymentEventCS = [SELECT Id, Allow_All_Data__c FROM Data_Change_Event_Condition__c WHERE Name = : ObjectName LIMIT 1];
            deploymentEventCS.Allow_All_Data__c = activationStatus;
            update deploymentEventCS;
    }

    private class TestDataDTO {
        public List<Deployment_Flow_Step__c> pipelineConnections;
        public Deployment_Flow__c pipeline;
        public List<Environment__c> environments;
        public List<Org__c> orgCredentials;
        public TestDataDTO(List<Deployment_Flow_Step__c> pipelineConnections, Deployment_Flow__c pipeline, List<Environment__c> environments, List<Org__c> orgCredentials){
            this.pipelineConnections = pipelineConnections;
            this.pipeline = pipeline;
            this.environments = environments;
            this.orgCredentials = orgCredentials;
        }
    }
}