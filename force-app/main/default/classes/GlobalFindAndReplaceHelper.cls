public with sharing virtual class GlobalFindAndReplaceHelper {
    // PUBLIC

    // Return the copado.yml ContentVersionId for the pipeline, or the environment (source or destination)
    public static String getContentVersionOfYamlFile(Id contextId, Boolean useSourceEnvironment) {
        JobStep__c step = new JobStepsSelector().byId(contextId);

        Id pipelineId = step.Pipeline_Id__c;
        Set<Id> ids = new Set<Id>();
        ids.add(pipelineId);
        String environmentId = useSourceEnvironment ? step.Source_Id__c : step.Destination_Id__c;
        ids.add(environmentId);

        Id pipelineFile;
        Id environmentFile;

        // get all the Files associated with the Pipeline or environment, due to SOQL ContentDocumentLink query limitations (you cannot WHERE by name)
        List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector().byLinkedEntityId(ids);
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            if (
                (contentDocumentLink.ContentDocument.Title.equals('Copado') || contentDocumentLink.ContentDocument.Title.equals('Copado.yml')) &&
                contentDocumentLink.ContentDocument.FileExtension.equals('yml')
            ) {
                if (contentDocumentLink.LinkedEntityId == pipelineId) {
                    pipelineFile = contentDocumentLink.ContentDocument.LatestPublishedVersionId;
                } else if (contentDocumentLink.LinkedEntityId == environmentId) {
                    environmentFile = contentDocumentLink.ContentDocument.LatestPublishedVersionId;
                }
            }
        }
        return pipelineFile != null ? pipelineFile : environmentFile;
    }
}