public with sharing class TestsResultGenerator {
    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Result__c.SObjectType });
    private List<Id> testIds = new List<Id>();

    @testVisible
    private static String mockResultStatus = 'Success';

    //PUBLIC

    public TestsResultGenerator(List<Id> testIds) {
        this.testIds = testIds;
    }

    public List<Id> execute() {
        List<Result__c> results = new List<Result__c>();
        List<Test__c> tests = new TestsSelector().byIds(new Set<Id>(testIds));

        for (Test__c testRecord : tests) {
            String status;

            if (Test.isRunningTest()) {
                status = mockResultStatus;
            } else {
                status = 'In Progress';
            }

            Result__c result = new Result__c(
                Job_Type__c = testRecord.ExtensionConfiguration__r.ExtensionTool__c,
                Progress_Status__c = status,
                Status__c = status,
                Start_Time__c = Datetime.now(),
                Test__c = testRecord.id
            );
            uow.registerNew(result);
            results.add(result);
        }
        uow.commitWork();

        return idsOnly(results);
    }

    //PRIVATE

    private static List<Id> idsOnly(List<SObject> records) {
        return new List<Id>(new Map<Id, SObject>(records).keySet());
    }
}