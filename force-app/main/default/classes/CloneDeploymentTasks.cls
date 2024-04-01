public with sharing class CloneDeploymentTasks implements Queueable, Finalizer {
    private static final String GENERIC_NOTIFICATION_EMAIL_TEMPLATE = 'GenericNotification';
    private static final String EMAIL_BODY = 'emailBody';
    private static final String EMAIL_TITLE = 'emailTitle';
    private static final String STORY_DETAILS = '{STORY_DETAILS}';

    private List<User_Story__c> childStories;
    private User_Story__c parentStory;
    private Integer position;

    // CONSTRUCTOR

    public CloneDeploymentTasks(List<User_Story__c> childStories, User_Story__c parentStory) {
        this(childStories, parentStory, 0);
    }

    public CloneDeploymentTasks(List<User_Story__c> childStories, User_Story__c parentStory, Integer position) {
        this.childStories = childStories;
        this.parentStory = parentStory;
        this.position = position;
    }

    public CloneDeploymentTasks(User_Story__c parentStory) {
        this.parentStory = parentStory;
    }

    // PUBLIC

    public void execute(QueueableContext context) {
        Finalizer finalizer = new CloneDeploymentTasks(parentStory);
        System.attachFinalizer(finalizer);
        if (childStories.size() > position) {
            Set<Id> tasks = new Map<Id, Deployment_Task__c>(
                    new DeploymentTasksSelector().byStories(new Set<Id>{ childStories[position].Id })
                )
                .keySet();
            if (!tasks.isEmpty()) {
                String serialized = SObjectDataLoader.serialize(
                    tasks,
                    new SObjectDataLoader.SerializeConfig().followChild(Attachment.ParentId).omit(Deployment_Task__c.User_Story__c)
                );
                SObjectDataLoader.deserialize(serialized, new SetParentStoryCallback(parentStory));
            }
            position++;
            if ((childStories.size() > position) && !Test.isRunningTest()) {
                System.enqueueJob(new CloneDeploymentTasks(childStories, parentStory, position));
            }
        }
    }

    public void execute(FinalizerContext context) {
        if (context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            if(parentStory != null) {
                parentStory = new UserStoriesSelector().byIds(new Set<Id>{ parentStory.Id })[0];
            }
            List<Id> recipientIds = new List<Id>{ UserInfo.getUserId() };
            String emailSubject = Label.USB_FAILURE_EMAIL_SUBJECT;
            Messaging.SingleEmailMessage message = Utilities.createEmail(
                recipientIds,
                emailSubject,
                getEmailTemplateBody(context.getException().getMessage() + '<br/>' + context.getException().getStackTraceString())
            );
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
        }
    }

    // PRIVATE
    
    @TestVisible
    private String getEmailTemplateBody(String emailBody) {
        String emailTitle = parentStory != null ? Label.USB_FAILURE_EMAIL_TITLE.replace(
            STORY_DETAILS,
            parentStory.Name +
            ' - ' +
            parentStory.User_Story_Title__c
        ) : Label.USB_FAILURE_EMAIL_TITLE;
        List<EmailTemplate> templates = new EmailTemplatesSelector().byDevName(GENERIC_NOTIFICATION_EMAIL_TEMPLATE);
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templates[0].Id, null, null);
        String emailHTMLBody = message.htmlbody == null
            ? ''
            : message.htmlbody.replace(EMAIL_BODY, emailBody).replace(EMAIL_TITLE, emailTitle);
        return emailHTMLBody;
    }

    private class SetParentStoryCallback implements SObjectDataLoader.IDeserializeCallback {
        private Id scenarioId;

        public SetParentStoryCallback(SObject clone) {
            scenarioId = clone.Id;
        }

        public void unresolvedReferences(SObjectType type, List<SObjectDataLoader.UnresolvedReferences> unresolved) {
            if (type == Deployment_Task__c.SObjectType) {
                for (SObjectDataLoader.UnresolvedReferences refs : unresolved) {
                    if (refs.References.contains(Deployment_Task__c.User_Story__c)) {
                        refs.Record.put(Deployment_Task__c.User_Story__c, scenarioId);
                    }
                }
            }
        }
    }
}