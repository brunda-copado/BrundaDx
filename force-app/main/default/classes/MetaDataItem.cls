public class MetaDataItem {
    @AuraEnabled
    public String t { get; set; } // Metadata Type
    @AuraEnabled
    public String n { get; set; } // Metadata Name
    @AuraEnabled
    public Boolean r { get; set; } // Retrieve Only
    @AuraEnabled
    public Boolean s { get; set; } // Metadata Is Selected
    @AuraEnabled
    public String cb { get; set; } // Created By
    @AuraEnabled
    public String cd { get; set; } // Created Date
    @AuraEnabled
    public String vk { get; set; } // Vlocity key
}