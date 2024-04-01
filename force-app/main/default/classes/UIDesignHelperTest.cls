@IsTest
public with sharing class UIDesignHelperTest {
    
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
        }
    }
    
    @IsTest
    static void testWarningMessageOLSFLS() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            UIDesignHelper.warningMessageOLSFLS('Sprint__c');
            Test.stopTest();

            // Verify
            System.assertEquals(2, ApexPages.getMessages().size(), 'There should be error messages');
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.Insufficient_Access_Rights), 'There should be access issue');
        }
    }
    
    @IsTest
    static void testWarningAlertsOLSFLS() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            List<UIDesignHelper.AlertWrapper> alerts = UIDesignHelper.warningAlertsOLSFLS('Sprint__c');
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            UIDesignHelper.warningAlertsOLSFLS('Sprint__c');
            Test.stopTest();

            // Verify
            System.assertEquals(1, alerts.size(), 'There should be error messages');
            System.assertEquals(2, ApexPages.getMessages().size(), 'There should be error messages');
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.Insufficient_Access_Rights), 'There should be access issue');
        }
    }

    @IsTest
    static void testGenericWarningMessage() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, 'There is an error');
            Test.stopTest();

            // Verify
            System.assertEquals(1, ApexPages.getMessages().size(), 'There should be error message');
            System.assert(ApexPages.getMessages()[0].getDetail().contains('There is an error'), 'There should be an error');
        }
    }
    
    @IsTest
    static void testGenericWarningAlert() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            UIDesignHelper.AlertWrapper alert = UIDesignHelper.genericWarningAlert(ApexPages.Severity.ERROR, 'There is an error');
            UIDesignHelper.genericWarningAlert(ApexPages.Severity.CONFIRM, 'There is a success');
            UIDesignHelper.genericWarningAlert(ApexPages.Severity.FATAL, 'There is an Fatal error');
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            UIDesignHelper.genericWarningAlert(ApexPages.Severity.ERROR, 'There is an error');
            Test.stopTest();

            // Verify
            System.assertEquals(alert.message, 'There is an error', 'There should be an error');
            System.assertEquals(1, ApexPages.getMessages().size(), 'There should be error message');
            System.assert(ApexPages.getMessages()[0].getDetail().contains('There is an error'), 'There should be an error');
        }
    }
    
    @IsTest
    static void testGenericWarningAlertBlocker() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            UIDesignHelper.AlertWrapper alert = UIDesignHelper.genericWarningAlert(ApexPages.Severity.ERROR, 'There is an error', true);
            Test.stopTest();

            // Verify
            System.assertEquals(alert.message, 'There is an error', 'There should be an error');
            System.assertEquals(alert.isBlocker, true, 'There should be a blocker error');
        }
    }
    
    @IsTest
    static void testGenericWarningMessages() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, new List <String>{Label.Insufficient_Access_Rights});
            Test.stopTest();

            // Verify
            System.assertEquals(1, ApexPages.getMessages().size(), 'There should be error messages');
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.Insufficient_Access_Rights), 'There should be access issue');
        }
    }
    
    @IsTest
    static void testGenericWarningAlerts() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            List<UIDesignHelper.AlertWrapper> alerts = UIDesignHelper.genericWarningAlerts(ApexPages.Severity.ERROR, new List <String>{Label.Insufficient_Access_Rights});
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            UIDesignHelper.genericWarningAlerts(ApexPages.Severity.ERROR, new List <String>{Label.Insufficient_Access_Rights});
            Test.stopTest();

            // Verify
            System.assertEquals(1, alerts.size(), 'There should be error messages');
            System.assertEquals(alerts[0].message, Label.Insufficient_Access_Rights, 'There should be access issue');
            System.assertEquals(1, ApexPages.getMessages().size(), 'There should be error messages');
        }
    }
    
    @IsTest
    static void testGenericWarningMessageMap() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            Map<String, List<Object>> pageMessagesMap = UIDesignHelper.genericWarningMessage(String.valueOf(ApexPages.Severity.ERROR), new List <String>{Label.Insufficient_Access_Rights});
            Test.stopTest();

            // Verify
            System.assertEquals(1, pageMessagesMap.size(), 'There should be error messages');
            System.assertEquals(pageMessagesMap.get(String.valueOf(ApexPages.Severity.ERROR))[0], Label.Insufficient_Access_Rights, 'There should be access issue');
        }
    }
    
    @IsTest
    static void testAccumulativeGenericWarningMessage() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            Map<String, Set<Object>> pageMessagesMap = new Map<String, Set<Object>>();
            pageMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(String.valueOf(ApexPages.Severity.ERROR), new List <String>{Label.Insufficient_Access_Rights}, pageMessagesMap);
            pageMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(String.valueOf(ApexPages.Severity.ERROR), new List <String>{'There is a new error'}, pageMessagesMap);
            Test.stopTest();

            // Verify
            System.assertEquals(1, pageMessagesMap.size(), 'There should be error messages');
            System.assertEquals(pageMessagesMap.get(String.valueOf(ApexPages.Severity.ERROR)).size(), 2, 'There should be 2 error');
        }
    }
    
    @IsTest
    static void testCustomExceptionData() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            //No Data setup required

            // Exercise
            Test.startTest();
            UIDesignHelper.CustomExceptionData customException = new UIDesignHelper.CustomExceptionData(ApexPages.Severity.ERROR, 'There is an exception', new List<String> {'1','2'}, 1, 'StackTrace', 'Ooperation');
            Test.stopTest();

            // Verify
            System.assertEquals('There is an exception', customException.generalMessage, 'There should be error messages');
        }
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }
}