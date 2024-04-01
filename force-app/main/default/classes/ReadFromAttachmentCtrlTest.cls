@IsTest
private with sharing class ReadFromAttachmentCtrlTest {
    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(10, 10, 10, 10, 10, 100);
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }
    @IsTest
    private static void testReadAttachment() {
        System.runAs(getUser()) {
            // SETUP

            MetaDataItem metadata = new MetaDataItem();
            metadata.n = 'name';
            metadata.r = false;
            metadata.t = 'ApexClass';

            Artifact__c mainPackage = new Artifact__c(
                Name = 'Test_mainPackage',
                RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId()
            );
            insert mainPackage;

            Artifact_Version__c version = new Artifact_Version__c(Artifact__c = mainPackage.Id, Name = 'Version one');
            insert version;

            Attachment content = new Attachment(ParentId = version.Id, Name = 'Metadata', Body = Blob.valueOf(JSON.serialize(metadata)));
            insert content;

            // EXERCISE

            String result = EncodingUtil.base64Decode(ReadFromAttachmentCtrl.getAttachment(version.Id, 'Metadata')).toString();

            // VERIFY

            System.assertEquals(JSON.serialize(metadata), result, 'Attachment content does not match');
        }
    }

    private static User getUser() {
        User standardUser = [SELECT Id, Username FROM User WHERE Username = 'test_user@myorg.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true, true);
        return standardUser;
    }
}