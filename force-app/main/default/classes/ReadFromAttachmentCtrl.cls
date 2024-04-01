public with sharing class ReadFromAttachmentCtrl {
    /** Note: this methods bypasses apex heap size limit until certain point **/
    @AuraEnabled(cacheable=true)
    public static String getAttachment(Id parentId, String name) {
        try {
            String result = '';
            List<Attachment> attachments = new AttachmentsSelector().byParentIdAndName(new Set<Id>{ parentId }, new Set<String>{ name });
            if (!attachments.isEmpty()) {
                result = EncodingUtil.base64Encode(attachments[0].Body);
            }
            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }
}