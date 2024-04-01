@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class CommitAction implements JobExecutionCallback {
    // GLOBAL

    @InvocableMethod(label='Commit changes' description='Commit your changes' category='Copado Multi-Cloud')
    global static List<Response> commitChanges(List<Request> requests) {
        Actions.CommitRequest commitRequest = convertRequests(requests);
        Actions.CommitResult commitResult = Actions.CommitService.execute(commitRequest);
        return convertResult(commitResult);
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global void execute(JobExecution__c job, String status) {
        new CommitServiceImpl().execute(job, status);
    }

    // PRIVATE

    private static Actions.CommitRequest convertRequests(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }
        Request request = requests[0];

        Actions.CommitRequest result = new Actions.CommitRequest();
        result.baseBranch = request.baseBranch;
        result.changes = convertChanges(request.changes);
        result.commitId = request.commitId;
        result.executeCommit = request.executeCommit != null ? request.executeCommit : true;
        result.otherInformation = request.jsonInformation;
        result.message = request.message;
        result.recreateFeatureBranch = request.recreateFeatureBranch != null ? request.recreateFeatureBranch : false;
        result.userStoryId = request.userStoryId;
        result.actionCallback = request.actionCallback;
        return result;
    }

    private static List<Actions.CommitChange> convertChanges(List<Change> changes) {
        List<Actions.CommitChange> result = new List<Actions.CommitChange>();
        for (Change change : changes) {
            Actions.CommitChange commitChange = new Actions.CommitChange();
            commitChange.a = change.a;
            commitChange.c = change.c;
            commitChange.m = change.m;
            commitChange.n = change.n;
            commitChange.t = change.t;
            commitChange.j = change.j;
            result.add(commitChange);
        }
        return result;
    }

    private static List<Response> convertResult(Actions.CommitResult commitResult) {
        Response result = new Response();
        result.userStorycommit = commitResult.userStoryCommit;
        result.jobExecution = commitResult.jobExecution;
        return new List<Response>{ result };
    }

    // INNER

    global with sharing class Request {
        @InvocableVariable(label='User Story Id' description='Commit your changes' required=true)
        global Id userStoryId;

        @InvocableVariable(label='Changes' description='List of changes to commit')
        global List<Change> changes = new List<Change>();

        @InvocableVariable(
            label='Recreate feature branch'
            description='If specified, previous branch and User Story Metadata records previously commited will be deleted. Defaults to false'
        )
        global Boolean recreateFeatureBranch = false;

        @InvocableVariable(
            label='Execute commit'
            description='If set to false, actual commit behaviour will be skipped and only operations in Copado will happen. Likely specified to false when commiting from CLI. Defaults to true'
        )
        global Boolean executeCommit = true;

        @InvocableVariable(
            label='Base branch'
            description='Base branch for the commit. If not provided, a default value is calculated based on User Story, Release, or Pipeline'
        )
        global String baseBranch; // optional, default value calculated

        @InvocableVariable(
            label='Message'
            description='Commit message. If not provided, a default value is calculated based on User Story Name and Title'
        )
        global String message; // optional, default value calculated

        @InvocableVariable(label='JSON Information' description='Additional commit information in JSON format')
        global String jsonInformation; // optional

        @InvocableVariable(label='Commit Id' description='Id of an existing git commit with the changes. Likely specified when commiting from CLI')
        global String commitId; // optional, CLI specific

        @InvocableVariable(label='Action Callback' description='Apex Callback Class that implements JobExecutionCallback')
        global String actionCallback;
    }

    // Note: names are short to reduce memory/heap/transmission sizes
    global with sharing class Change {
        @InvocableVariable(label='a' description='action: add, delete, ret-only, full pps, ...')
        global String a;
        @InvocableVariable(label='c' description='category: copadodx, vlocity, cpq, ...')
        global String c;
        @InvocableVariable(label='m' description='module directory e.g. force-app/main/default')
        global String m;
        @InvocableVariable(label='n' description='name')
        global String n;
        @InvocableVariable(label='t' description='type')
        global String t;
        @InvocableVariable(label='j' description='json additional information')
        global String j;

        // PRIVATE OUTTER

        private User_Story_Metadata__c toUserStoryMetadata(User_Story__c userStory) {
            String metadataApiName = t + '.' + n;
            String uniqueId = uniqueId(userStory.Id);

            return new User_Story_Metadata__c(
                Action__c = a,
                Category__c = c,
                ModuleDirectory__c = m,
                Type__c = t,
                JsonInformation__c = j,
                User_Story__c = userStory.Id,
                Metadata_API_Name__c = n, // Create Name__c later if needed
                Name = (userStory.Name + ' ' + a + ' ' + metadataApiName).left(80),
                Last_Commit_Date__c = System.now(), // needed?
                Unique_ID__c = uniqueId
            );
        }

        // PRIVATE INNER

        private String uniqueId(String userStoryId) {
            String result = userStoryId + ';' + m + ';' + t + ';' + n;
            return getEncodedUniqueIdWhenNeeded(result);
        }

        // Note: Encoding is skipped when not needed due to CPU performance and readability purposes
        private String getEncodedUniqueIdWhenNeeded(String uniqueId) {
            if (uniqueId.length() > 255) {
                uniqueId = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(uniqueId)));
            }
            return uniqueId;
        }
    }

    global with sharing class Response {
        @InvocableVariable(label='Job Execution' description='Job Execution record for the commit action')
        global JobExecution__c jobExecution;

        @InvocableVariable(label='User Story Commit' description='User Story Commit record created as part of the commit process')
        global User_Story_Commit__c userStorycommit;

        // CTOR OUTTER

        private Response userStoryCommitId(Id userStorycommitId) {
            this.userStorycommit = new User_Story_Commit__c(Id = userStorycommitId);
            return this;
        }
    }
}