@isTest
private with sharing class WebhookSchedulable_Test {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createPersonalSettings();
        }
    }

    @isTest
    private static void checkUserApiKeyAdded() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            String webhookUrl = 'https://dev-app-api.copa.do/json/v1/webhook/code/analysis/static/mode/credential/a0Q1v00000yU1uh';
            Scheduled_Job__c job = createJob(webhookUrl);

            // Exercise
            Test.startTest();
            WebhookSchedulable schedulable = new WebhookSchedulable(job.Id);
            schedulable.execute(null);
            Test.stopTest();

            // Verify
            Scheduled_Job_Run__c jobRun = [SELECT Called_URL__c FROM Scheduled_Job_Run__c WHERE Scheduled_Job__c = :job.Id];
            PageReference page = new PageReference(jobRun.Called_URL__c);
            String calledUrl = page.getUrl();
            Map<String, String> urlParameters = page.getParameters();

            System.assertEquals(webhookUrl, calledUrl.substringBefore('?'), 'URL should not change');
            System.assertEquals(Label.ApiKeyPlaceholder, urlParameters.get('api_key'), 'Api Key should be masked');
        }
    }

    @isTest
    private static void includeQueryParameters() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            String webhookUrl = 'https://dev-app-api.copa.do/json/v1/webhook/code/analysis/static/mode/credential/a0Q1v00000yU1uh&param1=a&param2=b&api_key=c';
            Scheduled_Job__c job = createJob(webhookUrl);

            // Exercise
            Test.startTest();
            WebhookSchedulable schedulable = new WebhookSchedulable(job.Id);
            schedulable.execute(null);
            Test.stopTest();

            // Verify
            Scheduled_Job_Run__c jobRun = [SELECT Called_URL__c FROM Scheduled_Job_Run__c WHERE Scheduled_Job__c = :job.Id];
            PageReference page = new PageReference(jobRun.Called_URL__c);
            String calledUrl = page.getUrl();
            Map<String, String> urlParameters = page.getParameters();

            System.assertEquals(webhookUrl.substringBefore('&'), calledUrl.substringBefore('?'), 'URL should not change');
            System.assert(urlParameters.containsKey('param1'), 'Query parameters should not change');
            System.assert(urlParameters.containsKey('param2'), 'Query parameters should not change');
            System.assertEquals(Label.ApiKeyPlaceholder, urlParameters.get('api_key'), 'Api Key should be masked');
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

    private static void createPersonalSettings() {
        Personal_Settings__c setting = new Personal_Settings__c(
            Name = 'Personal Settings for current user',
            SetupOwnerId = UserInfo.getUserId(),
            API_Key__c = DeployAPI.encryptAPIKey('test_apikey'),
            MaskApiKey__c = true
        );
        insert setting;
    }

    private static Scheduled_Job__c createJob(String url) {
        Scheduled_Job__c job = new Scheduled_Job__c(Name = 'test job', Webhook_Url__c = url, Run_As_User__c = UserInfo.getUserId());
        insert job;
        return job;
    }

    private static String getUserAPIKey() {
        return DeployAPI.getUserAPIKey();
    }
}