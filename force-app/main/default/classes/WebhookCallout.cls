public with sharing class WebhookCallout extends HttpCallout {

    public WebhookCallout(String path) {
        super(path, HttpMethod.GET);
    }

    public class Credential { 
        public String error;
        public String endPoint;
        public String sessionId;
        public Boolean isSuccess;
    }
}