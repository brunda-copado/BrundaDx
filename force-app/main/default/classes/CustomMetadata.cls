public with sharing class CustomMetadata {


    // Note: Metadata service accepts only 10 records at a time
    public static List<MetadataService.SaveResult> create(List<MetadataService.Metadata> metadata) {
        List<MetadataService.SaveResult> result = new List<MetadataService.SaveResult>();

        List<MetadataService.Metadata> currentBatch = new List<MetadataService.Metadata>();
        Integer batchSize = 10;

        for(MetadataService.Metadata record : metadata) {
            currentBatch.add(record);

            if(currentBatch.size() == batchSize && !currentBatch.isEmpty()) {
                result.addAll(mdApi().createMetadata(currentBatch));
                currentBatch.clear();
            }
        }
        
        if(!currentBatch.isEmpty()) {
            result.addAll(mdApi().createMetadata(currentBatch));            
        }

        return result;
    }
    
    
    // Note: Metadata service accepts only 10 records at a time
    public static List<MetadataService.SaveResult> updateMetadata(List<MetadataService.Metadata> metadata) {
        List<MetadataService.SaveResult> result = new List<MetadataService.SaveResult>();

        List<MetadataService.Metadata> currentBatch = new List<MetadataService.Metadata>();
        Integer batchSize = 10;

        for(MetadataService.Metadata record : metadata) {
            currentBatch.add(record);

            if(currentBatch.size() == batchSize && !currentBatch.isEmpty()) {
                result.addAll(mdApi().updateMetadata(currentBatch));
                currentBatch.clear();
            }
        }
        
        if(!currentBatch.isEmpty()) {
            result.addAll(mdApi().updateMetadata(currentBatch));            
        }

        return result;
    }


    // Note: Metadata service accepts only 10 records at a time
    public static List<MetadataService.DeleteResult> deleteMetadata(String type, List<String> metadataNames) {
        List<MetadataService.DeleteResult> result = new List<MetadataService.DeleteResult>();

        List<String> currentBatch = new List<String>();
        Integer batchSize = 10;

        for(String metadataName : metadataNames) {
            currentBatch.add(metadataName);

            if(currentBatch.size() == batchSize && !currentBatch.isEmpty()) {
                result.addAll(mdApi().deleteMetadata(type, currentBatch));
                currentBatch.clear();
            }
        }
        
        if(!currentBatch.isEmpty()) {
            result.addAll(mdApi().deleteMetadata(type, currentBatch));            
        }

        return result;
    }


    private static MetadataService.MetadataPort mdApi() {
        MetadataService.MetadataPort result = null;

        try {
            result = new MetadataService.MetadataPort();
            result.SessionHeader = new MetadataService.SessionHeader_element();
            result.SessionHeader.sessionId = UserInfo.getSessionId();
        }
        catch(Exception ex) {
            ApexPages.addMessages(ex);
        }

        return result;
    }
}