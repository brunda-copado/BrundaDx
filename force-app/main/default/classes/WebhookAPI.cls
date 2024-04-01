public with sharing class WebhookAPI {
    public static String copadoURL = Settings.Server_URL;

    class ServerException extends Exception {
    }

    public static void runSeleniumTest(Id runId, String apiKey) {
        String url = copadoURL + '/json/v1/webhook/selenium/TestRun/' + runId + '?api_key=' + apiKey;
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        sendReq(req);
    }

    public static void runSeleniumTestGroup(Id groupId, String apiKey) {
        if (!Test.isRunningTest()) {
            String url = copadoURL + '/json/v1/webhook/selenium/TestGroupRun/' + groupId + '?api_key=' + apiKey;
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            req.setEndpoint(url);
            req.setMethod('POST');
            // fix for GCP issue with POST without body: Force Content-Length: 0
            req.setHeader('Content-Length', '0');
            sendReq(req);
        }
    }

    public static void setJobStatus(Id copadoJobId, String status, String apiKey) {
        String url = copadoURL + '/json/v1/webhook/jobStatus/' + copadoJobId + '/' + status + '?api_key=' + apiKey;
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        sendReq(req);
    }

    public static void setGroupJobStatus(Id groupId, String status, String apiKey) {
        String url = copadoURL + '/json/v1/webhook/groupJobStatus/' + groupId + '/' + EncodingUtil.urlEncode(status, 'UTF-8') + '?api_key=' + apiKey;
        System.debug(LoggingLevel.INFO, 'POST -> ' + url);
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        sendReq(req);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    @Future(callout=true)
    public static void callGenericWebhookAtFuture(String url, String schedId) {
        Scheduled_Job__c job = Schema.sObjectType.Scheduled_Job__c.isQueryable()
            ? [SELECT Id, Name, Run_as_User__c, Delete_Runs_after_days__c FROM Scheduled_Job__c WHERE Id = :schedId]
            : new Scheduled_Job__c();

        String calledUrl = maskApiKey(url, job);

        Scheduled_Job_Run__c jobRun = new Scheduled_Job_Run__c(
            Scheduled_Job__c = schedId,
            Called_URL__c = calledUrl,
            Run_as_User__c = job.Run_as_User__c
        );

        try {
            WebhookAPI.callGenericWebhook(url);
            jobRun.Status__c = 'Success';
        } catch (Exception e) {
            jobRun.Status__c = 'Failure';
            jobRun.Message__c = e.getMessage();
        }

        Utilities.Secure_DML(jobRun, Utilities.DML_Action.INS, Schema.SObjectType.Scheduled_Job_Run__c);

        job.Status__c = jobRun.Status__c;
        job.Message__c = jobRun.Message__c;
        if (job.Delete_Runs_after_days__c == null) {
            job.Delete_Runs_after_days__c = 10;
        }
        Utilities.Secure_DML(job, Utilities.DML_Action.UPD, Schema.SObjectType.Scheduled_Job__c);

        Date d = System.today() - job.Delete_Runs_after_days__c.intValue();
        List<Scheduled_Job_Run__c> jobRunsToDelete = [SELECT id FROM Scheduled_Job_Run__c WHERE CreatedDate < :d AND Scheduled_Job__c = : schedId];
        Utilities.Secure_DML(jobRunsToDelete, Utilities.DML_Action.DEL, Schema.SObjectType.Scheduled_Job_Run__c);
    }

    public static void callGenericWebhook(String url) {
        System.debug(LoggingLevel.INFO, 'POST -> ' + url);
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        sendReq(req);
    }

    public static void callGenericWebhookWithJsonBody(String url, String jsonBody) {
        System.debug(LoggingLevel.INFO, 'POST -> ' + url);
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setEndpoint(url);
        req.setBody(jsonBody);
        req.setMethod('POST');
        sendReq(req);
    }

    private static void sendReq(HttpRequest req) {
        Http h = new Http();
        HttpResponse res = h.send(req);
        String body = res.getBody();
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(body);
        if (m.containsKey('error')) {
            String errorMessage = (String) m.get('error');
            throw new ServerException(errorMessage);
        }
        if (res.getStatusCode() >= 400) {
            throw new ServerException(res.getStatusCode() + ' - ' + res.getStatus());
        }
    }

    @SuppressWarnings('PMD.ApexOpenRedirect')
    private static String maskApiKey(String url, Scheduled_Job__c job) {
        String result = url;
        if (String.isNotBlank(job.Run_as_User__c) && MaskApiKey.enforceMask) {
            PageReference page = new PageReference(url);
            Map<String, String> parameters = page.getParameters();
            if (parameters.containsKey('api_key')) {
                parameters.put('api_key', new MaskApiKey(parameters.get('api_key')).usingPlaceholder().execute());
                page.getParameters().putAll(parameters);
                result = EncodingUtil.urlDecode(page.getUrl(), 'UTF-8');
            }
            
        }
        return result;
    }
}