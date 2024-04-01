@SuppressWarnings('PMD')
public with sharing class DeployJobHelper {

    public static void upsertDeployJobs(List<Deployment__c> deployments) {
        Map<Id, Deployment__c> deploymentByIds = new DeploymentsSelector().deploymentByIds(deployments);
        List<Deployment_Job__c> deploymentJobs = new List<Deployment_Job__c>();
        List<Step__c> steps = new List<Step__c>();
        List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();
        for (Deployment__c deployment : deploymentByIds.values()) {
            steps.addAll(deployment.Steps__r);
            destinationOrgs.addAll(deployment.Destination_Orgs__r);
        }

        for (Step__c step : steps) {
            for (Destination_Org__c destinationCredential : destinationOrgs) {
                if (step.Deployment__c == destinationCredential.Deployment__c) {
                    deploymentJobs.add(
                        new Deployment_Job__c(
                            Step__c = step.Id,
                            Destination_Org__c = destinationCredential.Id,
                            External_Id__c = step.Id + '_' + destinationCredential.Id
                        )
                    );
                }
            }
        }
        try {
            Utilities.Secure_DML(
                deploymentJobs,
                Utilities.DML_Action.UPS,
                schema.Sobjecttype.Deployment_Job__c,
                schema.sObjectType.Deployment_Job__c.fields.external_id__c
            );
        } catch (DmlException e) {
            //If we are in visualforce context
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '' + e));
            }
        }
    }

    public static boolean getContinueOnErrorStatus(Id deploymentJobId) {
        Boolean resultFlag = false;
        String body = [SELECT Id, Step__r.dataJson__c FROM Deployment_Job__c WHERE Id = :deploymentJobId WITH USER_MODE][0]?.Step__r.dataJson__c;
        if(body != null && body.contains('dataTemplateId')) {
            String dataTemplateId = (DataTemplateDetail.parseJSON(body)).dataTemplateId;
            resultFlag = [SELECT Id, Continue_on_Error__c FROM Data_Template__c WHERE Id = :dataTemplateId AND Continue_on_Error__c = 'Stop deployment on first issue' WITH USER_MODE].isEmpty();
            return resultFlag;
        }
        else {
            return !resultFlag;
        }
       
    }

    public static Map<Id, String> updateStatus(
        Map<Id, List<Deployment_Job__c>> deploymentJobsByDeploymentIds,
        List<Deployment_Job__c> deploymentJobs
    ) {
        DeploymentConstant constant = new DeploymentConstant();
        Map<String, String> destinationOrgStatusByIds = getDestinationOrgStatus(deploymentJobs);
        Map<Id, Destination_Org__c> destinationOrgsByIds = new Map<Id, Destination_Org__c>();
        Map<Id, Step__c> stepsByIds = new Map<Id, Step__c>();
        Map<Id, Deployment__c> deploymentsByIds = new Map<Id, Deployment__c>();
        Map<Id, String> deploymentStatusesByIds = new Map<Id, String>();
        Map<Id, List<Deployment_Job__c>> deploymentJobsBySteps = new Map<Id, List<Deployment_Job__c>>();
        Set<Id> completedStepIds = new Set<Id>();
        Set<Id> failedStepIds = new Set<Id>();

        for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
            if(deploymentJobsBySteps.containsKey(deploymentJobRecord.Step__c)) {
                deploymentJobsBySteps.get(deploymentJobRecord.Step__c).add(deploymentJobRecord);
            } else {
                deploymentJobsBySteps.put(deploymentJobRecord.Step__c, new List<Deployment_Job__c> { deploymentJobRecord });
            }
        }

        Map<Id, Step__c> stepsById = new Map<Id, Step__c>([SELECT Id, Status__c FROM Step__c WHERE Id IN : deploymentJobsBySteps.keyset() WITH USER_MODE]);

        for(Id stepId : deploymentJobsBySteps.keySet()) {
            Integer stepJobCount = deploymentJobsBySteps.get(stepId).size();
            Integer successJobCount = 0;
            Integer failedJobCount = 0;

            for(Deployment_Job__c deploymentJobRecord : deploymentJobsBySteps.get(stepId)) {
                if(deploymentJobRecord.Status__c == constant.SUCCESS) {
                    successJobCount++;
                }
                if(deploymentJobRecord.Status__c == constant.FAILED) {
                    failedJobCount++;
                }
            }

            if(stepJobCount == successJobCount) {
                completedStepIds.add(stepId);
            }

            Integer totalJobCount = failedJobCount + successJobCount;
            if(failedJobCount == stepJobCount || (stepJobCount == totalJobCount && totalJobCount != successJobCount)) {
                failedStepIds.add(stepId);
            }
        }

        for (Id deploymentId : deploymentJobsByDeploymentIds.keySet()) {
            String attachmentJSON = [SELECT Name, body FROM Attachment WHERE ParentId = :deploymentId AND (Name LIKE '__________________.json') WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 1]?.body.toString();
            for (Deployment_Job__c deploymentJob : deploymentJobsByDeploymentIds.get(deploymentId)) {
                //define status of the destination org
                String key = deploymentJob.Id + '_' + deploymentJob.Destination_org__c;
                Destination_Org__c destinationOrg = new Destination_Org__c(
                    Id = deploymentJob.Destination_org__c,
                    Status__c = destinationOrgStatusByIds.get(key)
                );
                destinationOrgsByIds.put(destinationOrg.Id, destinationOrg);

                //define status of the step
                Step__c step = new Step__c(Id = deploymentJob.Step__c);
                String newStepStatus = '';
                for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
                    if (deploymentJobRecord.Step__c == deploymentJob.Step__c) {
                        if (deploymentJobRecord.Status__c == constant.PENDING || 
                            deploymentJobRecord.Status__c.toLowerCase() == constant.IN_PROGRESS.toLowerCase() || 
                            (!failedStepIds.contains(deploymentJob.Step__c) && !completedStepIds.contains(deploymentJob.Step__c) && (deploymentJobRecord.Status__c == constant.SUCCESS || deploymentJobRecord.Status__c == constant.FAILED))) {
                            Boolean inProgressStatus = (deploymentJobRecord.Status__c == constant.SUCCESS && !completedStepIds.contains(deploymentJob.Step__c)) || (deploymentJobRecord.Status__c == constant.FAILED && !failedStepIds.contains(deploymentJob.Step__c));
                            newStepStatus = inProgressStatus ? constant.IN_PROGRESS : destinationOrgStatusByIds.get(key);
                            break;
                        } else if (deploymentJobRecord.Status__c == constant.SUCCESS && completedStepIds.contains(deploymentJob.Step__c)) {
                            newStepStatus = constant.COMPLETED_SUCCESSFULLY;
                        } else if (deploymentJobRecord.Status__c == constant.FAILED && failedStepIds.contains(deploymentJob.Step__c)) {
                            newStepStatus = constant.COMPLETED_WITH_ERRORS;
                        } else if (deploymentJobRecord.Status__c == constant.CANCELLED) {
                            newStepStatus = constant.CANCELLED;
                            break;
                        }
                    } else {
                        if(deploymentJobRecord.Status__c == constant.SUCCESS && stepsById.containsKey(deploymentJobRecord.Step__c) && stepsById.get(deploymentJobRecord.Step__c).Status__c == constant.IN_PROGRESS){
                            Step__c parkedStep = new Step__c(Id = deploymentJobRecord.Step__c, Status__c = constant.COMPLETED_SUCCESSFULLY);
                            stepsByIds.put(parkedStep.Id, parkedStep);
                        }
                    }
                }
                if (String.isNotBlank(newStepStatus)) {
                    step.Status__c = newStepStatus;
                }
                stepsByIds.put(step.Id, step);

                //define status of the deployment
                Deployment__c deployment = new Deployment__c(Id = deploymentId);
                String newDeploymentStatus = '';
                Boolean isAllcompleted = true;
                Boolean isCancelled = false;
                for (String keyValue : destinationOrgStatusByIds.keySet()) {
                    String destinationOrgStatus = destinationOrgStatusByIds.get(keyValue);
                    if(keyValue.contains(deploymentJob.Id)) {
                        Boolean allStepsCompletedSuccessfully = deploymentJobsBySteps.keySet().size() == completedStepIds.size();
                        Boolean continueOnErrorDisabled = (!Test.isRunningTest()) ? getContinueOnErrorStatus(deploymentJob.Id) : true;
                        if (
                            destinationOrgStatus.toLowerCase() == constant.IN_PROGRESS.toLowerCase() ||
                            destinationOrgStatus == constant.PENDING ||
                            destinationOrgStatus == constant.NOT_STARTED || 
                            (!failedStepIds.contains(deploymentJob.Step__c) && !completedStepIds.contains(deploymentJob.Step__c) && (destinationOrgStatus == constant.COMPLETED_SUCCESSFULLY || destinationOrgStatus == constant.COMPLETED_WITH_ERRORS)) ||
                            completedStepIds.contains(deploymentJob.Step__c) && !allStepsCompletedSuccessfully && destinationOrgStatus == constant.COMPLETED_SUCCESSFULLY
                        ) {
                            newDeploymentStatus = constant.IN_PROGRESS;
                            isAllcompleted = false;
                            break;
                        } else if (destinationOrgStatus == constant.COMPLETED_SUCCESSFULLY && completedStepIds.contains(deploymentJob.Step__c) && allStepsCompletedSuccessfully && 
                            (continueOnErrorDisabled || !continueOnErrorDisabled && String.isBlank(hasFailedRecords(attachmentJSON)))) {
                            newDeploymentStatus = constant.COMPLETED_SUCCESSFULLY;
                        } else if ((destinationOrgStatus == constant.COMPLETED_WITH_ERRORS && newDeploymentStatus != constant.CANCELLED && failedStepIds.contains(deploymentJob.Step__c)) ||
                            (destinationOrgStatus == constant.COMPLETED_SUCCESSFULLY && newDeploymentStatus != constant.CANCELLED && (failedStepIds.contains(deploymentJob.Step__c) || (!String.isBlank(hasFailedRecords(attachmentJSON)) && !continueOnErrorDisabled)))
                        ) {
                            newDeploymentStatus = constant.COMPLETED_WITH_ERRORS;
                            isAllcompleted = true;
                            break;
                        } else if (destinationOrgStatus == constant.CANCELLED) {
                            newDeploymentStatus = constant.CANCELLED;
                            isCancelled = true;
                        }
                    }
                }
                if (isAllcompleted) {
                    deployment.Status__c = newDeploymentStatus;
                    deploymentsByIds.put(deployment.Id, deployment);
                }

                deploymentStatusesByIds.put(deploymentId, newDeploymentStatus);
            }
        }

        if(!destinationOrgsByIds.isEmpty()) {
            Utilities.Secure_DML(destinationOrgsByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Destination_Org__c);
        }
        if(!stepsByIds.isEmpty()) {
            Utilities.Secure_DML(stepsByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);
        }
        if(!deploymentsByIds.isEmpty()) {
            Utilities.Secure_DML(deploymentsByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
        }

        updateResultAndDeploymentJobStatusFieldsRelatedToDeployment(deploymentsByIds);
        updateDeploymentJobToInvokeParentDeployments(deploymentsByIds);
        return deploymentStatusesByIds;
    }

    public static String hasFailedRecords(String attBodyAsJSON) {
        DeploymentConstant constant = new DeploymentConstant();
        if(attBodyAsJSON == null) {
            return '';
        }
        else {
            for(Results resultObj : deploymentJobJSON.parse(attBodyAsJSON).results) {
                if(resultObj.m.failedRecords > 0) {
                    return constant.COMPLETED_WITH_ERRORS;
                }
            }
            return '';
        }
    }

    private static void updateResultAndDeploymentJobStatusFieldsRelatedToDeployment(Map<Id, Deployment__c> deploymentsByIds) {
        DeploymentConstant constant = new DeploymentConstant();
        if (!deploymentsByIds.isEmpty()) {
            List<Result__c> results = [
                SELECT Id, Deployment__c, End_Time__c, Status__c, (SELECT Id, Step__c, Status__c, Last_Result__c FROM Deployment_Jobs__r)
                FROM Result__c
                WHERE Deployment__c IN :deploymentsByIds.keySet() AND Function__c = NULL
                WITH SECURITY_ENFORCED
            ];
           
            List<Deployment_Job__c> deploymentJobs = new List<Deployment_Job__c>();
            for (Result__c resultRecord : results) {
                String deploymentStatus = deploymentsByIds.get(resultRecord.Deployment__c).Status__c;
                String resultStatus = deploymentStatus == constant.COMPLETED_SUCCESSFULLY
                    ? constant.SUCCESS
                    : deploymentStatus == constant.COMPLETED_WITH_ERRORS ? constant.FAILED : constant.IN_PROGRESS.toLowerCase();
                resultRecord.Status__c = resultStatus;
                resultRecord.End_Time__c = System.now();
                for (Deployment_Job__c deploymentJobRecord : resultRecord.Deployment_Jobs__r) {
                    deploymentJobRecord.Status__c = resultStatus;
                    deploymentJobs.add(deploymentJobRecord);
                }
            }

            Utilities.Secure_DML(results, Utilities.DML_Action.UPD, schema.Sobjecttype.Result__c);
            Utilities.Secure_DML(deploymentJobs, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Job__c);
        }
    }

    private static void updateDeploymentJobToInvokeParentDeployments(Map<Id, Deployment__c> deploymentsByIds) {
        DeploymentConstant constant = new DeploymentConstant();
        if (!deploymentsByIds.isEmpty()) {
            Set<Id> parentDeploymentIds = new Set<Id>();
            for (Deployment__c deployment : [SELECT Id, Parent_Deployment__c FROM Deployment__c
                                             WHERE Id IN :deploymentsByIds.keySet() 
                                             AND Status__c = :constant.COMPLETED_SUCCESSFULLY  WITH USER_MODE]) {
                parentDeploymentIds.add(deployment.Parent_Deployment__c);
            }

            List<Deployment_Job__c> deploymentJobs = [SELECT Id, Status__c FROM Deployment_Job__c
                                                      WHERE Step__r.Deployment__c IN :parentDeploymentIds 
                                                      AND Step__r.Order__c = 1 WITH USER_MODE];
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                deploymentJob.Status__c = constant.IN_PROGRESS;
            }
            Utilities.Secure_DML(deploymentJobs, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Job__c);
        }
    }

    public static Map<String, String> getDestinationOrgStatus(List<Deployment_Job__c> deploymentJobs) {
        DeploymentConstant constant = new DeploymentConstant();
        Map<String, String> destinationOrgStatusByIds = new Map<String, String>();
        for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
            String newDestinationOrgStatus = '';
            if (deploymentJobRecord.Status__c == constant.PENDING && deploymentJobRecord.Destination_Org__r.Status__c == constant.NOT_STARTED) {
                newDestinationOrgStatus = constant.NOT_STARTED;
            } else if (deploymentJobRecord.Status__c == constant.PENDING || deploymentJobRecord.Status__c.toLowerCase() == constant.IN_PROGRESS.toLowerCase()) {
                newDestinationOrgStatus = constant.IN_PROGRESS;
            } else if (deploymentJobRecord.Status__c == constant.SUCCESS) {
                newDestinationOrgStatus = constant.COMPLETED_SUCCESSFULLY;
            } else if (deploymentJobRecord.Status__c == constant.FAILED) {
                newDestinationOrgStatus = constant.COMPLETED_WITH_ERRORS;
            } else if (deploymentJobRecord.Status__c == constant.CANCELLED) {
                newDestinationOrgStatus = constant.CANCELLED;
            }
            String key = deploymentJobRecord.Id + '_' + deploymentJobRecord.Destination_Org__c;
            destinationOrgStatusByIds.put(key, newDestinationOrgStatus);
        }
        return destinationOrgStatusByIds;
    }

    public static Boolean hasFailedCount(String deploymentID, String templateType) {
        return ('Data Template' == templateType) ? String.isBlank(hasFailedRecords([SELECT Name, body FROM Attachment WHERE ParentId = :deploymentID AND (Name LIKE '__________________.json') WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 1]?.body.toString())) : false;
    }

    public static Boolean getContinueOnError(String dataTemplateId) {
        return [SELECT Id, Continue_on_Error__c FROM Data_Template__c WHERE Id = :dataTemplateId AND Continue_on_Error__c = 'Stop deployment on first issue' WITH USER_MODE].isEmpty();
    }

    public static String getDataTemplateId(String currJobID) {
        return (DataTemplateDetail.parseJSON([SELECT Id, Step__r.dataJson__c FROM Deployment_Job__c WHERE Id = :currJobID WITH USER_MODE][0]?.Step__r.dataJson__c).dataTemplateId);
    }

    public class ManualTaskStepAttachmentDetails {
        public String m { get; set; }
        public String l { get; set; }
        public String t { get; set; }
    }

    public class deploymentJobJSON {
    
        public String sourceDomain;
        public String targetDomain;
        public List<Results> results;
    }
    public class Results {
        public String l;
        public m m;
        public String t;
    }
    public class m {
        public String templateId;
        public String templateName;
        public String objectName;
        public Integer deployedRecords;
        public Integer failedRecords;
        public Integer generatedIds;
    }
    public static deploymentJobJSON parse(String json) {
        return isValidJSON(json)? (deploymentJobJSON) System.JSON.deserialize(json, deploymentJobJSON.class) : new deploymentJobJSON();
    }

    public class DataTemplateDetail {
        public String dataTemplateId;
        public String dataTemplateName;
    }
    public static DataTemplateDetail parseJSON(String json) {
        return isValidJSON(json)? (DataTemplateDetail) System.JSON.deserialize(json, DataTemplateDetail.class) : new DataTemplateDetail();
    }

    public static boolean isValidJSON(String message) {
        Boolean isValidJSON = false;
        if(message == null) {
            return isValidJSON;
        }
        try{
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(message);
            isValidJSON = true;
        }catch(JSONException e){
            System.debug(e.getMessage());
        }
        return isValidJSON;
    }
}