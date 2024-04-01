public with sharing class PackageDistributeServiceImpl {
    // PUBLIC

    public static Actions.PackageDistributeRequestResult execute(Actions.PackageDistributeRequest request) {
        return getResponse(PackageVersionPublishAction.publish(getRequest(request)));
    }

    // PRIVATE

    private static List<PackageVersionPublishAction.Request> getRequest(Actions.PackageDistributeRequest request) {
        PackageVersionPublishAction.Request result = new PackageVersionPublishAction.Request(request.packageVersionId);
        result.actionCallback = request.actionCallback;
        return new List<PackageVersionPublishAction.Request>{ result };
    }

    private static Actions.PackageDistributeRequestResult getResponse(List<PackageVersionPublishAction.Response> response) {
        Actions.PackageDistributeRequestResult result = new Actions.PackageDistributeRequestResult();
        result.jobExecution = response[0].job;
        return result;
    }
}