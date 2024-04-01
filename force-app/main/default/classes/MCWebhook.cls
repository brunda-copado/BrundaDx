@SuppressWarnings('PMD')
@RestResource(urlMapping='/mcwebhook')
global with sharing class MCWebhook {

    @HttpPost
    global static String runAction() {
        Object result;
        String action = '';
        String key = '';
        String payload = '';

        try {
            Map<String, Object> restReq = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            action = (String) restReq.get('action');
            key = (String) restReq.get('key');
            payload = JSON.serialize(restReq.get('payload'));

            validateRequest(action, key, restReq.get('payload'));

            if (action.equalsIgnoreCase('Commit')) {
                CommitAction.Request actionReq = (CommitAction.Request) JSON.deserializeStrict(payload, CommitAction.Request.class);
                result = CommitAction.commitChanges(new List<CommitAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('Promotion')) {
                PromoteAction.Request actionReq = (PromoteAction.Request) JSON.deserializeStrict(payload, PromoteAction.Request.class);
                result = PromoteAction.promote(new List<PromoteAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('PromotionDeployment')) {
                PromotionDeployAction.Request actionReq = (PromotionDeployAction.Request) JSON.deserializeStrict(
                    payload,
                    PromotionDeployAction.Request.class
                );
                result = PromotionDeployAction.deploy(new List<PromotionDeployAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('CreatePackage')) {
                PackageCreateAction.Request actionReq = (PackageCreateAction.Request) JSON.deserializeStrict(
                    payload,
                    PackageCreateAction.Request.class
                );
                result = PackageCreateAction.create(new List<PackageCreateAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('CreatePackageVersion')) {
                PackageVersionCreateAction.Request actionReq = (PackageVersionCreateAction.Request) JSON.deserializeStrict(
                    payload,
                    PackageVersionCreateAction.Request.class
                );
                result = PackageVersionCreateAction.create(new List<PackageVersionCreateAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('PublishPackageVersion')) {
                PackageVersionPublishAction.Request actionReq = (PackageVersionPublishAction.Request) JSON.deserializeStrict(
                    payload,
                    PackageVersionPublishAction.Request.class
                );
                result = PackageVersionPublishAction.publish(new List<PackageVersionPublishAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('ImportPackage')) {
                PackageImportAction.Request actionReq = (PackageImportAction.Request) JSON.deserializeStrict(
                    payload,
                    PackageImportAction.Request.class
                );
                result = PackageImportAction.import(new List<PackageImportAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('RunTests')) {
                RunTestsAction.Request actionRequest = (RunTestsAction.Request) JSON.deserializeStrict(payload, RunTestsAction.Request.class);
                result = RunTestsAction.execute(new List<RunTestsAction.Request>{ actionRequest }).get(0);
            } else if (action.equalsIgnoreCase('CheckStatusAction')) {
                CheckStatusAction.Request actionReq = (CheckStatusAction.Request) JSON.deserializeStrict(payload, CheckStatusAction.Request.class);
                result = CheckStatusAction.fetch(new List<CheckStatusAction.Request>{ actionReq }).get(0);
            } else if (action.equalsIgnoreCase('RunJobTemplate')) {
                CreateExecution.Request request = (CreateExecution.Request) JSON.deserializeStrict(payload, CreateExecution.Request.class);
                result = CreateExecution.execute(new List<CreateExecution.Request>{ request }).get(0);
            } else if (Test.isRunningTest() && action == 'TestClassAction') {
                result = JSON.deserializeStrict(payload, JobExecution__c.class);
            } else if(action.equalsIgnoreCase('TakeSnapshot')){
                Actions.TakeGitSnapshotRequest snapReq = (Actions.TakeGitSnapshotRequest) JSON.deserializeStrict(payload, Actions.TakeGitSnapshotRequest.class);
                result = Actions.GitSnapshotService.takeSnapshot(snapReq);
            } else {
                throw new ApplicationException(Label.Action_Not_Supported);
            }

            return JSON.serialize(result);
        } catch (JSONException ex) {
            String errMsg = String.format(Label.Invalid_Json_Payload_For_Action, new List<String>{ action });
            throw new ApplicationException(errMsg, ex);
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage(), ex);
        }
    }

    // PRIVATE

    private static void validateRequest(String action, String key, Object payload) {
        List<Webhook_Settings__c> actionKeys = [
            SELECT Action__c, Start_Date__c, End_Date__c
            FROM Webhook_Settings__c
            WHERE UserId__c = :UserInfo.getUserId() AND Key__c = :key
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (action == null || actionKeys.isEmpty()) {
            throw new ApplicationException(Label.Invalid_Action_Key);
        }

        // Note: Any api valid key can use CheckStatusAction to track the status of other actions.
        if (!action.equalsIgnoreCase('CheckStatusAction') && isInvalidAction(actionKeys[0], action)) {
            throw new ApplicationException(Label.Invalid_Action_Key);
        }

        if (actionKeys[0].Start_Date__c.date() > Date.today() || actionKeys[0].End_Date__c.date() < Date.today()) {
            throw new ApplicationException(Label.Invalid_Date_Range_Key);
        }

        if (payload == null) {
            String errMsg = String.format(Label.Invalid_Json_Payload_For_Action, new List<String>{ action });
            throw new ApplicationException(errMsg);
        }
    }

    private static Boolean isInvalidAction(Webhook_Settings__c actionKey, String action) {
        List<String> actions = actionKey.Action__c.toLowerCase().split(',');
        return !actions.contains(action.toLowerCase());
    }
}