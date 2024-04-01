public with sharing class PromoteBundledChildStories implements Queueable {
    private Set<Id> promotions = new Set<Id>();
    private Set<Id> parentBundleStories = new Set<Id>();
    private Set<Id> stories = new Set<Id>();

    // CONSTRUCTORS

    public PromoteBundledChildStories(Set<Id> promotions) {
        this.promotions = promotions;
    }

    // PUBLIC

    public void execute(QueueableContext qc) {
        Savepoint sp = Database.setSavepoint();

        try {
            promoteUpdateChildStories();
        } catch (Exception ex) {
            Database.rollback(sp);
            notifyViaEmail(ex);
        }
    }

    // PRIVATE

    private void promoteUpdateChildStories() {
        Map<Id, List<Promoted_User_Story__c>> junctionsByPromotion = groupJunctionsByPromotions();

        if (!junctionsByPromotion.isEmpty()) {
            fflib_ISObjectUnitOfWork uow = uow();

            Map<Id, Set<Id>> storiesByParentBundle = groupStoriesByParent();
            Map<Id, User_Story__c> storiesById = new Map<Id, User_Story__c>(new UserStoriesSelector().byIds(stories));

            for (Promotion__c promotion : new PromotionsSelector().byIds(junctionsByPromotion.keySet())) {
                Promotion__c newPromotion = promotion.clone();
                uow.registerNew(newPromotion);

                for (Promoted_User_Story__c junction : junctionsByPromotion.get(promotion.Id)) {
                    for (Id story : storiesByParentBundle.get(junction.User_Story__c)) {
                        uow.registerNew(newChildPromotion(storiesById.get(story)), Promoted_User_Story__c.Promotion__c, newPromotion);
                        uow.registerDirty(syncChildStoryWithParent(newPromotion, story));
                    }
                }
            }

            uow.commitWork();
        }
    }

    private Map<Id, List<Promoted_User_Story__c>> groupJunctionsByPromotions() {
        Map<Id, List<Promoted_User_Story__c>> result = new Map<Id, List<Promoted_User_Story__c>>();

        for (Promoted_User_Story__c junction : new PromotedUserStoriesSelector().byBundleUSPromotions(promotions)) {
            parentBundleStories.add(junction.User_Story__c);

            if (result.containsKey(junction.Promotion__c)) {
                result.get(junction.Promotion__c).add(junction);
            } else {
                result.put(junction.Promotion__c, new List<Promoted_User_Story__c>{ junction });
            }
        }

        return result;
    }

    private Map<Id, Set<Id>> groupStoriesByParent() {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        for (Bundled_Story__c bundledStory : new BundledStorySelector().byParentUSBIds(parentBundleStories)) {
            stories.add(bundledStory.User_Story__c);

            Id parentUSB = bundledStory.Package_Version__r.User_Story__c;

            if (!result.containsKey(parentUSB)) {
                result.put(parentUSB, new Set<Id>{ bundledStory.User_Story__c });
            } else {
                result.get(parentUSB).add(bundledStory.User_Story__c);
            }
        }

        return result;
    }

    private Promoted_User_Story__c newChildPromotion(User_Story__c story) {
        return new Promoted_User_Story__c(Name = PromotionConstants.PROMOTED_USER_STORY + ' ' + story.Name, User_Story__c = story.Id);
    }

    private User_Story__c syncChildStoryWithParent(Promotion__c promotion, Id story) {
        return new User_Story__c(
            Id = story,
            Org_Credential__c = promotion.Destination_Org_Credential__c,
            Environment__c = promotion.Destination_Environment__c
        );
    }

    private void notifyViaEmail(Exception ex) {
        Messaging.SingleEmailMessage message = Utilities.createEmail(
            new List<String>{ UserInfo.getUserId() },
            Label.USB_ERROR_EMAIL_SUBJECT,
            messageFromTemplate(ex)
        );

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
    }

    private String messageFromTemplate(Exception ex) {
        List<EmailTemplate> template = new EmailTemplatesSelector().byDevName('GenericNotification');
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template[0].Id, null, null);

        return (message.htmlbody == null)
            ? ''
            : message.htmlbody.replace('emailBody', ex.getMessage() + '<br/>' + ex.getStackTraceString())
                  .replace('emailTitle', Label.USB_ERROR_EMAIL_TITLE);
    }

    private fflib_SObjectUnitOfWork uow() {
        return new fflib_SObjectUnitOfWork(
            new List<SObjectType>{ Promotion__c.SObjectType, User_Story__c.SObjectType, Promoted_User_Story__c.SObjectType }
        );
    }
}