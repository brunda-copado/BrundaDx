@IsTest
public class Sprint extends DomainBuilder {
    public Sprint() {
        super(Sprint__c.SObjectType);
    }

    public Sprint name(String name) {
        return (Sprint) set(Sprint__c.Name, name);
    }

    public Sprint startDate(Date startDate) {
        return (Sprint) set(Sprint__c.Start_Date__c, startDate);
    }

    public Sprint endDate(Date endDate) {
        return (Sprint) set(Sprint__c.End_Date__c, endDate);
    }

    public Sprint status(String status) {
        return (Sprint) set(Sprint__c.Status__c, status);
    }

    public Sprint add(UserStory userStory) {
        userStory.setParent(User_Story__c.Sprint__c, this);
        return this;
    }
}