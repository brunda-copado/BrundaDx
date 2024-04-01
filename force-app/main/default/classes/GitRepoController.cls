public with sharing class GitRepoController {
    private static Set<Id> flowIds = new Set<Id>();
    private static Set<String> branchNamesInUse = new Set<String>();
    private static String gitRepoId;
    @TestVisible
    private static final String GIT_BRANCHES = 'GitBranches';
    private static final String HEAD = 'HEAD';
    @TestVisible
    private static final String COPADO_NOTIFICATIONS = Test.isRunningTest() ? 'Test' + 'CopadoNotifications' : 'CopadoNotifications';
    private static String namespace = Settings.ns;
    @TestVisible
    private static final String QUERY =
        'SELECT Id, Name,CreatedDate, LastModifiedDate,' +
        namespace +
        'status__c, ' +
        namespace +
        'AttachmentId__c, ' +
        namespace +
        'Type__c, ' +
        namespace +
        'Message__c, ' +
        namespace +
        'ParentId__c, ' +
        namespace +
        'Parent2Id__c, ' +
        namespace +
        'isFinished__c, ' +
        namespace +
        'isSuccess__c FROM ' +
        namespace +
        'Copado_Notification__c WITH USER_MODE';

    //PUBLIC

    @AuraEnabled
    public static void refreshBranches(String repoId) {
        try {
            if (String.isNotEmpty(repoId) & Schema.sObjectType.Git_Repository__c.isQueryable()) {
                SfdxAPI.retrieveBranchesFromRepository(repoId);
                //Dummy Insert in Test Context to assert Copado Notification record creation
                if(Test.isRunningTest()){
                    createCopadoNotificationInTestContext(repoId,'DxListRepositoryBranches');
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+'\nStackTrace:'+e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static String fetchBranches(String repoId) {
        String result = '';
        try {
            if(String.isNotBlank(repoId)) {
                gitRepoId = repoId;
                List<Attachment> gitBranchesFile = [
                    SELECT Id, Body, LastModifiedDate, Name, ParentId
                    FROM Attachment
                    WHERE Name = :GIT_BRANCHES AND parentId = :repoId
                    WITH USER_MODE
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ]; 

                if(!gitBranchesFile.isEmpty()) {
                    List<Branch> gitBranches = (List<Branch>) JSON.deserialize((gitBranchesFile[0].Body).toString(), List<Branch>.class);
                    result =  JSON.serialize( removeBranchesInUse(gitBranches) );
                }
            }
            

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+'\nStackTrace:'+e.getStackTraceString());
        }
        return result;
    }

    @AuraEnabled
    public static Boolean areGitBranchesDeleted(String gitRepoId, String deleteGitBranches) {
        Boolean isDeleted = false;
        CopadoNotificationHelper.copadoFrontAPIreponse responseDetails;
        try {
                String callURL = Settings.Server_URL + '/json/v1/deleteGitBranches/' + EncodingUtil.urlEncode(gitRepoId, 'UTF-8');
                HttpResponse response = SfdxAPIHelper.callDxJob('POST', callURL, deleteGitBranches, true);
                String body = response.getBody();

                if (String.isNotBlank(body)) {
                     responseDetails = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(
                        body,
                        CopadoNotificationHelper.copadoFrontAPIreponse.class
                    );
                }

                if (responseDetails != null && String.isNotBlank(responseDetails.copadoJobId)) {
                    JobsManager.createRunningJob(responseDetails.CopadoJobId, CopadoNotificationHelper.DELETE_GIT_BRANCHES, gitRepoId, 'Starting...');
                    isDeleted = true;
                }

                if(Test.isRunningTest()){
                    createCopadoNotificationInTestContext(gitRepoId,'GitDeleteBranches');
                }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+'\nStackTrace:'+e.getStackTraceString());
        }
        return isDeleted;
    }

    @AuraEnabled
    public static PushTopicCreationResponse createCopadoNotificationPushTopic() {
        PushTopicCreationResponse result = new PushTopicCreationResponse(true, null);
        try {
            List<PushTopic> copadoNotifications = [
                SELECT Id, Name
                FROM PushTopic
                WHERE Name = :COPADO_NOTIFICATIONS
                WITH SYSTEM_MODE
            ];
            if (copadoNotifications.isEmpty()) {
                PushTopic pushTopic = new PushTopic();
                pushTopic.Name = COPADO_NOTIFICATIONS;
                pushTopic.Query = QUERY;
                pushTopic.ApiVersion = 32.0;
                pushTopic.NotifyForOperationCreate = true;
                pushTopic.NotifyForOperationUpdate = true;
                pushTopic.NotifyForOperationUndelete = true;
                pushTopic.NotifyForOperationDelete = true;
                pushTopic.NotifyForFields = 'All';
                DML.insertAsSystem(new List<PushTopic>{ pushTopic }, String.format(Label.ErrorWhileInserting, new List<String>{
                    'PushTopic',
                    'GitRepoController.createCopadoNotificationPushTopic'
                }));
            }
        } catch (Exception ex) {
            result = new PushTopicCreationResponse(false, ex.getMessage() +'\nStackTrace:'+ ex.getStackTraceString());
        }
        return result;
    }

    //PRIVATE

    private static List<Branch> removeBranchesInUse(List<Branch> branches){
        List<Branch> finalBranchList = new List<Branch>();
        Set<String> branchesinUseList = prepareBranchesInUse();
        if(branchesinUseList.isEmpty()){
            return removeHeadBranch(branches);
        }

        for (Branch br : branches) {
            if (!branchesinUseList.contains(br.name) && !br.name.equalsIgnoreCase(HEAD)) {
                finalBranchList.add(br);
            }
        }
        return finalBranchList;
    }

    private static List<Branch> removeHeadBranch(List<Branch> branchList){
        List<Branch> finalBranches =  new List<Branch>();
        for (Branch branch : branchList) {
            if (!(branch.name).equalsIgnoreCase(HEAD)) {
                finalBranches.add(branch);
            }
        }
        return finalBranches;
    }

    private static Set<String> prepareBranchesInUse() {
        processDeploymentFlows();
        if (!flowIds.isEmpty()) {
            processBranchNames();
        }
        return branchNamesInUse;
    }

    private static List<Deployment_Flow__c> fetchPipelines() {
        return [SELECT Id, Main_Branch__c FROM Deployment_Flow__c WHERE Active__c = TRUE AND Git_Repository__c = :gitRepoId WITH USER_MODE];
    }

    private static void processDeploymentFlows() {
        for (Deployment_Flow__c pipeline : fetchPipelines()) {
            flowIds.add(pipeline.Id);
            addBranchNameIfNotBlank(pipeline.Main_Branch__c);
        }
    }

    private static void processBranchNames() {
        for (Deployment_Flow_Step__c pipelineConnection : [SELECT Id, Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c IN :flowIds WITH USER_MODE]) {
            addBranchNameIfNotBlank(pipelineConnection.Branch__c);
        }
    }

    private static void addBranchNameIfNotBlank(String branchName) {
        if (String.isNotBlank(branchName)) {
            branchNamesInUse.add(branchName);
        }
    }

    private static void createCopadoNotificationInTestContext(Id repoId,String name){
        Copado_Notification__c copadoNotification = new Copado_Notification__c();
        copadoNotification.isFinished__c = false;
        copadoNotification.Name = name;
        copadoNotification.Type__c = name;
        copadoNotification.ParentId__c = repoId;
        DML.safeInsert(copadoNotification, String.format(Label.ErrorWhileInserting, new List<String>{'Copado_Notification__c', 'GitRepoController.createCopadoNotificationInTestContext'} ));
    }
    @TestVisible
    private Class Branch {
        public string name;
        public string type;
        public String lastUpdate;
    }

    public class PushTopicCreationResponse {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String message;
    
        public PushTopicCreationResponse(Boolean isSuccess, String message) {
            this.isSuccess = isSuccess;
            this.message = message;
        }
    }
}