public with sharing class CustomConnectedAppTriggerHelper {
    private static final String MASKED_STRING = '***************';
    public void callBackend() {
        for (SObject so : Trigger.new) {
            Custom_Connected_App_Info__c customAppRecord = (Custom_Connected_App_Info__c) so;
            if(customAppRecord.ClientSecret__c != MASKED_STRING){
                registerCustomApp(
                    new CustomConnectedAppBody(customAppRecord)
                        .getSerializedRecord(),
                    JSON.serialize(customAppRecord)
                );
            }
        }
    }

    @future(callout=true)
    public static void registerCustomApp(String customAppDTOStr, String customAppRecordStr){
        Http call = new Http();
        HttpRequest req = new HttpRequest();
        DeployAPI.setAuthHeaders(req);
        req.setEndpoint(Settings.server_url + '/json/v1/connected-app');
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(customAppDTOStr);
        HttpResponse res = call.send(req);
        if(Integer.valueOf(res.getStatusCode()/100) == 2){
            Custom_Connected_App_Info__c info = (Custom_Connected_App_Info__c)JSON.deserialize(customAppRecordStr, Custom_Connected_App_Info__c.class);
            info.ClientId__c = MASKED_STRING;
            info.ClientSecret__c = MASKED_STRING;
            //no need for permission check since this is to make sure we dont have visible key and secret after a successful registration
            update info;
        }
    }

    public class CustomConnectedAppBody {
        public String callBackUrl;
        public String name;
        public String clientId;
        public String clientSecret;
        public String connectedAppId;

        public CustomConnectedAppBody(Custom_Connected_App_Info__c info){
            this.callBackUrl = info.Callback_URL__c;
            this.name = info.Name;
            this.clientId = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', DeployAPI.getCryptoKey(), Blob.valueOf(info.ClientId__c)));
            this.clientSecret = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', DeployAPI.getCryptoKey(), Blob.valueOf(info.ClientSecret__c)));
            this.connectedAppId = info.Connected_App_Id__c;
        }

        public String getSerializedRecord(){
            return JSON.serialize(this);
        }
    }

    public class CustomConnectedAppResult {
        public Boolean success { get; set; }
        public String message { get; set; }
    }
}