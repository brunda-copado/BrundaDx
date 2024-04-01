public with sharing class SetSystemPropertySharing {

    private List<System_Property__c> publicRecords;
    private List<System_Property__c> privateRecords;

    // CONSTRUCTOR

    public SetSystemPropertySharing(List<System_Property__c> records, Map<Id, System_Property__c> oldRecords) {
        publicRecords = filterPublicRecords(records, oldRecords);
        privateRecords = filterPrivateRecords(records, oldRecords);
    }

    public SetSystemPropertySharing(List<System_Property__c> records) {
        publicRecords = filterPublicRecords(records, new Map<Id, System_Property__c>());
        privateRecords = filterPrivateRecords(records, new Map<Id, System_Property__c>());
    }


    // PUBLIC

    public void execute() {
        Id allUsersGroupId = [SELECT Id FROM Group WHERE Type = 'Organization' LIMIT 1].Id;

        List<System_Property__Share> shareRecordsToBeCreated = new List<System_Property__Share>();
        List<System_Property__Share> shareRecordsToBeDeleted = [SELECT Id FROM System_Property__Share WHERE ParentId IN :privateRecords AND UserOrGroupId = :allUsersGroupId WITH SYSTEM_MODE];

        for(System_Property__c publicRecord : publicRecords) {
            shareRecordsToBeCreated.add(new System_Property__Share(
                ParentId = publicRecord.Id,
                UserOrGroupId = allUsersGroupId,
                RowCause = Schema.System_Property__Share.RowCause.isPublic__c,
                AccessLevel = 'Read'
            ));
        }

        DML.insertAsSystem(shareRecordsToBeCreated, 'Failed to create sharing records');
        DML.deleteAsSystem(shareRecordsToBeDeleted, 'Failed to delete sharing records');
    }


    // PRIVATE

    private List<System_Property__c> filterPublicRecords(List<System_Property__c> records, Map<Id, System_Property__c> oldRecords) {
        List<System_Property__c> result = new List<System_Property__c>();

        for(System_Property__c record : records) {
            System_Property__c oldRecord = oldRecords.get(record.Id);

            if((oldRecord == null || oldRecord.Is_Public__c == false) && record.Is_Public__c == true) {
                result.add(record);
            }
        }

        return result;
    }

    private List<System_Property__c> filterPrivateRecords(List<System_Property__c> records, Map<Id, System_Property__c> oldRecords) {
        List<System_Property__c> result = new List<System_Property__c>();

        for(System_Property__c record : records) {
            System_Property__c oldRecord = oldRecords.get(record.Id);

            if((oldRecord == null || oldRecord.Is_Public__c == true) && record.Is_Public__c == false) {
                result.add(record);
            }
        }

        return result;
    }
}