public with sharing class PackageVersionCreateServiceImpl {

    // PUBLIC
    
    public static Actions.PackageVersionCreateResult execute(Actions.PackageVersionCreateRequest request) {
        return getResponse(PackageVersionCreateAction.create(getRequest(request)));
    }

    // PRIVATE

    private static List<PackageVersionCreateAction.Request> getRequest(Actions.PackageVersionCreateRequest request) {
        PackageVersionCreateAction.Request result = new PackageVersionCreateAction.Request(
            request.packageId,
            request.otherInformation
        );
        result.versionName = request.versionName;
        result.versionNumber = request.versionNumber;
        result.description = request.description;
        result.actionCallback = request.actionCallback;
        return new List<PackageVersionCreateAction.Request> { result };
    }

    private static Actions.PackageVersionCreateResult getResponse(List<PackageVersionCreateAction.Response> response) {
        Actions.PackageVersionCreateResult result = new Actions.PackageVersionCreateResult();
        result.jobExecution = response[0].job;
        return result;
    }
}