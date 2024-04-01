@IsTest
public class CopadoDomainTest {

    @TestSetup
    private static void setup() {

        GlobalAPI.UserLicense licence = new GlobalAPI.UserLicense();
        licence.isCADEnabled = true;
        licence.isCCHEnabled = true;
        licence.isCCMEnabled = true;
        licence.isCopadoEnabled = true;
        licence.isCSTEnabled = true;
        licence.userId = UserInfo.getUserId();

        new GlobalAPI().upsertCopadoLicense(licence);
    }


    @IsTest
    private static void promotion() {

        // Exercise
        new Promotion(new Release(), new Credential(), new Credential()).persist();

        // Verify
        System.assertEquals(2, [SELECT Count() FROM Org__c]);
        System.assertEquals(2, [SELECT Count() FROM Environment__c]);
        System.assertEquals(1, [SELECT Count() FROM Deployment_Flow__c]);
        System.assertEquals(1, [SELECT Count() FROM Git_Repository__c]);
        System.assertEquals(1, [SELECT Count() FROM Deployment_Flow_Step__c]);
        System.assertEquals(1, [SELECT Count() FROM Project__c]);
        System.assertEquals(1, [SELECT Count() FROM Release__c]);
        System.assertEquals(1, [SELECT Count() FROM Promotion__c]);

        // Further asserts on actual fields
    }


    @IsTest
    private static void promotionWithParentsManually() {

        Promotion pro = new Promotion();

        // Exercise
        new Pipeline()
                .add( new Connection(
                            new Environment()
                                    .add( new Credential() )
                                    .add( pro ),
                            new Environment()
                                    .add( new Credential() ) ))
                .add( new Project()
                            .add( new Release() )
                            .add( pro ))
                .persist();

        // Verify
        System.assertEquals(2, [SELECT Count() FROM Org__c]);
        System.assertEquals(2, [SELECT Count() FROM Environment__c]);
        System.assertEquals(1, [SELECT Count() FROM Deployment_Flow__c]);
        System.assertEquals(1, [SELECT Count() FROM Git_Repository__c]);
        System.assertEquals(1, [SELECT Count() FROM Deployment_Flow_Step__c]);
        System.assertEquals(1, [SELECT Count() FROM Project__c]);
        System.assertEquals(1, [SELECT Count() FROM Release__c]);
        System.assertEquals(1, [SELECT Count() FROM Promotion__c]);

        // Further asserts on actual fields
    }


    @IsTest
    private static void userStoryWithAllParents() {

        // Exercise
        Promotion pro = new Promotion(new Release(), new Credential(), new Credential());

        pro.persist();

        new Deployment(pro)
                .add( new Step() )
                .add( new UserStory() )
            .persist();

        // Verify
        System.assertEquals(2, [SELECT Count() FROM Org__c]);
        System.assertEquals(2, [SELECT Count() FROM Environment__c]);
        System.assertEquals(1, [SELECT Count() FROM Deployment_Flow__c]);
        System.assertEquals(1, [SELECT Count() FROM Git_Repository__c]);
        System.assertEquals(1, [SELECT Count() FROM Deployment_Flow_Step__c]);
        System.assertEquals(1, [SELECT Count() FROM Project__c]);
        System.assertEquals(1, [SELECT Count() FROM Release__c]);
        System.assertEquals(1, [SELECT Count() FROM Promotion__c]);
        System.assertEquals(1, [SELECT Count() FROM Deployment__c]);
        System.assertEquals(1, [SELECT Count() FROM Destination_Org__c]);
        System.assertEquals(1, [SELECT Count() FROM Step__c]);
        System.assertEquals(1, [SELECT Count() FROM User_Story__c]);

        // Further asserts on actual fields
    }
}