public with sharing class Test_t extends DomainBuilder {
    public Test_t() {
        super(Test__c.SObjectType);
    }

    public Test_t name(String name) {
        return (Test_t) set(Test__c.Name, name);
    }

    public Test_t extensionConfiguration(ExtensionConfiguration extensionConfiguration) {
        setParent(Test__c.ExtensionConfiguration__c, extensionConfiguration);
        return this;
    }

    public Test_t userStory(UserStory userStory) {
        setParent(Test__c.User_Story__c, userStory);
        return this;
    }

    public Test_t jobExecution(JobExecution jobExecution) {
        setParent(Test__c.LatestJobExecution__c, jobExecution);
        return this;
    }
}