public with sharing class UpdateTemplateDetailAttachment {
    List<Data_Template__c> templates;
    Map<Id, Data_Template__c> oldTemplates;

    public UpdateTemplateDetailAttachment(List<Data_Template__c> templates, Map<Id, Data_Template__c> oldTemplates) {
        this.templates = templates;
        this.oldTemplates = oldTemplates;
    }

    public void execute() {
        try {
            Map<Id, Data_Template__c> changedTemplates = new Map<Id, Data_Template__c>();

            for (Data_Template__c template : templates) {
                if (
                    (template.Name != oldTemplates.get(template.Id).Name) || template.Description__c != oldTemplates.get(template.Id).Description__c
                ) {
                    changedTemplates.put(template.Id, template);
                }
            }

            if (changedTemplates.isEmpty()) {
                return;
            }

            List<Attachment> attachments = new AttachmentsSelector()
                .byParentIdAndName(changedTemplates.keySet(), new Set<String>{ DataTemplateDetail.ATTACHMENT_NAME });

            for (Attachment attachment : attachments) {
                DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(attachment.Body.toString(), DataTemplateDetail.class);
                templateDetail.dataTemplate.templateName = changedTemplates.get(attachment.ParentId)?.Name;
                templateDetail.dataTemplate.templateDescription = changedTemplates.get(attachment.ParentId)?.Description__c;
                attachment.Body = Blob.valueOf(JSON.serialize(templateDetail));
            }

            Utilities.Secure_DML(attachments, Utilities.DML_Action.UPD, Schema.SObjectType.Attachment);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'exception line' + ex.getLineNumber() + 'exception message' + ex.getMessage());
        }
    }
}