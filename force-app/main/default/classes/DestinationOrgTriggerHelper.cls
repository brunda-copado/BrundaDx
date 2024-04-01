public with sharing class DestinationOrgTriggerHelper {
    private Map<Id, Org__c> credentialByIds = new Map<Id, Org__c>();
    private List<Destination_Org__c> destinationOrgRecords;
    private List<Deployment__c> deployments = new List<Deployment__c>();
    private Set<String> credentialIds = new Set<String>();

    // CONSTRUCTOR

    public DestinationOrgTriggerHelper(List<Destination_Org__c> destinationOrgs, Boolean isAfter) {
        destinationOrgRecords = destinationOrgs;
        if (isAfter) {
            getCredentials();
            getDeployments();
        }
    }

    // PUBLIC

    public void afterInsert() {
        addHistory('created');
        DeployJobHelper.upsertDeployJobs(deployments);
    }

    public void afterDelete() {
        addHistory('deleted');
    }

    // PRIVATE

    private void getCredentials() {
        for (Destination_Org__c destinationOrg : destinationOrgRecords) {
            if (destinationOrg.To_Org__c != null) {
                credentialIds.add(destinationOrg.To_Org__c);
            }
        }
        credentialByIds = new OrgsSelector().credentialsById(credentialIds);
    }

    private void getDeployments() {
        for (Destination_Org__c destinationOrg : destinationOrgRecords) {
            deployments.add(new Deployment__c(Id = destinationOrg.Deployment__c));
        }
    }

    private void addHistory(String event) {
        Boolean objectAccess = Schema.sObjectType.Deployment_History__c.isUpdateable();
        Boolean oldValueFieldAccess = Schema.sObjectType.Deployment_History__c.fields.Old_Value__c.isUpdateable();
        Boolean newValueFieldAccess = Schema.sObjectType.Deployment_History__c.fields.New_Value__c.isUpdateable();
        List<Deployment_History__c> deploymentHistories = new List<Deployment_History__c>();
        for (Destination_Org__c destinationOrg : destinationOrgRecords) {
            Deployment_History__c deploymentHistory = new Deployment_History__c(
                Deployment_Id__c = destinationOrg.Deployment__c,
                Deployment__c = destinationOrg.Deployment__c,
                Date__c = System.now(),
                Event__c = event,
                Object__c = 'Destination Org',
                User__c = UserInfo.getUserId(),
                Field__c = 'Destination Org'
            );
            if (event == 'Created' && objectAccess && newValueFieldAccess) {
                deploymentHistory.New_Value__c = destinationOrg.To_Org__c;
            }
            if (event == 'Deleted' && objectAccess && oldValueFieldAccess) {
                deploymentHistory.Old_Value__c = destinationOrg.To_Org__c;
            }

            String orgName = '';
            String environmentOrgId = '';

            if (String.isNotBlank(deploymentHistory.New_Value__c) && credentialByIds.containsKey(deploymentHistory.New_Value__c)) {
                orgName = credentialByIds.get(deploymentHistory.New_Value__c).Name;
                environmentOrgId = credentialByIds.get(deploymentHistory.New_Value__c).Environment__r.Org_ID__c;

                Boolean isOtherPlatform =
                    credentialByIds.get(deploymentHistory.New_Value__c).Platform__c != null &&
                    credentialByIds.get(deploymentHistory.New_Value__c).Platform__c != 'Salesforce';

                deploymentHistory.New_Value__c = orgName;
                if (!isOtherPlatform) {
                    deploymentHistory.New_Value__c += ' (' + environmentOrgId + ')';
                }
            }
            if (String.isNotBlank(deploymentHistory.Old_Value__c) && credentialByIds.containsKey(deploymentHistory.Old_Value__c)) {
                orgName = credentialByIds.get(deploymentHistory.Old_Value__c).Name;
                environmentOrgId = credentialByIds.get(deploymentHistory.Old_Value__c).Environment__r.Org_ID__c;

                Boolean isOtherPlatform =
                    credentialByIds.get(deploymentHistory.Old_Value__c).Platform__c != null &&
                    credentialByIds.get(deploymentHistory.Old_Value__c).Platform__c != 'Salesforce';

                deploymentHistory.Old_Value__c = orgName;
                if (!isOtherPlatform) {
                    deploymentHistory.Old_Value__c += ' (' + environmentOrgId + ')';
                }
            }
            deploymentHistories.add(deploymentHistory);
        }

        if(Schema.sObjectType.Deployment_History__c.isCreateable() && Schema.sObjectType.Deployment_History__c.isAccessible()) {
            insert deploymentHistories;
        }
    }
}