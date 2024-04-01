public with sharing class CreateUserStoryBundleServiceImpl {
    // PUBLIC

    public static Actions.CreateUserStoryBundleResult create(Actions.CreateUserStoryBundleRequest request) {
        Actions.CreateUserStoryBundleResult response = new Actions.CreateUserStoryBundleResult();

        new UserStoryBundleValidator(request.userStoryIds).run();

        Artifact__c packageArtifact = createPackage(request);
        Artifact_Version__c packageVersion = createPackageVersion(request, packageArtifact.Id);
        createBundledStories(request.userStoryIds, packageVersion.Id);

        response.packageVersion = packageVersion;
        return response;
    }

    // PRIVATE

    private static Artifact__c createPackage(Actions.CreateUserStoryBundleRequest request) {
        Artifact__c result = new Artifact__c(
            Name = request.packageVersion.Name,
            RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId(),
            Pipeline__c = pipelineId(request.userStoryIds)
        );

        DML.safeInsert(
            result,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    Artifact__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'CreateUserStoryBundleServiceImpl.createPackageAndPackageVersions'
                }
            )
        );

        return result;
    }

    private static Artifact_Version__c createPackageVersion(Actions.CreateUserStoryBundleRequest request, Id packageId) {
        Artifact_Version__c result = request.packageVersion;
        result.Artifact__c = packageId;

        DML.safeInsert(
            result,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    Artifact_Version__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'CreateUserStoryBundleServiceImpl.createPackageAndVersions'
                }
            )
        );
        return result;
    }

    private static void createBundledStories(List<Id> userStoryIds, Id packageVersionId) {
        Actions.AddUserStoryBundleRequest request = new Actions.AddUserStoryBundleRequest();
        request.packageVersionId = packageVersionId;
        request.userStoryIds = userStoryIds;
        Actions.UserStoryBundleService.add(request);
    }

    private static Id pipelineId(List<Id> userStoryIds) {
        User_Story__c userStory = [
            SELECT Id, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
            FROM User_Story__c
            WHERE Id IN :userStoryIds
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return new FindPipeline().fromObject(userStory);
    }
}