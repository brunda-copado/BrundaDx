public with sharing class DataTemplateInformationsCtrl {
    @AuraEnabled(cacheable=true)
    public static Integer getRelatedObjectCount(Id templateId) {
        try {
            Integer totalObjects = 0;
            List<Attachment> attachments = new AttachmentsSelector()
                .byParentIdAndName(new Set<Id>{ templateId }, new Set<String>{ DataTemplateDetail.ATTACHMENT_NAME });
            if (attachments != null && !attachments.isEmpty()) {
                DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(attachments[0].Body.toString(), DataTemplateDetail.class);
                totalObjects = templateDetail.parentObjectsReferenceList?.size() + templateDetail.childrenObjectsReferenceList?.size();
            }
            return totalObjects;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}