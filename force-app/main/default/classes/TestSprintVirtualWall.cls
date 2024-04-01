@IsTest
public with sharing class TestSprintVirtualWall {
    static TestUtilities tu = new TestUtilities();

    @TestSetup
    static void setupData() {
        tu.insertSObject(
            'User',
            new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator']
                .Id,
                'LastName' => 'LastName',
                'Email' => 'test1@test1.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
            }
        );
        tu.insertSObject(
            'User',
            new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator']
                .Id,
                'LastName' => 'LastName',
                'Email' => 'test2@test2.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
            }
        );
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void sprintWallActualVelocityZero() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            List<SObject> insertSObjects = new List<SObject>();
            // Create 5 user story to fill sobjectlist
            insertSObjects.addAll(
                tu.createSObjects(
                    'User_Story__c',
                    5,
                    new Map<String, Object>{
                        'User_Story_Title__c' => 'us-0000000',
                        'Status__c' => 'Approved',
                        'Sprint__c' => tu.item('Sprint__c', 0).get('Id'),
                        'Story_Points_SFDC__c' => 2,
                        'Developer__c' => u.Id
                    }
                )
            );

            // Create previous sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{
                    'Name' => 'Sprint 1',
                    'Start_Date__c' => Date.today().addDays(-16),
                    'End_Date__c' => Date.today().addDays(-8)
                }
            );

            // Create 5 user story to previous sprint
            insertSObjects.addAll(
                tu.createSObjects(
                    'User_Story__c',
                    5,
                    new Map<String, Object>{
                        'User_Story_Title__c' => 'us-0000000',
                        'Status__c' => 'In Progress',
                        'Sprint__c' => tu.item('Sprint__c', 1).get('Id'),
                        'Story_Points_SFDC__c' => 3
                    }
                )
            );

            // Create next sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(8), 'End_Date__c' => Date.today().addDays(16) }
            );

            // Create 5 user story to next sprint
            insertSObjects.addAll(
                tu.createSObjects(
                    'User_Story__c',
                    5,
                    new Map<String, Object>{
                        'User_Story_Title__c' => 'us-0000000',
                        'Status__c' => 'Completed',
                        'Sprint__c' => tu.item('Sprint__c', 2).get('Id'),
                        'Story_Points_SFDC__c' => 4
                    }
                )
            );

            insert insertSObjects;

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);
            // Check if the user story wrapper list size 5.
            System.assertEquals(controller.usWrapperList.size(), 5);

            // Pagination setup and check the expected values
            Boolean nextDisabled = controller.getDisableNext();
            System.assertEquals(nextDisabled, true);
            Boolean previousDisabled = controller.getDisablePrevious();
            System.assertEquals(previousDisabled, true);
            Integer pageNumber = controller.getPageNumber();
            System.assertEquals(pageNumber, 1);
            Integer totalPageNumber = controller.getTotalPages();
            System.assertEquals(totalPageNumber, 1);

            // Sprint setup and check the expected values
            String nextSprint = controller.getNextSprint();
            System.assertEquals(nextSprint, tu.item('Sprint__c', 2).get('Id'));
            String previousSprint = controller.getPreviousSprint();
            System.assertEquals(previousSprint, tu.item('Sprint__c', 1).get('Id'));

            // Velocity setup and check the expected values
            controller.getDaysLeftString();
            Map<String, Decimal> velocityMap = controller.getCalculatedVelocities();
            System.assertEquals(velocityMap.get('actual'), 0);
            System.assertEquals(velocityMap.get('planned'), 10);

            // Chatter setup and validation
            controller.getIsChatterEnabled();

            // Pagination process
            controller.next();
            controller.previous();
            controller.end();
            controller.beginning();
            Test.stopTest();

            // New User Story
            ApexPages.currentPage().getParameters().put('mode', 'new');
            controller.prepareUserStory();
            controller.userStoryCreateOperation();
            System.assertEquals(nextSprint, tu.item('Sprint__c', 2).get('Id'));
        }
    }

    @isTest
    static void sprintWallUserStoryOperations() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            List<SObject> insertSObjects = new List<SObject>();
            // Create 5 user story to fill sobjectlist
            insertSObjects.addAll(
                tu.createSObjects(
                    'User_Story__c',
                    5,
                    new Map<String, Object>{
                        'User_Story_Title__c' => 'us-0000000',
                        'Status__c' => 'Approved',
                        'Sprint__c' => tu.item('Sprint__c', 0).get('Id'),
                        'Story_Points_SFDC__c' => 2,
                        'Developer__c' => u.Id,
                        'Order__c' => 1
                    }
                )
            );

            // Create previous sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{
                    'Name' => 'Sprint 1',
                    'Start_Date__c' => Date.today().addDays(-16),
                    'End_Date__c' => Date.today().addDays(-8)
                }
            );

            // Create 5 user story to previous sprint
            insertSObjects.addAll(
                tu.createSObjects(
                    'User_Story__c',
                    5,
                    new Map<String, Object>{
                        'User_Story_Title__c' => 'us-0000000',
                        'Status__c' => 'In Progress',
                        'Sprint__c' => tu.item('Sprint__c', 1).get('Id'),
                        'Story_Points_SFDC__c' => 3
                    }
                )
            );

            // Create next sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(8), 'End_Date__c' => Date.today().addDays(16) }
            );

            // Create 5 user story to next sprint
            insertSObjects.addAll(
                tu.createSObjects(
                    'User_Story__c',
                    5,
                    new Map<String, Object>{
                        'User_Story_Title__c' => 'us-0000000',
                        'Status__c' => 'Completed',
                        'Sprint__c' => tu.item('Sprint__c', 2).get('Id'),
                        'Story_Points_SFDC__c' => 4
                    }
                )
            );

            insert insertSObjects;

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Filter values setup and apply filter
            ApexPages.currentPage().getParameters().put('pRenderer', 'usWithFilter');
            controller.pageRendererAssignment();
            controller.pickListValuesWrapperList[0].isSelected = true;
            controller.usDevWrapperList[0].isSelected = true;
            controller.rtValuesWrapperList[0].isSelected = true;
            controller.applyFilter();
            System.assertEquals(controller.usWrapperList.size(), 0); // Check if the user story wrapper list size 0. Selected filters should return empty list.
            controller.refreshTable();
            controller.pickListValuesWrapperList[0].isSelected = false;
            controller.usDevWrapperList[0].isSelected = false;
            controller.rtValuesWrapperList[0].isSelected = false;
            controller.applyFilter();
            System.assertEquals(controller.usWrapperList.size(), 5); // Check if the user story wrapper list size 5.

            // User story operations
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 2).get('Id')));
            controller.moveUsToNextSprint();
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 3).get('Id')));
            controller.removeSprintFromUs();
            System.assertEquals(controller.usWrapperList.size(), 3); // Check if the user story wrapper list size 3.

            // User Story Edit
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 4).get('Id')));
            ApexPages.currentPage().getParameters().put('mode', 'edit');
            controller.prepareUserStory();
            System.assertEquals(controller.us.Id, String.valueOf(tu.item('User_Story__c', 4).get('Id')));
            controller.userStoryUpdateOperation();

            // User Story Mass Update
            controller.usWrapperList[1].isSelected = true;
            controller.usWrapperList[2].isSelected = true;
            ApexPages.currentPage().getParameters().put('mode', 'massupdate');
            controller.prepareUserStory();
            controller.us.Developer__c = u.Id;
            controller.userStoryUpdateOperation();
            Test.stopTest();
        }
    }

    @IsTest
    static void sprintWallActualVelocityNotZero() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).get('Id'),
                    'Story_Points_SFDC__c' => 2
                }
            );

            // Create previous sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{
                    'Name' => 'Sprint 1',
                    'Start_Date__c' => Date.today().addDays(-16),
                    'End_Date__c' => Date.today().addDays(-8)
                }
            );

            // Create attachment for sprint record to show burndown chart
            tu.insertSObject(
                'Attachment',
                new Map<String, Object>{
                    'Name' => 'BurnDownItem',
                    'Body' => Blob.valueOf(
                        '[{"idealValue":47388.00,"dates":"2018-05-28","actualValue":42450.00},{"idealValue":23694.00,"dates":"2018-05-29","actualValue":32645.00},{"idealValue":0.00,"dates":"2018-05-30","actualValue":8476.00}]'
                    ),
                    'ParentId' => tu.item('Sprint__c', 1).get('Id')
                }
            );

            // Create 5 user story to previous sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 1).get('Id'),
                    'Story_Points_SFDC__c' => 3
                }
            );

            // Create next sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(8), 'End_Date__c' => Date.today().addDays(16) }
            );

            // Create 5 user story to next sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 2).get('Id'),
                    'Story_Points_SFDC__c' => 4,
                    'Developer__c' => u.Id
                }
            );

            // Create 1 user story task to user story 3
            tu.insertSObjects(
                'User_Story_Task__c',
                1,
                new Map<String, Object>{
                    'Status__c' => 'In Progress',
                    'Subject__c' => 'Test',
                    'Hours_Remaining__c' => 2,
                    'User_Story__c' => tu.item('User_Story__c', 3).get('Id')
                }
            );

            // Create 3 burndownitem  for sprint
            tu.insertSObjects(
                'Burndown_Item__c',
                3,
                new Map<String, Object>{
                    'Sprint__c' => tu.item('Sprint__c', 2).get('Id'),
                    'Date__c' => Date.today().addDays(8),
                    'Expected_Story_Point__c' => 100,
                    'Total_Story_Point__c' => 90
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 2));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 5.
            System.assertEquals(controller.usWrapperList.size(), 5);

            // Pagination setup and check the expected values
            Boolean nextDisabled = controller.getDisableNext();
            System.assertEquals(nextDisabled, true);
            Boolean previousDisabled = controller.getDisablePrevious();
            System.assertEquals(previousDisabled, true);
            Integer pageNumber = controller.getPageNumber();
            System.assertEquals(pageNumber, 1);
            Integer totalPageNumber = controller.getTotalPages();
            System.assertEquals(totalPageNumber, 1);

            // Sprint setup and check the expected values
            String nextSprint = controller.getNextSprint();
            System.assertEquals(nextSprint, '');
            String previousSprint = controller.getPreviousSprint();
            System.assertEquals(previousSprint, tu.item('Sprint__c', 0).get('Id'));

            // Velocity setup and check the expected values
            String daysLeft = controller.getDaysLeftString();
            System.assertEquals(daysLeft, 'NOT STARTED');
            Map<String, Decimal> velocityMap = controller.getCalculatedVelocities();
            System.assertEquals(velocityMap.get('actual'), 20);
            System.assertEquals(velocityMap.get('planned'), 20);
            Test.stopTest();
        }
    }

    @isTest
    static void sprintWallUserStoryTaskOperations() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).get('Id'),
                    'Story_Points_SFDC__c' => 2
                }
            );

            // Create previous sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{
                    'Name' => 'Sprint 1',
                    'Start_Date__c' => Date.today().addDays(-16),
                    'End_Date__c' => Date.today().addDays(-8)
                }
            );

            // Create attachment for sprint record to show burndown chart
            tu.insertSObject(
                'Attachment',
                new Map<String, Object>{
                    'Name' => 'BurnDownItem',
                    'Body' => Blob.valueOf(
                        '[{"idealValue":47388.00,"dates":"2018-05-28","actualValue":42450.00},{"idealValue":23694.00,"dates":"2018-05-29","actualValue":32645.00},{"idealValue":0.00,"dates":"2018-05-30","actualValue":8476.00}]'
                    ),
                    'ParentId' => tu.item('Sprint__c', 1).get('Id')
                }
            );

            // Create 5 user story to previous sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 1).get('Id'),
                    'Story_Points_SFDC__c' => 3
                }
            );

            // Create next sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(8), 'End_Date__c' => Date.today().addDays(16) }
            );

            // Create 5 user story to next sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 2).get('Id'),
                    'Story_Points_SFDC__c' => 4,
                    'Developer__c' => u.Id
                }
            );

            // Create 1 user story task to user story 3
            tu.insertSObjects(
                'User_Story_Task__c',
                1,
                new Map<String, Object>{
                    'Status__c' => 'In Progress',
                    'Subject__c' => 'Test',
                    'Hours_Remaining__c' => 2,
                    'User_Story__c' => tu.item('User_Story__c', 3).get('Id')
                }
            );

            // Create 3 burndownitem  for sprint
            tu.insertSObjects(
                'Burndown_Item__c',
                3,
                new Map<String, Object>{
                    'Sprint__c' => tu.item('Sprint__c', 2).get('Id'),
                    'Date__c' => Date.today().addDays(8),
                    'Expected_Story_Point__c' => 100,
                    'Total_Story_Point__c' => 90
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 2));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Sprint operations (Next sprint, Previous sprint)
            ApexPages.currentPage().getParameters().put('sprMode', 'previous');
            controller.goToStandardRecordView();
            ApexPages.currentPage().getParameters().put('sprMode', '');
            controller.goToStandardRecordView();

            // User story task operations
            ApexPages.currentPage().getParameters().put('pSwitcher', 'snippet');
            controller.pageSwithcerAssignment();
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 3).get('Id')));
            controller.prepareUserStoryTask();
            controller.userStoryTaskOperation();

            System.assertEquals('Not Started', controller.usTask.Status__c);

            // Edit user story task
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 3).get('Id')));
            ApexPages.currentPage().getParameters().put('usTaskId', String.valueOf(tu.item('User_Story_Task__c', 0).get('Id')));
            controller.prepareUserStoryTask();
            controller.userStoryTaskOperation();

            SprintVirtualWall.updateRecordsPicklistValue(String.valueOf(tu.item('User_Story_Task__c', 0).get('Id')), 'Completed');

            // Delete user story task
            controller.userStoryTaskDeletion();

            // Check the burndown item chart
            controller.getData();
            Test.stopTest();
        }
    }

    @IsTest
    static void sprintWallBurnDownForClosedSprint() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).get('Id'),
                    'Story_Points_SFDC__c' => 2
                }
            );

            // Create previous sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{
                    'Name' => 'Sprint 1',
                    'Start_Date__c' => Date.today().addDays(-16),
                    'End_Date__c' => Date.today().addDays(-8)
                }
            );

            // Create attachment for sprint record to show burndown chart
            tu.insertSObject(
                'Attachment',
                new Map<String, Object>{
                    'Name' => 'BurnDownItems',
                    'Body' => Blob.valueOf(
                        '[{"idealValue":47388.00,"dates":"2018-05-28","actualValue":42450.00},{"idealValue":23694.00,"dates":"2018-05-29","actualValue":32645.00},{"idealValue":0.00,"dates":"2018-05-30","actualValue":8476.00}]'
                    ),
                    'ParentId' => tu.item('Sprint__c', 1).get('Id')
                }
            );

            // Create 5 user story to previous sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 1).get('Id'),
                    'Story_Points_SFDC__c' => 3
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 1));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 5.
            System.assertEquals(controller.usWrapperList.size(), 5);

            // Check the burndown item chart
            controller.getData();
            Test.stopTest();
        }
    }

    @IsTest
    static void sprintWallMassUpdate() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            // Create previous sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{
                    'Name' => 'Sprint 1',
                    'Start_Date__c' => Date.today().addDays(-16),
                    'End_Date__c' => Date.today().addDays(-8)
                }
            );

            // Create 5 user story to previous sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 1).Id,
                    'Story_Points_SFDC__c' => 3
                }
            );

            // Create next sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(8), 'End_Date__c' => Date.today().addDays(16) }
            );

            // Create 5 user story to next sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 2).Id,
                    'Story_Points_SFDC__c' => 4
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 5.
            System.assertEquals(controller.usWrapperList.size(), 5);

            // User Story Mass Update
            for (Integer i = 0; i < 5; i++) {
                controller.usWrapperList[i].isSelected = true;
            }
            ApexPages.currentPage().getParameters().put('mode', 'massupdate');
            controller.prepareUserStory();
            System.assertEquals(controller.usWrapperList[3].userStory.Developer__c, String.valueOf(u.Id));
            controller.us.Status__c = 'Draft';
            controller.userStoryUpdateOperation();
            System.assertEquals(controller.usWrapperList[3].userStory.Status__c, 'Draft');
            Test.stopTest();
        }
    }

    @IsTest
    static void completeSprintSplitAndMove() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id,
                    'Progress__c' => 60
                }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            // Create next sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(8), 'End_Date__c' => Date.today().addDays(16) }
            );

            // Create 5 user story to next sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 1).Id,
                    'Story_Points_SFDC__c' => 4
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 15.
            System.assertEquals(controller.usWrapperList.size(), 15);

            // Populate modal values
            Integer completedUs = controller.getCompletedUsNumber();
            System.assertEquals(5, completedUs);
            Integer inCompletedUs = controller.getInCompletedUsNumber();
            System.assertEquals(10, inCompletedUs);
            List<SelectOption> optList = controller.getSprintCompleteOptions();
            System.assertEquals(optList.size(), 3);

            // complete sprint and check the number based on status
            controller.selectedSprintCompleteOption = 'splitmove';
            controller.completeSprint();
            Integer newCompletedUs = controller.getCompletedUsNumber();
            System.assertEquals(10, newCompletedUs);

            Test.stopTest();
        }
    }

    @IsTest
    static void completeSprintBacklog() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 10.
            System.assertEquals(controller.usWrapperList.size(), 10);

            // Populate modal values
            Integer completedUs = controller.getCompletedUsNumber();
            System.assertEquals(completedUs, 5);
            Integer inCompletedUs = controller.getInCompletedUsNumber();
            System.assertEquals(inCompletedUs, 5);
            List<SelectOption> optList = controller.getSprintCompleteOptions();
            System.assertEquals(optList.size(), 1);

            // complete sprint and check the number based on status
            controller.selectedSprintCompleteOption = 'backlog';
            controller.completeSprint();
            Integer newCompletedUs = controller.getCompletedUsNumber();
            System.assertEquals(newCompletedUs, 5);

            Test.stopTest();
        }
    }

    @IsTest
    static void completeSprintNextSprint() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'In Progress',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            // Create next sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(8), 'End_Date__c' => Date.today().addDays(16) }
            );

            // Create 5 user story to next sprint
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Completed',
                    'Sprint__c' => tu.item('Sprint__c', 1).Id,
                    'Story_Points_SFDC__c' => 4
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 10.
            System.assertEquals(controller.usWrapperList.size(), 10);

            // Populate modal values
            Integer completedUs = controller.getCompletedUsNumber();
            System.assertEquals(completedUs, 5);
            Integer inCompletedUs = controller.getInCompletedUsNumber();
            System.assertEquals(inCompletedUs, 5);
            List<SelectOption> optList = controller.getSprintCompleteOptions();
            System.assertEquals(optList.size(), 3);

            // complete sprint and check the number based on status
            controller.selectedSprintCompleteOption = 'nextsprint';
            controller.completeSprint();
            Integer newCompletedUs = controller.getCompletedUsNumber();
            System.assertEquals(newCompletedUs, 5);

            Test.stopTest();
        }
    }

    @IsTest
    static void sprintWallKanbanBoard() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );

            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 5.
            System.assertEquals(controller.usWrapperList.size(), 5);

            controller.kanbanBoardOperations();
            Test.stopTest();
        }
    }

    @IsTest
    static void sprintWallOrder() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create 5 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                5,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => u.Id
                }
            );
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 5.
            System.assertEquals(controller.usWrapperList.size(), 5);

            ApexPages.currentPage().getParameters().put('newUSOrder', '[2,3,4,1]');
            ApexPages.currentPage().getParameters().put('oldUSOrder', '[1,2,3,4]');
            controller.updateUSOrder();
            Test.stopTest();
        }
    }
}