public with sharing class WizardUtilsController {

    public String token2 { get {return DeployAPI.getAuthToken2(UserInfo.getUserId());} set; }

    public String sessionId { get {return Userinfo.getSessionId() != null ? Userinfo.getSessionId() : '';} set; }

    public String orgId { get {return Userinfo.getOrganizationId();} set; }

    public String userId { get {return Userinfo.getUserId();} set; }
}