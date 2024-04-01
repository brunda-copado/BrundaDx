@SuppressWarnings('PMD')
public with sharing class DeployAPI {
    public final static String PRIVATE_KEY = 'id_rsa';
    public final static String FW_SLASH = '/';
    public static String copadoURL = Settings.server_url;
    public static Map<String, Object> orgMap;
    public static String currentUserId {
        get {
            return UserInfo.getUserId();
        }
        set;
    }

    public class ApplicationException extends Exception {
    }

    @Future(Callout=true)
    public static void deploy(List<Id> ids, String sid) {
        for (Id depId : ids) {
            deployNow(depId, sid);
        }
    }
    //@Future(callout=true)
    public static void deploy(Id depId, String sid) {
        deployNow(depId, sid);
    }

    public static void cancelDeployment(Id depId) {
        List<Deployment_Job__c> djs = new List<Deployment_Job__c>();
        if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            djs = [
                SELECT Id
                FROM Deployment_Job__c
                WHERE Step__r.Deployment__c = :depId AND Status__c IN ('Pending', 'Not started')
                WITH SECURITY_ENFORCED
            ];
        }
        for (Deployment_Job__c d : djs) {
            d.Status__c = 'Cancelled';
        }
        if (!djs.isEmpty()) {
            Utilities.Secure_DML(djs, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Job__c);
        }
    }

    public static void deployNow(Id depId, String sid) {
        String copadoOrgId = UserInfo.getOrganizationId();
        if (!Schema.SObjectType.Deployment__c.isQueryable() && !Schema.SObjectType.Deployment__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForDeployment));
            return;
        }
        Deployment__c deployment = [SELECT OwnerId FROM Deployment__c WHERE Id = :depId][0];
        if (deployment == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Deployment_Not_Found));
            return;
        }
        String copadoUserId = deployment.OwnerId;
        String url = copadoURL + '/json/v1/deployNow/' + depId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        new HerokuResponse(res);
        if (res.getStatusCode() == 200) {
            renameDeploymentAttachments(depId);
        }
    }

    public static void deployNowOutstanding(Id depId, String sid) {
        String copadoOrgId = UserInfo.getOrganizationId();
        if (!Schema.SObjectType.Deployment__c.isQueryable() && !Schema.SObjectType.Deployment__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForDeployment));
            return;
        }
        Deployment__c deployment = [SELECT OwnerId FROM Deployment__c WHERE Id = :depId][0];
        if (deployment == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Deployment_Not_Found));
            return;
        }
        String copadoUserId = deployment.OwnerId;
        String url = copadoURL + '/json/v1/deployNow/' + depId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
    }

    /**
     * This method renames old attachment names with OLD prefix
     * @param deploymentId
     */
    public static void renameDeploymentAttachments(String deploymentId) {
        Boolean isDeploymentJobQueryableAccessible =
            !Schema.SObjectType.Deployment_Job__c.isQueryable() && !Schema.SObjectType.Deployment_Job__c.isAccessible();
        Boolean isAttachmentQueryableAccessible = !Schema.SObjectType.Attachment.isQueryable() && !Schema.SObjectType.Attachment.isAccessible();
        if (isDeploymentJobQueryableAccessible || isAttachmentQueryableAccessible) {
            return;
        }
        List<Attachment> atts = new List<Attachment>();
        //list only results json files from jobs to be re-deployed. so result are not lost for previously deployed jobs

        atts = getAttachments(deploymentId);
        if (!atts.isEmpty()) {
            Utilities.Secure_DML(atts, Utilities.DML_Action.UPD, schema.SObjectType.Attachment);
        }
    }

    private static LisT<Attachment> getAttachments(String deploymentId) {
        List<String> pendingJobs = new List<String>();
        //reset status of deployment jobs
        Set<Id> djIds = new Set<Id>();
        Boolean isDataTemplateDeployment = false;

        for (Deployment_Job__c dj : [
            SELECT Id, Status__c, Step__r.Type__c
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :deploymentId
            WITH SECURITY_ENFORCED
        ]) {
            djIds.add(dj.Id);
            if (dj.Status__c == 'Pending') {
                pendingJobs.add(dj.Id + '.json');
            }
            if (dj.Step__r.Type__c == 'Data Template') {
                isDataTemplateDeployment = true;
            }
        }

        List<Attachment> atts = new List<Attachment>();
        for (Attachment at : [
            SELECT Id, Name
            FROM Attachment
            WHERE ParentId = :deploymentId AND (NOT Name LIKE 'OLD_%') AND Name != 'Test Classes'
            WITH SECURITY_ENFORCED
        ]) {
            Boolean isErrorAttachment = pendingJobs.contains(at.Name) || at.Name.contains('ERROR');
            Boolean isStatusCopadoAttachment = djIds.contains(at.Id) && at.Name.contains('_STATUS_COPADO');

            if (isErrorAttachment || isStatusCopadoAttachment || isDataTemplateDeployment) {
                at.Name = 'OLD_' + at.Name;
                atts.add(at);
            }
        }
        return atts;
    }

    public static void backupNow(Id backupId) {
        DeployAPI.backupNow(backupId, '', false, false);
    }

    public static void backupNow(Id backupId, String comment, Boolean applyEnvVars, Boolean applyYAML) {
        if (!Schema.SObjectType.Git_Backup__c.isQueryable() && !Schema.SObjectType.Git_Backup__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForGitBackup));
            return;
        }
        if (!Schema.SObjectType.Org__c.isQueryable() && !Schema.SObjectType.Org__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForOrg));
            return;
        }
        Git_Backup__c bk = [SELECT Org__c, Metadata_Types__c FROM Git_Backup__c WHERE Id = :backupId WITH SECURITY_ENFORCED];
        String copadoOrgId = UserInfo.getOrganizationId();

        String copadoUserId = [SELECT OwnerId FROM Org__c WHERE Id = :bk.Org__c].OwnerId;
        String orgId = bk.Org__c;
        String url =
            copadoURL +
            '/json/v1/backupNow/' +
            backupId +
            '?message=' +
            EncodingUtil.urlEncode(comment, 'UTF-8') +
            '&copadoOrgId=' +
            copadoOrgId +
            '&copadoUserId=' +
            copadoUserId +
            '&orgId=' +
            orgId +
            '&applyEnvVars=' +
            applyEnvVars +
            '&applyYAML=' +
            applyYAML;
        if (bk.Metadata_Types__c != null && bk.Metadata_Types__c != '') {
            url += '&filter=' + EncodingUtil.urlEncode(bk.Metadata_Types__c, 'UTF-8');
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        new HerokuResponse(h.send(req));
    }

    public static void executeCI(Id ciId) {
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();
        String url = copadoURL + '/json/v1/buildTaskExec/' + ciId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody('{"commits":[]}');
        new HerokuResponse(h.send(req));
    }

    @Future(callout=true)
    public static void deployBuildTask(Set<Id> btIds, String sessionId) {
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();

        for (Id btId : btIds) {
            String url = copadoURL + '/json/v1/deployBuildTask/' + btId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(btIds));
            new HerokuResponse(h.send(req));
        }
    }

    public static void getCommits(Id backupId) {
        String url = copadoURL + '/json/v1/gitCommits/' + backupId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        new HerokuResponse(h.send(req));
    }

    public static void testNow(Id orgId) {
        String copadoOrgId = UserInfo.getOrganizationId();
        if (!Schema.SObjectType.Org__c.isQueryable() && !Schema.SObjectType.Org__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForOrg));
            return;
        }
        String copadoUserId = [SELECT OwnerId FROM Org__c WHERE Id = :orgId].OwnerId;
        String url = copadoURL + '/json/v1/testNow/' + orgId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        new HerokuResponse(h.send(req));
    }

    //seems like is not used
    public static Map<String, Object> estimateDeploy(Id depId, String sid) {
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();
        String url = copadoURL + '/json/v1/estimateDeploy/' + depId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        new HerokuResponse(res);
        String r = res.getBody();
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        return m;
    }

    public static Integer getCredits() {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(copadoURL + '/?nosid=1');
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        new HerokuResponse(res);
        Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        orgMap = (Map<String, Object>) fullMap.get('customerOrg');
        return (Integer) orgMap.get('credits');
    }
    //seems like is not used
    @Future(Callout=true)
    public static void saveDeploy(Id deployId, String sid) {
        String url = copadoURL + '/json/v1/saveDeploy/' + deployId + '?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        new HerokuResponse(h.send(req));
    }

    @Future(Callout=true)
    public static void cleanDeploy(Id deployId) {
        if (!Schema.SObjectType.Deployment__c.isQueryable() && !Schema.SObjectType.Deployment__c.isAccessible()) {
            return; // TODO: add message if possible
        }
        String url = copadoURL + '/json/v1/cleanDeploy/' + EncodingUtil.urlEncode(deployId, 'UTF-8');
        String status = [SELECT Status__c FROM Deployment__c WHERE Id = :deployId].Status__c;
        url += '?status=' + EncodingUtil.urlEncode(status, 'UTF-8');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        new HerokuResponse(h.send(req));
    }

    @Future(Callout=true)
    public static void deployJob(List<Id> ids, String sid) {
        if (!Schema.SObjectType.Deployment_Job__c.isQueryable() && !Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            return;
        }
        Map<Id, Deployment_Job__c> mp = new Map<Id, Deployment_Job__c>([SELECT Id, Step__r.Deployment__c FROM Deployment_Job__c WHERE Id IN :ids]);
        for (Id jobId : ids) {
            String url = copadoURL + '/json/v1/deployJob/' + jobId + '?deployId=' + mp.get(jobId).Step__r.Deployment__c;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('GET');
            new HerokuResponse(h.send(req));
        }
    }

    @Future(Callout=true)
    public static void validateOrgAsync(Id orgId) {
        if (isOrgValidationDisabled(orgId)) {
            return;
        }

        String url = copadoURL + '/json/v1/validateOrg/' + orgId + '?setProfile=true';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        try {
            new HerokuResponse(res);
            Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        } catch (Exception e) {
            throw new ServerException(e.getMessage());
        }
    }

    public static Boolean validateOrg(Id orgId) {
        if (isOrgValidationDisabled(orgId)) {
            return true;
        }

        String url = copadoURL + '/json/v1/validateOrg/' + orgId + '?setProfile=true';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        try {
            new HerokuResponse(res);
            Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return mapa.get('organizationId') != null;
        } catch (Exception e) {
            return false;
        }
    }

    public static Boolean isOrgValidationDisabled(Id orgId) {
        Boolean isValidationDisabled = false;
        try {
            for (Org__c org : [SELECT Disable_Validation__c FROM Org__c WHERE Id = :orgId WITH SECURITY_ENFORCED]) {
                isValidationDisabled = org.Disable_Validation__c;
            }
        } catch (Exception ex) {
            // We show a WARNING since the user can still perform other operations on a record (for instance, a deployment).
            // This method is not supposed to block the user, it's purely informative.
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Label.Insufficient_Access + ' ' + Org__c.SObjectType.getDescribe().getLabel() + ': ' + orgId
                    )
                );
            }
            isValidationDisabled = true;
        }
        return isValidationDisabled;
    }

    public class ValidateGitResult {
        public Boolean success { get; set; }
        public String message { get; set; }
    }

    public static ValidateGitResult validateGit(Id gitId) {
        String url = copadoURL + '/json/v1/validateGit/?nosid=1';
        Git_Repository__c git = new Git_Repository__c();
        if (Schema.SObjectType.Git_Repository__c.isQueryable() && Schema.SObjectType.Git_Repository__c.isAccessible()) {
            git = [SELECT Id, URI__c FROM Git_Repository__c WHERE Id = :EncodingUtil.urlEncode(gitId, 'UTF-8') WITH SECURITY_ENFORCED];

            if (String.isBlank(git.URI__c)) {
                ValidateGitResult resultEmpty = new ValidateGitResult();
                resultEmpty.success = false;
                resultEmpty.message = Label.URI_cannot_be_empty;
                return resultEmpty;
            }

            url += '&uri=' + EncodingUtil.urlEncode(git.URI__c, 'UTF-8');
            url += '&repoId=' + EncodingUtil.urlEncode(git.Id, 'UTF-8');
        } else {
            ValidateGitResult resultEmpty = new ValidateGitResult();
            resultEmpty.success = false;
            resultEmpty.message = Label.DeployAPI_no_privileges_git_repo;
            return resultEmpty;
        }

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        Sensitive_Information__c gitRepositoryConfiguration = Sensitive_Information__c.getValues(gitId);
        if (null != gitRepositoryConfiguration) {
            if (String.isNotBlank(gitRepositoryConfiguration.Username__c)) {
                req.setHeader('un', gitRepositoryConfiguration.Username__c);
            }
            if (String.isNotBlank(gitRepositoryConfiguration.Password__c)) {
                req.setHeader('pw', gitRepositoryConfiguration.Password__c);
            }
        }
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        return returnResult(res, gitId);
    }

    private static ValidateGitResult returnResult(HttpResponse res, Id gitId) {
        ValidateGitResult result = new ValidateGitResult();
        try {
            new HerokuResponse(res);
            result.success = true;
            String expirationNoticeMessage = '';
            if (
                Copado_Setting__mdt.getInstance('Override_SSH_Rotation') == null ||
                (!Copado_Setting__mdt.getInstance('Override_SSH_Rotation').Enabled__c &&
                Copado_Setting__mdt.getInstance('Override_SSH_Rotation') != null)
            ) {
                String sshKeyFileName = [
                    SELECT Id, Name, LastModifiedDate, ParentId
                    FROM Attachment
                    WHERE ParentId = :gitId AND Name = :PRIVATE_KEY AND LastModifiedDate = LAST_N_MONTHS:11 AND LastModifiedDate < LAST_N_MONTHS:10
                    WITH SECURITY_ENFORCED
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ]
                ?.Name;
                if (String.isNotBlank(sshKeyFileName)) {
                    expirationNoticeMessage = Label.SSH_Key_Expiry_Notification;
                }
            }
            result.message = Label.OK_CREDENTIALS + '. ' + expirationNoticeMessage;
        } catch (Exception e) {
            result.success = false;
            result.message = Label.WRONG_CREDENTIALS + ': ' + e.getMessage();
        }
        return result;
    }

    public static Org__c getCustomerOrg() {
        return getCustomerOrg(UserInfo.getUserId());
    }

    public static Org__c getCustomerOrg(String uid) {
        String oid = UserInfo.getOrganizationId();
        uid = uid == null ? UserInfo.getUserId() : uid;
        String key = oid + '_' + uid;
        List<Org__c> ls = new List<Org__c>();
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            ls = [SELECT Id FROM Org__c WHERE SFDC_Org_ID__c = :oid OR SFDC_Org_ID__c = :key WITH SECURITY_ENFORCED];
        }
        Org__c copadoOrg = ls.size() > 0 ? ls.get(0) : null;
        return copadoOrg;
    }

    class ServerException extends Exception {
    }

    public class HerokuResponse {
        public Boolean success { get; set; }
        public String message { get; set; }

        public HerokuResponse(HttpResponse res) {
            validateResponse(res);
            if (!success) {
                throw new ServerException(message);
            }
        }

        public void validateResponse(HttpResponse res) {
            if (res.getStatusCode() != null) {
                if (res.getBody().containsIgnoreCase('<html') && res.getBody().containsIgnoreCase('error')) {
                    success = false;
                    message = res.getBody();
                } else {
                    Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    success = fullMap.get('error') == null;
                    if (success) {
                        message = (String) fullMap.get('ok');
                    } else {
                        message = (String) fullMap.get('error');
                    }
                }
            }
        }
    }

    public static String getAuthToken(Id userId) {
        String sid = '<sessionId might change>'; //UserInfo.getSessionId()!=null?UserInfo.getSessionId():'';
        String cdate = Datetime.now().formatGmt('yyyy-MM-dd');
        String myData = 'Copado Deployer by Copado Ltd' + userId + UserInfo.getOrganizationId() + sid + cdate;
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(myData));
        return EncodingUtil.convertToHex(hash);
    }

    public static void setAuthHeaders(HttpRequest req, Id userId) {
        req.setHeader('userId', userId);
        req.setHeader('orgId', UserInfo.getOrganizationId());
        //req.setHeader('sessionId', UserInfo.getSessionId()!=null?UserInfo.getSessionId():'');
        req.setHeader('token2', getAuthToken2(userId));
        req.setTimeout(120000);
    }

    public static String getAuthToken2(Id userId) {
        return encryptAPIKey(getAuthToken(userId));
    }

    public static String getAuthToken() {
        String sid = '<sessionId might change>'; //UserInfo.getSessionId()!=null?UserInfo.getSessionId():'';
        String cdate = Datetime.now().formatGmt('yyyy-MM-dd');
        String myData = 'Copado Deployer by Copado Ltd' + currentUserId + UserInfo.getOrganizationId() + sid + cdate;
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(myData));
        return EncodingUtil.convertToHex(hash);
    }

    public static void setAuthHeaders(HttpRequest req) {
        setAuthHeaders(req, currentUserId);
    }

    public static List<String> metadataTypes(Id orgId, String sid) {
        String url = copadoURL + '/json/v1/metadataTypes/' + orgId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        String r = res.getBody();
        List<String> mt = (List<String>) JSON.deserialize(r, List<String>.class);
        mt.sort();
        return mt;
    }

    /**
     * Callout to refresh Features in customer orgs.
     */
    public static HerokuResponse refreshOrgFeatures(String installationParams) {
        String url = copadoURL + '/json/v1/checkProvisioning';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate against heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(installationParams);
        HttpResponse res = h.send(req);

        return new HerokuResponse(res);
    }

    /*
    retrieve the available features for this installation. features are in heroku database which are
    synchronized from main Copado salesforce APO org.
    */
    public static void checkSyncFeatures() {
        //if features has been updated today skip update
        List<Feature__c> existing = Feature__c.getAll().values();
        syncFeaturesNow();
    }

    public static void checkSyncLicenses() {
        syncLicensesNow();
    }

    public static void syncFeaturesNow() {
        //US-0001524 features are now handled by FMA/LMO standard features. No need to callout the backend.
        List<Feature__c> featureList = new List<Feature__c>();
        //LMO controlled features
        Integer eeLicensesInteger = FeatureManagement.checkPackageIntegerValue('EE_Licenses_Enabled');
        Integer cadLicensesInteger = FeatureManagement.checkPackageIntegerValue('CAD_Licenses_Enabled');
        Integer ccmLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCM_Licenses_Enabled');
        Integer cstLicensesInteger = FeatureManagement.checkPackageIntegerValue('CST_Licenses_Enabled');
        Integer cchLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCH_Licenses_Enabled');
        Boolean multiLicense =
            eeLicensesInteger > 0 && (cadLicensesInteger > 0 || ccmLicensesInteger > 0 || cstLicensesInteger > 0 || cchLicensesInteger > 0);

        //CBM
        Feature__c cbmFeature = Feature__c.getInstance('Branch Management');
        if (cbmFeature == null) {
            cbmFeature = new Feature__c(Name = 'Branch Management');
        }
        cbmFeature.Enabled__c = FeatureManagement.checkPackageIntegerValue('CBM_Branches') > 0;
        cbmFeature.Expiration_Date__c = null;
        cbmFeature.Quantity__c = FeatureManagement.checkPackageIntegerValue('CBM_Branches');
        featureList.add(cbmFeature);
        //CCM
        Feature__c ccmFeature = Feature__c.getInstance('Change Management');
        if (ccmFeature == null) {
            ccmFeature = new Feature__c(Name = 'Change Management');
        }
        ccmFeature.Enabled__c = !multiLicense || ccmLicensesInteger > 0 || cadLicensesInteger > 0;
        ccmFeature.Expiration_Date__c = null;
        ccmFeature.Quantity__c = null;
        featureList.add(ccmFeature);
        //CST
        Feature__c cstFeature = Feature__c.getInstance('Selenium Testing');
        if (cstFeature == null) {
            cstFeature = new Feature__c(Name = 'Selenium Testing');
        }
        cstFeature.Enabled__c = cstLicensesInteger > 0;
        cstFeature.Expiration_Date__c = null;
        cstFeature.Quantity__c = null;
        featureList.add(cstFeature);
        //CCH
        Feature__c cchFeature = Feature__c.getInstance('Compliance Hub');
        if (cchFeature == null) {
            cchFeature = new Feature__c(Name = 'Compliance Hub');
        }
        cchFeature.Enabled__c = cchLicensesInteger > 0;
        cchFeature.Expiration_Date__c = null;
        cchFeature.Quantity__c = null;
        featureList.add(cchFeature);

        //Default, legacy features always enabled since there is no more Professional Edition.
        List<String> featuresStrings = new List<String>{
            'Apex Test',
            'Continuous Integration',
            'Full Permission Sets step',
            'Full Profiles step',
            'Git Backup',
            'Git MetaData',
            'Org Difference',
            'Snapshot Difference',
            'Full Translations step'
        };
        for (String featureName : featuresStrings) {
            Feature__c cs = Feature__c.getInstance(featureName);
            if (cs == null) {
                cs = new Feature__c(Name = featureName);
            }
            cs.Enabled__c = true;
            //we need to remove the expiration from the Feature list UI.
            cs.Expiration_Date__c = null;
            cs.Quantity__c = null;
            featureList.add(cs);
        }

        Utilities.Secure_DML(featureList, Utilities.DML_Action.UPS, schema.SObjectType.Feature__c);
    }

    public static void syncLicensesNow() {
        new LicenseManagerController();
    }

    public static String createAPIKeys() {
        String url = copadoURL + '/json/v1/createAPIKey?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        return res.getBody();
    }

    public static void createAPIKey() {
        String url = copadoURL + '/json/v1/createAPIKey?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        //HerokuResponse hr = new HerokuResponse(res);
        Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String key = (String) mapa.get('api_key');
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        ps.API_Key__c = encryptAPIKey(key);
        Utilities.Secure_DML(ps, Utilities.DML_Action.UPS, schema.SObjectType.Personal_Settings__c);
    }

    public static Blob getCryptoKey() {
        return cryptoKey;
    }

    private static Blob cryptoKey {
        get {
            if (null == cryptoKey) {
                if (!String.isEmpty(Settings__c.getOrgDefaults().CryptoKEY__c)) {
                    System.debug(LoggingLevel.INFO, 'Using customer unique key');
                    cryptoKey = EncodingUtil.base64Decode(Settings__c.getOrgDefaults().CryptoKEY__c);
                } else {
                    String metaKey = [
                        SELECT Id, DeveloperName, Text_Field__c
                        FROM Copado_Protected_Settiing__mdt
                        WHERE DeveloperName = 'Deprecated_Key'
                        LIMIT 1
                    ]
                    .Text_Field__c;
                    System.debug(LoggingLevel.INFO, 'Using deprecated key');
                    cryptoKey = EncodingUtil.base64Decode(metaKey);
                }
            }
            return cryptoKey;
        }
        set;
    }

    //takes a plain text api key and encrypt it using AES256. Finally base64 encode to be saved as Text.
    public static String encryptAPIKey(String clearAPIKey) {
        String result = null;
        if (String.isNotBlank(clearAPIKey)) {
            // Note: after change to token2, some test methods were failing due to invalid crypto keys defined in the setup, as token was not encrypted before
            if (Test.isRunningTest()) {
                try {
                    result = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', DeployAPI.cryptoKey, Blob.valueOf(clearAPIKey)));
                } catch (Exception e) {
                }
            } else {
                result = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', DeployAPI.cryptoKey, Blob.valueOf(clearAPIKey)));
            }
        }
        return result;
    }

    //takes a base64 text
    public static String decryptAPIKey(String apiKey) {
        if (String.isBlank(apiKey)) {
            return null;
        }
        Blob encryptedData = EncodingUtil.base64Decode(apiKey);
        return Crypto.decryptWithManagedIV('AES256', DeployAPI.cryptoKey, encryptedData).toString();
    }

    //read encrypted user api key and return it decrypted
    public static String getUserAPIKey() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        return decryptAPIKey(ps.API_Key__c);
    }

    public static String getUserAPIKey(Boolean forceSameUser) {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (forceSameUser && ps.SetupOwnerId != ps.CreatedById) {
            throw new ApplicationException(Label.APIKeyExposed);
        }
        return decryptAPIKey(ps.API_Key__c);
    }

    public static String createSSHKey(String parentId) {
        try {
            return generateSSHKey(parentId);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }

    private static String generateSSHKey(String parentId) {
        try {
            if (String.isBlank(parentId)) {
                return '{"error":"The parentId variable was not specified.  Please contact Copado Solutions support. Error code: DeployAPI.createSSHkey"}';
            }
            String url = copadoURL + '/json/v1/keygen?parentId=' + parentId;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('POST');
            // fix for GCP issue with POST without body: Force Content-Length: 0
            req.setHeader('Content-Length', '0');
            HttpResponse res = h.send(req);
            new HerokuResponse(res);
            return res.getBody();
        } catch (Exception ex) {
            throw ex;
        }
    }

    // Created for LWC components as adding to VF page message will not work
    public static String createSSHKeyForLWC(String parentId) {
        try {
            return generateSSHKey(parentId);
        } catch (Exception ex) {
            throw new ApplicationException(Label.SSHKEY_ERROR);
        }
    }

    public static void getCommitsFromRepo(Id repositoryId, String branch) {
        if (String.isBlank(branch)) {
            branch = 'master';
        }
        String url = copadoURL + '/json/v1/gitCommitsFromRepo/' + repositoryId + '?branch=' + branch;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        new HerokuResponse(h.send(req));
    }

    /**
     * makes deployment callout with current User Id or commit user Id from Async trigger
     *
     * @param url
     * @param commitUserId
     */
    private static void makeDeploymentCallout(String url, Id commitUserId) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        if (null == commitUserId) {
            setAuthHeaders(req);
        } else {
            setAuthHeaders(req, commitUserId); //to authenticate agains heroku servers
        }
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        new HerokuResponse(h.send(req));
    }

    /**
     * checks variables and adds additional parameters to the url if needed
     *
     * @param url
     * @param checkOnly
     * @param pipelineId
     * @param currentPromotion
     * @param repositoryId
     *
     * @return up to date url
     */
    private static String checkAdditionalParameters(
        String url,
        Boolean checkOnly,
        Id pipelineId,
        Promotion__c currentPromotion,
        String repositoryId
    ) {
        if (checkOnly == false && String.isNotBlank(pipelineId)) {
            //check git repo branch here
            if (!Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && !Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow_Step__c.label);
                return null;
            }
            //query with pipeline id and source and destination
            String flowStepQuery = 'SELECT Destination_Branch__c, Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipelineId';
            String sourceEnvironmentId;
            String destinationEnvironmentId;
            if (currentPromotion.Back_Promotion__c) {
                sourceEnvironmentId = currentPromotion.Destination_Environment__c;
                destinationEnvironmentId = currentPromotion.Source_Environment__c;
            } else {
                sourceEnvironmentId = currentPromotion.Source_Environment__c;
                destinationEnvironmentId = currentPromotion.Destination_Environment__c;
            }
            flowStepQuery +=
                ' AND Source_Environment__c = :sourceEnvironmentId' + ' AND Destination_Environment__c = :destinationEnvironmentId LIMIT 1';
            List<Deployment_Flow_Step__c> pipelineConnection = Database.query(flowStepQuery);
            if (pipelineConnection != null && !pipelineConnection.isEmpty()) {
                url += '&repositoryId=' + repositoryId;
                String destinationBranch = (currentPromotion.Back_Promotion__c
                    ? pipelineConnection[0].Branch__c
                    : pipelineConnection[0].Destination_Branch__c);
                url += '&branch=' + (String.isBlank(destinationBranch) ? '' : destinationBranch);
            }
        }
        return url;
    }

    /**
     * returns current promotion of the Id sent as a parameter
     *
     * @param promotionId
     *
     * @return Promotion record
     */
    private static Promotion__c returnCurrentPromotion(Id promotionId) {
        List<Promotion__c> result = [
            SELECT
                Id,
                Destination_Environment__c,
                Source_Environment__c,
                Destination_Environment__r.Name,
                Project__r.Deployment_Flow__r.Git_Repository__c,
                Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                Project__r.Deployment_Flow__c,
                Release__r.Project__r.Deployment_Flow__c,
                Back_Promotion__c
            FROM Promotion__c
            WHERE Id = :promotionId AND (Project__r.Deployment_Flow__c != NULL OR Release__r.Project__r.Deployment_Flow__c != NULL)
            WITH SECURITY_ENFORCED
        ];

        return result[0];
    }

    @Future(Callout=true)
    public static void deployPromotionAsync(
        Id promotionId,
        String userStoryName,
        Boolean checkOnly,
        Boolean singleStep,
        String testLevel,
        Boolean isDeployParam,
        String commitUserIdParam
    ) {
        deployPromotion(promotionId, userStoryName, checkOnly, singleStep, testLevel, isDeployParam, commitUserIdParam);
    }
    /**
     * duplicate of old deployPromotion method with two additional parameters. currentUserId and isDeploy
     *
     * @param promotionId
     * @param userStoryName
     * @param checkOnly
     * @param singleStep
     * @param testLevel
     * @param isDeploy to decide to start the deployment right away or leave the decision (for CCD logic)to CCD quality Gate step creation
     * @param commitUserId userId to use in the callout for async calls in the async triggers flow
     */
    public static void deployPromotion(
        Id promotionId,
        String userStoryName,
        Boolean checkOnly,
        Boolean singleStep,
        String testLevel,
        Boolean isDeploy,
        Id commitUserId
    ) {
        testLevel = (String.isBlank(testLevel)) ? 'NoTestRun' : testLevel;
        if (!Schema.SObjectType.Promotion__c.isQueryable() && !Schema.SObjectType.Promotion__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForPromotion));
            return;
        }

        Promotion__c currentPromotion = returnCurrentPromotion(promotionId);
        if (currentPromotion == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Current_Promotion_Not_Found));
            return;
        }
        String destEnv = currentPromotion.Destination_Environment__r.Name;
        String repositoryId = currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c == null
            ? currentPromotion.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
            : currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c;
        String pipelineId = String.isNotBlank(currentPromotion.Project__r.Deployment_Flow__c)
            ? currentPromotion.Project__r.Deployment_Flow__c
            : currentPromotion.Release__r.Project__r.Deployment_Flow__c;
        String deploymentName = 'CD: ' + (checkOnly ? 'Validate' : 'Deploy') + ' - ' + userStoryName + ' ➠ ' + destEnv;
        String url =
            copadoURL +
            '/json/v1/promote/' +
            promotionId +
            '?deploy=' +
            isDeploy +
            '&deploymentName=' +
            EncodingUtil.urlEncode(deploymentName, 'UTF-8') +
            '&checkOnly=' +
            checkOnly +
            '&singleStep=' +
            singleStep +
            '&testLevel=' +
            testLevel;

        url = checkAdditionalParameters(url, checkOnly, pipelineId, currentPromotion, repositoryId);
        //if url equals to null then there is a permission issue related to Deployment_Flow_Step__c object
        if (null == url) {
            return;
        }

        makeDeploymentCallout(url, commitUserId);
    }

    @Future(Callout=true)
    public static void deployPromotionAsync(Id promotionId, String userStoryName, Boolean checkOnly, Boolean singleStep, String testLevel) {
        deployPromotion(promotionId, userStoryName, checkOnly, singleStep, testLevel);
    }
    /**
     * legacy deployPromotion method without changes
     *
     * @param promotionId
     * @param userStoryName
     * @param checkOnly
     * @param singleStep
     * @param testLevel
     */
    public static void deployPromotion(Id promotionId, String userStoryName, Boolean checkOnly, Boolean singleStep, String testLevel) {
        testLevel = (String.isBlank(testLevel)) ? 'NoTestRun' : testLevel;
        if (!Schema.SObjectType.Promotion__c.isQueryable() && !Schema.SObjectType.Promotion__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForPromotion));
            return;
        }

        Promotion__c currentPromotion = returnCurrentPromotion(promotionId);
        if (currentPromotion == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Current_Promotion_Not_Found));
            return;
        }
        String destEnv = currentPromotion.Destination_Environment__r.Name;
        String repositoryId = currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c == null
            ? currentPromotion.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
            : currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c;
        String pipelineId = String.isNotBlank(currentPromotion.Project__r.Deployment_Flow__c)
            ? currentPromotion.Project__r.Deployment_Flow__c
            : currentPromotion.Release__r.Project__r.Deployment_Flow__c;
        String deploymentName = 'CD: ' + (checkOnly ? 'Validate' : 'Deploy') + ' - ' + userStoryName + ' ➠ ' + destEnv;
        String url =
            copadoURL +
            '/json/v1/promote/' +
            promotionId +
            '?deploy=true&deploymentName=' +
            EncodingUtil.urlEncode(deploymentName, 'UTF-8') +
            '&checkOnly=' +
            checkOnly +
            '&singleStep=' +
            singleStep +
            '&testLevel=' +
            testLevel;

        url = checkAdditionalParameters(url, checkOnly, pipelineId, currentPromotion, repositoryId);
        //if url equals to null then there is a permission issue related to Deployment_Flow_Step__c object
        if (null == url) {
            return;
        }

        makeDeploymentCallout(url, null);
    }

    /**
     * Run SCA from Org Credential
     */
    public static void orgCodeAnalysis(Id orgId) {
        new ValidateScaConfiguration().forCredential(orgId);

        String url = copadoURL + '/json/v1/code/analysis/static/mode/credential/' + orgId;
        HttpResponse res = new HerokuCallout(url, HttpMethod.POST).default().request().response();
        new HerokuResponse(res);
    }

    /**
     * Launch Static Code Analysis from a User Story
     */
    public static void usCodeAnalysis(Id orgId, Id usId) {
        new ValidateScaConfiguration().forUserStory(usId);

        String url = copadoURL + '/json/v1/code/analysis/static/mode/userstory/' + usId;
        HttpResponse res = new HerokuCallout(url, HttpMethod.POST).default().request().response();
        new HerokuResponse(res);
    }

    public static void orgComplianceScan(Id orgId) {
        checkExceptions(orgId);
        String url = copadoURL + '/json/v1/scanCompliance';
        url += '?orgId=' + orgId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setMethod('GET');

        new HerokuResponse(h.send(req));
    }

    private static void checkExceptions(Id orgId) {
        List<Org__c> org = new List<Org__c>();
        List<Environment__c> environment = new List<Environment__c>();
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            org = [SELECT Environment__c FROM Org__c WHERE Id = :orgId WITH SECURITY_ENFORCED LIMIT 1];
        }
        if (org.isEmpty()) {
            throw new ApplicationException(Label.ORG_NOT_FOUND);
        }
        if (Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            environment = [SELECT Id, Compliance_Rule_Group__c FROM Environment__c WHERE Id = :org[0].Environment__c WITH SECURITY_ENFORCED LIMIT 1];
        }
        if (environment.isEmpty() || environment[0].Compliance_Rule_Group__c == null) {
            throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
        }
    }

    public static void gitBackupComplianceScan(Id gitBackupId) {
        List<Git_Backup__c> gitBackup = new List<Git_Backup__c>();
        List<Environment__c> environment = new List<Environment__c>();
        if (Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
            gitBackup = [SELECT Id, Org__r.Environment__c FROM Git_Backup__c WHERE Id = :gitBackupId WITH SECURITY_ENFORCED LIMIT 1];
        }
        if (gitBackup.isEmpty()) {
            throw new ApplicationException(Label.GIT_BACKUP_NOT_FOUND);
        }
        if (Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            environment = [
                SELECT Id, Compliance_Rule_Group__c
                FROM Environment__c
                WHERE Id = :gitBackup[0].Org__r.Environment__c
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        }
        if (environment.isEmpty() || environment[0].Compliance_Rule_Group__c == null) {
            throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
        }

        String url = copadoURL + '/json/v1/scanCompliance';
        url += '?gitBackupId=' + gitBackupId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setMethod('GET');

        new HerokuResponse(h.send(req));
    }
    public static void usComplianceScan(Id orgId, Id usId) {
        List<User_Story__c> userStories = new List<User_Story__c>();
        if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            userStories = [
                SELECT
                    Name,
                    Environment__r.Compliance_Rule_Group__c,
                    Project__r.Deployment_Flow__c,
                    Project__r.Deployment_Flow__r.Git_Repository__c,
                    Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
                FROM User_Story__c
                WHERE Id = :usId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        }

        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.USER_STORY_NOT_FOUND);
        } else {
            if (userStories[0].Environment__r.Compliance_Rule_Group__c == null) {
                throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
            }
        }

        // Metadata attachments are retrieved in the backend. Verify that the attachments exist.
        List<Attachment> attachments = new List<Attachment>();
        try {
            if (Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                attachments = [
                    SELECT Id, Body
                    FROM Attachment
                    WHERE ParentId = :usId AND (Name = 'MetaData' OR Name = 'Delete MetaData' OR Name = 'Git MetaData')
                    WITH SECURITY_ENFORCED
                ];
            }
        } catch (Exception e) {
            throw new ApplicationException(Label.PROBLEM_RETRIEVING_META_ATTACH);
        }

        if (attachments.isEmpty()) {
            throw new ApplicationException(Label.METADATA_NOT_FOUND_COMPLIANCE);
        } else {
            String url = copadoURL + '/json/v1/scanCompliance/';
            url += '?orgId=' + orgId + '&userStoryId=' + usId;
            if (userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c != null) {
                url += '&repositoryId=' + userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c;
                url += '&branch=feature/' + userStories[0].Name;
            } else if (userStories[0].Release__r.Project__r.Deployment_Flow__r.Git_Repository__c != null) {
                url += '&repositoryId=' + userStories[0].Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
                url += '&branch=feature/' + userStories[0].Name;
            }
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('GET');

            new HerokuResponse(h.send(req));
        }
    }

    public static void retrieveVlocityDependencies(Id userStoryId, String jsonSelectedMetadata) {
        calloutForVlocityDependencies(userStoryId, jsonSelectedMetadata);
    }
    private static void calloutForVlocityDependencies(Id userStoryId, String jsonSelectedMetadata) {
        String url = copadoURL + '/json/v1/metadataDependencies?userStoryId=' + userStoryId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate against heroku servers
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody(jsonSelectedMetadata);

        HttpResponse res = h.send(req);
        String body = res.getBody();
        new HerokuResponse(res);

        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(
            body,
            CopadoNotificationHelper.copadoFrontAPIreponse.class
        );
        if (String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.copadoJobId, CopadoNotificationHelper.METADATA_DEPENDENCIES, userStoryId, Label.Starting);
        }
    }
    /**
     * Calls Copado Backend API to know name and type of paths.
     * @param filesList
     * @return Retrievable class
     */
    public static WorkPushServices.DxFormatConvertResponse fileToRet(WorkPushServices.FileToRetWrapper retWrapper, String sourceFormat) {
        String endpointString = copadoURL.endsWith(FW_SLASH) ? copadoURL : copadoURL + FW_SLASH;
        String body;
        if (sourceFormat == 'DX') {
            endpointString += 'json/v1/dx/metadata/filenames2retrievables';
            body = JSON.serialize(retWrapper);
        } else {
            endpointString += 'json/v1/metadata/filenames2retrievables';
            body = JSON.serialize(retWrapper.fileList);
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate against heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(endpointString);
        req.setMethod('POST');
        req.setBody(body);
        HttpResponse res = h.send(req);

        WorkPushServices.DxFormatConvertResponse retrievableList = (WorkPushServices.DxFormatConvertResponse) JSON.deserialize(
            res.getBody(),
            WorkPushServices.DxFormatConvertResponse.class
        );
        return retrievableList;
    }
}