public with sharing class Changes {
    private List<User_Story_Metadata__c> metadataChanges;

    public Changes metadata(List<User_Story_Metadata__c> metadataChanges) {
        this.metadataChanges = metadataChanges;
        return this;
    }

    public List<String> getValues(String node) {
        List<String> result = new List<String>();
        if (metadataChanges != null) {
            for (User_Story_Metadata__c file : metadataChanges) {
                String value = getValue(file, node);
                if (String.isNotBlank(value)) {
                    result.add(value);
                }
            }
        }
        return result;
    }

    private String getValue(User_Story_Metadata__c metadata, String node) {
        String result;
        switch on node {
            when 'Name' {
                result = metadata.Metadata_API_Name__c;
            }
            when 'Directory' {
                result = metadata.ModuleDirectory__c;
            }
            when 'Type' {
                result = metadata.Type__c;
            }
        }
        return result;
    }
}