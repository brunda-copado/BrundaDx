public class DeploymentFlowTriggerHelper {
    // TODO: remove this comment
    private List<Deployment_Flow__c> pipelines;
    private Map<Id, List<Deployment_Flow_Step__c>> stepsByPipelineId = new Map<Id, List<Deployment_Flow_Step__c>>();

                         	
    // CONSTRUCTOR

    public DeploymentFlowTriggerHelper(List<Deployment_Flow__c> pipelines) {
        this.pipelines = pipelines;
    }             
    
    // PUBLIC

    public void execute() {
        stepsByPipelineId = new DeploymentFlowStepsSelector().byPipeline(pipelines);

        for(Deployment_Flow__c pipeline : pipelines) {
            if(String.isNotBlank(pipeline.Order_By__c)) {
                PromotionTriggerHelper.checkValidity(pipeline);
            }

            if(pipeline.Calculate_Based_on__c != 'Branch') {
                pipeline.Hide_tabs__c = 'Commits Ahead;Commits Behind;Deployment Error;File Differences;Auto Resolved Conflicts;Merged Files';
            }

            if(!pipeline.Disable_Validations__c && isValid(pipeline) && stepsByPipelineId.containsKey(pipeline.Id)) {
                validateAgainstStep(pipeline, stepsByPipelineId.get(pipeline.Id));
            }
        }
    }

    private void validateAgainstStep(Deployment_Flow__c pipeline, List<Deployment_Flow_Step__c> steps) {
        Set<String> branches = new Set<String>();
        Set<String> environments = new Set<String>();

        for (Deployment_Flow_Step__c step: steps) {
            if (branches.contains(step.Branch__c) || step.Branch__c == pipeline.Main_branch__c) {
                pipeline.addError(Label.REPEATED_BRANCH_NAME);
                return;
            }
            else {
                branches.add(step.Branch__c);
            }

            if (pipeline.Equal_Branch_Environment_Name__c) {
                if (!step.Branch__c.equals(step.Source_Environment__r.Name)) {
                    pipeline.addError(Label.BRANCH_AND_SOURCE_ENVIRONMENT_EQUALS);
                }
            }

            if (step.Source_Environment__c != null && environments.contains(step.Source_Environment__c)) {
                pipeline.addError(Label.REPEATED_SOURCE_ENVIRONMENT);
                return;
            }
            else {
                environments.add(step.Source_Environment__c);
            }
        }
    }

    private boolean isValid(Deployment_Flow__c pipeline) {
        return (pipeline.Active__c == true && pipeline.Git_Repository__c != null && String.isNotBlank(pipeline.Main_branch__c));
    }
}