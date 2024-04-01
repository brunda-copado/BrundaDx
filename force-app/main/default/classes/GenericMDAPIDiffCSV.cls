/**
 * Created by dineshdk on 14/08/2018.
 * Last Modified By kunal kaushik 24/02/2022.
 */


public with sharing class GenericMDAPIDiffCSV {

    public List<JsonWrapperOrgDiff> jwOrgDiffs { get; set; }
    public List<JsonWrapperSnapDiff> jwSnapDiffs { get; set; }
    public Boolean jsonValflag { get; set; }
    public Boolean typeOrgDiffflag { get; set; }
    public Boolean typeSnapDiffflag { get; set; }
    public String recordId;
    public String currentPage;
    public static final Integer MAX_SIZE = 10000;
    public List<List< JsonWrapperOrgDiff>> jwOrgDiffsList{ 
        get {
            if(null == jwOrgDiffsList){
                jwOrgDiffsList = new List<List<JsonWrapperOrgDiff>>();
            }
            return jwOrgDiffsList;
        } private set; 
    }
    

    public GenericMDAPIDiffCSV(){
    }

    public GenericMDAPIDiffCSV(ApexPages.StandardController controller) {
        try{
            recordId = ApexPages.currentPage().getParameters().get('Id');
            currentPage = ApexPages.currentPage().getParameters().get('currentPage');
            jsonValflag = false;
            typeOrgDiffflag = false;
            typeSnapDiffflag = false;

            jsontoApex(recordId);
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Contact_System_Administrator + '  Message: '+e.getMessage() + '  Stack Trace: ' + e.getStackTraceString()));
        }
    }

    public void jsontoApex(String recordId) {
        List<Attachment> attLst = new List<Attachment>();
        String json;
        jwOrgDiffs = new List<JsonWrapperOrgDiff>();
        jwSnapDiffs = new List<JsonWrapperSnapDiff>();
        if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
            if(currentPage.equalsIgnoreCase('SnapshotDifferenceCSV')) {
                attLst = [SELECT Id,Name,Body FROM Attachment WHERE ParentId = :recordId AND Name = 'index.json' ORDER BY LastModifiedDate DESC LIMIT 1];
                if(attLst.size()>0){
                    json = attLst[0].Body.toString();
                    try{
                        if(!String.isBlank(json)){
                            jwSnapDiffs = (List<JsonWrapperSnapDiff>) System.JSON.deserialize(json, List<JsonWrapperSnapDiff>.class);
                            System.debug('jwSnapDiffs: ' + jwSnapDiffs);
                        }
                    } catch(Exception e){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Attachment_format_not_correct));
                        return;
                    }

                    typeOrgDiffflag = false;
                    typeSnapDiffflag = true;
                }
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Attachment_was_found));
                }

            } else if(currentPage.equalsIgnoreCase('ViewOrgDiffCSV')) {
                attLst = [SELECT Id,Name,Body FROM Attachment WHERE ParentId = :recordId AND Name = 'OrgDiff' ORDER BY LastModifiedDate DESC LIMIT 1];
                if(attLst.size()>0){
                    json = attLst[0].Body.toString();
                    try{
                        if(!String.isBlank(json)){
                            jwOrgDiffs = (List<JsonWrapperOrgDiff>) System.JSON.deserialize(json, List<JsonWrapperOrgDiff>.class);
                            Integer listSize = MAX_SIZE;
                            Integer lastSublistSize = math.mod(jwOrgDiffs.size(), MAX_SIZE);
                            Integer index = 0;
                            Integer noOfSubLists = jwOrgDiffs.size() / MAX_SIZE;

                            if(jwOrgDiffs.size() > 0 && jwOrgDiffs.size() < MAX_SIZE){
                                noOfSubLists = 1;
                            }
                            if(lastSublistSize > 0 && jwOrgDiffs.size() > MAX_SIZE){
                                noOfSubLists++;
                            }

                            for(Integer index1 = 0; index1 < noOfSubLists; index1++){
                                if(lastSublistSize > 0 && index1 == noOfSubLists - 1){
                                    listSize = lastSublistSize;
                                }
                                jwOrgDiffsList.add(new List<JsonWrapperOrgDiff>());
                                for(Integer index2 = 0; index2 < listSize; index2++){
                                    jwOrgDiffsList[index1].add(jwOrgDiffs[index++]);
                                }
                            }
                        }
                    } catch(Exception e){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Attachment_format_not_correct));
                        return;
                    }

                    typeOrgDiffflag = true;
                    typeSnapDiffflag = false;
                }
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Attachment_was_found));
                }
            }
            if(!jwOrgDiffs.isEmpty() || !jwSnapDiffs.isEmpty()) {
                jsonValflag = true;
            } else {
                jsonValflag = false;
            }
        }
        else{
            ApexPages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING, Schema.SObjectType.Attachment.getName() +': ' + Label.Insufficient_Access_Rights));
        }
    }

    public class JsonWrapperOrgDiff {
        public String t { get; set; } //Type
        public String n { get; set; } //Name
        public String s { get; set; } //Status
        public String d { get; set; } //Last Modified By ID
        public String b { get; set; } //Last Modified By Date
        public String cd { get; set; } //Created Date
        public String cb { get; set; } //Created By ID
    }

    public class JsonWrapperSnapDiff {
        public String f { get; set; } //Metadata
        public Boolean s { get; set; }
        public String d { get; set; } //Status
        public String n { get; set; } //Name
        public String t { get; set; } //Type
    }
}