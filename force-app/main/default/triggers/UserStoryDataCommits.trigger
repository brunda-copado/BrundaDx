trigger UserStoryDataCommits on User_Story_Data_Commit__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    fflib_SObjectDomain.triggerHandler(UserStoryDataCommits.class);
}