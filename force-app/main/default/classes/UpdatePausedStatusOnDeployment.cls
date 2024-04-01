public with sharing class UpdatePausedStatusOnDeployment {
    private List<Step__c> steps;
    private Map<Id, Step__c> oldSteps;

    // CONSTRUCTOR

    public UpdatePausedStatusOnDeployment(List<Step__c> steps, Map<Id, Step__c> oldSteps) {
        this.steps = steps;
        this.oldSteps = oldSteps;
    }

    // PUBLIC

    public void execute() {
        Set<Deployment__c> uniqueDeployments = new Set<Deployment__c>();
        Map<String, Step__c> nextStepByCurrentStepId = nextStepByCurrentStepId();


        for (Step__c newStep : steps) {
            Step__c oldStep = oldSteps.get(newStep.Id);
            if (newStep.Status__c == 'Completed Successfully' && newStep.Status__c != oldStep.Status__c) {
                //default value
                Boolean pauseFlag = false;

                if (nextStepByCurrentStepId.containsKey(String.valueOf(newStep.Deployment__c) + newStep.Id)) {
                    Step__c nextStep = nextStepByCurrentStepId.get(String.valueOf(newStep.Deployment__c) + newStep.Id);
                    if (nextStep.Type__c == 'Manual Task' && nextStep.Status__c == 'Not started') {
                        pauseFlag = true;
                        uniqueDeployments.add(new Deployment__c(Id = nextStep.Deployment__c, Paused__c = true));
                    }
                }

                if (newStep.Type__c == 'Manual Task' && !pauseFlag) {
                    uniqueDeployments.add(new Deployment__c(Id = newStep.Deployment__c, Paused__c = false));
                }
            }
        }

        if(!uniqueDeployments.isEmpty()) {
            List<Deployment__c> deployments = new List<Deployment__c>(uniqueDeployments);
            Utilities.Secure_DML(deployments, Utilities.DML_Action.UPD, SObjectType.Deployment__c);
        }
    }

    // PRIVATE

    private Map<String, Step__c> nextStepByCurrentStepId() {
        Map<String, Step__c> result = new Map<String, Step__c>();

        for (Deployment__c deployment : new DeploymentsSelector().byIdWithSteps(deploymentIds())) {
            List<Step__c> deploymentSteps = deployment.Steps__r;

            for (Integer i = 0; i < deploymentSteps.size() - 1; i++) {
                Step__c currentStep = deploymentSteps[i];
                result.put('' + currentStep.Deployment__c + currentStep.Id, deploymentSteps[i + 1]);
            }
        }

        return result;
    }

    private Set<Id> deploymentIds() {
        Set<Id> result = new Set<Id>();
        for (Step__c step : steps) {
            result.add(step.Deployment__c);
        }

        return result;
    }
}