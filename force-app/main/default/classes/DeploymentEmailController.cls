public with sharing class DeploymentEmailController {

    public static String deployId {get;set;}
    public static String podUri{get;set;}
    public static String statusMessage{get;set;}
    public static List<Deployment_Job__c> deploymentJobs{get;set;}
    public static final Integer MAX_BODY_LENGTH = 300000;

    public static String getPodUrl() {
        	return URL.getSalesforceBaseUrl().toExternalForm();
    }

    public static List<StepsWrapper> getDeploymentSteps() {
        Id previousStep = null;
        DeploymentConstant constant = new DeploymentConstant();
        List<StepsWrapper> lsw = new List<StepsWrapper>();
        List<String> parentIds = new List<String>();
        List<Deployment_Job__c> deploymentSteps = new List<Deployment_Job__c>();
        Map<Id,Attachment> stepAttachment = new Map<Id,Attachment>();

        if(String.isBlank(deployId)){
            statusMessage = Label.Deployment_Not_Found;
            return new List<StepsWrapper>();
        }

        if(Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            deploymentSteps = [ SELECT Step__r.Deployment__c, Step__r.CheckOnly__c, Step__r.Name, Status__c, Step__r.Type__c, Step__r.Deployment__r.Name, To_Org_Name__c
                                FROM Deployment_Job__c
                                WHERE Step__r.Deployment__c = :deployId
                                WITH USER_MODE
                                ORDER BY Step__r.Order__c ASC ];
        }

        for (Deployment_Job__c st: deploymentSteps) {
            parentIds.add(st.Step__c);
        }
        List<Attachment> atts = getAttachment(parentIds, '%MetaData');
        
        for (Attachment att: atts) {
           stepAttachment.put(att.ParentId, att);
        }

        for (Deployment_Job__c step: deploymentSteps) {
            if (previousStep != step.Step__c && previousStep != null) {
                if (stepAttachment.containsKey(previousStep)) {
                    Attachment att = stepAttachment.get(previousStep);
                    if(att.BodyLength <= MAX_BODY_LENGTH){
                        try{
                            List<Object> results = (List<Object>)JSON.deserializeUntyped(att.Body.toString());
                            for(Object o : results){
                                Map<String, Object> meta = (Map<String, Object>)o;
                                StepsWrapper swChild = new StepsWrapper();
                                swChild.className = 'MetaData';
                                swChild.t = 'Metadata Component';
                                swChild.n = '';
                                swChild.s = '';
                                try{ swChild.ct = (String)meta.get('t'); }catch(Exception ex){ swChild.ct=''; }
                                try{ swChild.cn = (String)meta.get('n'); }catch(Exception ex){ swChild.cn=''; }
                                lsw.add(swChild);
                            }

                            StepsWrapper swChild = new StepsWrapper();
                            swChild.className = 'Division';
                            swChild.t = '';
                            swChild.n = '';
                            swChild.s = '';
                            swChild.ct = '';
                            swChild.cn = '';
                            lsw.add(swChild);
                        }
                        catch(Exception e){
                            statusMessage = constant.ERROR_PARSING_JSON+e.getMessage();
                            return new List<StepsWrapper>();
                        }
                    }
                    else{
                        statusMessage = Label.MAX_FILE_SIZE_EXCEEDED;
                        return new List<StepsWrapper>();
                    }
                }
            }

            StepsWrapper sw = new StepsWrapper();
            sw.t = step.Step__r.Type__c;
            sw.n = step.Step__r.Name;
            sw.s = step.Status__c;
            sw.o = step.To_Org_Name__c;
            sw.co = step.Step__r.CheckOnly__c;
            sw.cn = '';
            sw.ct = '';
            sw.className = 'Step';
            lsw.add(sw);

            previousStep = step.Step__c;
        }

        if (stepAttachment.containsKey(previousStep)) {
            Attachment att = stepAttachment.get(previousStep);
            if(att.BodyLength <= MAX_BODY_LENGTH){
                try{
                    List<Object> results = (List<Object>)JSON.deserializeUntyped(att.Body.toString());
                    for(Object o : results){
                        Map<String, Object> meta = (Map<String, Object>)o;
                        StepsWrapper swChild = new StepsWrapper();
                        swChild.className = 'MetaData';
                        swChild.t = 'Metadata Component';
                        swChild.n = '';
                        swChild.s = '';
                        try{ swChild.ct = (String)meta.get('t'); }catch(Exception ex){ swChild.ct=''; }
                        try{ swChild.cn = (String)meta.get('n'); }catch(Exception ex){ swChild.cn=''; }
                        lsw.add(swChild);
                    }

                    StepsWrapper swChild = new StepsWrapper();
                    swChild.className = 'Division';
                    swChild.t = '';
                    swChild.n = '';
                    swChild.s = '';
                    swChild.ct = '';
                    swChild.cn = '';
                    lsw.add(swChild);
                }
                catch(Exception e){
                    statusMessage = constant.ERROR_PARSING_JSON+e.getMessage();
                    return new List<StepsWrapper>();
                }
            }
            else{
                statusMessage = Label.MAX_FILE_SIZE_EXCEEDED;
                return new List<StepsWrapper>();
            }
        }
        return lsw;
    }

    public static List<ErrorContent> getErrorMessages() {
        DeploymentConstant constant = new DeploymentConstant();
        List<ErrorContent> errorDetails = new List<ErrorContent>();

        if(String.isBlank(deployId)){
            statusMessage = Label.Deployment_Not_Found;
            return new List<ErrorContent>();
        }
        else {
            deploymentJobs = getDeploymentJobs(deployId);
            for (Deployment_Job__c deployJobs: deploymentJobs) {
                List<String> parentIds = new List<String>();
                parentIds.add(deployId);
                List<Attachment> atts = getAttachment(parentIds, deployJobs.Id+'.json');

                if(atts.size()>0){
                    if(atts[0].BodyLength <= MAX_BODY_LENGTH){
                        try{
                            List<Object> results = (List<Object>)JSON.deserializeUntyped(atts[0].Body.toString());
                            for(Object o : results){
                                Map<String, Object> err = (Map<String, Object>)o;
                                ErrorContent ed = new ErrorContent();
                                try{ ed.l = (String)err.get('l'); }catch(Exception ex){ ed.l=''; }
                                try{ ed.m = (String)err.get('m'); }catch(Exception ex){ ed.m=''; }
                                try{ ed.t = (String)err.get('t'); }catch(Exception ex){ ed.t=''; }
                                errorDetails.add(ed);
                            }
                        }
                        catch(Exception e){
                            statusMessage = constant.ERROR_PARSING_JSON+e.getMessage();
                            return new List<ErrorContent>();
                        }
                    }
                    else{
                        statusMessage = Label.MAX_FILE_SIZE_EXCEEDED;
                        return new List<ErrorContent>();
                    }
                }
        	}

            if (errorDetails.isEmpty()) {
                statusMessage = Label.NO_ERROR_ATTACHMENT_FOUND;
                return new List<ErrorContent>();
            }

            statusMessage = '';
            return errorDetails;
    	}
    }

    private static List<Deployment_Job__c> getDeploymentJobs(String dId){
        if(null != deploymentJobs){
            return deploymentJobs;
        }
        if(Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            deploymentJobs = [SELECT Id, Step__c, Step__r.Deployment__r.Name FROM Deployment_Job__c WHERE Step__r.Deployment__c = :dId WITH USER_MODE];
        }
        return deploymentJobs;
    }

    private static List<Attachment> getAttachment(List<String> parentId, String name){
        return [SELECT Id, ParentId, Body, BodyLength, Name, IsDeleted FROM Attachment WHERE ParentId IN :parentId AND Name LIKE :name AND IsDeleted=FALSE WITH USER_MODE];
    }

    public class ErrorContent {
        public String l {get;set;}
        public String m {get;set;}
        public String t {get;set;}
    }

    public class StepsWrapper {
        public String t {get;set;}
        public String n {get;set;}
        public String s {get;set;}
        public String o {get;set;}
        public String cn {get;set;}
        public Boolean co {get;set;}
        public String ct {get;set;}
        public String className {get;set;}
    }
}