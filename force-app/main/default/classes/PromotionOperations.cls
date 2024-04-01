public with sharing class PromotionOperations {

    private Id projectId;
    private Id releaseId;
    private Boolean backPromotion;
    private Id sourceEnvironmentId;
    private String orderUserStoriesBy;
    private Id destinationEnvironmentId;

    // CONSTRUCTOR

    public PromotionOperations(Id sourceEnvironmentId) {
        this(sourceEnvironmentId, null, false);
    }

    public PromotionOperations(Id sourceEnvironmentId, Id destinationEnvironmentId, Boolean backPromotion) {
        this.backPromotion = backPromotion;
        this.sourceEnvironmentId = sourceEnvironmentId;
        this.destinationEnvironmentId = destinationEnvironmentId;
    }

    // PUBLIC

    public PromotionOperations projectId(Id projectId) {
        this.projectId = projectId;
        return this;
    }

    public PromotionOperations releaseId(Id releaseId) {
        this.releaseId = releaseId;
        return this;
    }

    public PromotionOperations orderUserStoriesBy(String orderUserStoriesBy) {
        this.orderUserStoriesBy = orderUserStoriesBy;
        return this;
    }

    public Promotion__c insertPromotion() {
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Promotion__c> { promotion() });
        insert decision.getRecords();
        return ((List<Promotion__c>) decision.getRecords())[0];
    }

    public Promotion__c promotion() {
        return new Promotion__c(
            Back_Promotion__c = backPromotion,
            Project__c = projectId,
            Release__c = releaseId,
            Order_by__c = orderUserStoriesBy,
            Source_Environment__c = sourceEnvironmentId,
            Destination_Environment__c = destinationEnvironmentId
        );
    }
}