public with sharing class CreateAttachmentAction {
    public with sharing class Request {
        @InvocableVariable(label='String Data')
        public String stringData;

        @InvocableVariable(label='Parent record')
        public Id parentRecord;
    }

    @InvocableMethod(label='Create Attachment' description='Create Attachment linked to the specified parent record')
    public static void execute(List<Request> requests) {
        List<Attachment> attachments = new List<Attachment>();

        for (Request req : requests) {
            attachments.add(new Attachment(
                Name = 'ApexTestResult',
                Body = Blob.valueOf(req.stringData),
                ParentId = req.parentRecord
            ));
        }

        Utilities.Secure_DML(attachments, Utilities.DML_Action.INS, Schema.SObjectType.Attachment);
    }
}