public with sharing class PackageCreateServiceImpl {
   
    // PUBLIC

    public static Actions.PackageCreateResult execute(Actions.PackageCreateRequest request){
        return getResponse(PackageCreateAction.create(getRequest(request)));
    }

    // PRIVATE

    private static List<PackageCreateAction.Request> getRequest(Actions.PackageCreateRequest request) {
        PackageCreateAction.Request result = new PackageCreateAction.Request(request.packageId, request.otherInformation);
        result.actionCallback = request.actionCallback;

        return new List<PackageCreateAction.Request> { result };
    }

    private static Actions.PackageCreateResult getResponse(List<PackageCreateAction.Response> response) {
        Actions.PackageCreateResult result = new Actions.PackageCreateResult();
        result.jobExecution = response[0].job;
        return result;
    }
}