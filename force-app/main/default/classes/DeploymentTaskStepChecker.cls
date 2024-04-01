public with sharing class DeploymentTaskStepChecker {
    private static final String DISABLED_STAGES = 'disabledStages';
    private static final String DISABLED_ENVIRONMENTS = 'disabledEnvironments';
    private static final String DISABLED_FOR_BACK_PROMOTIONS = 'disableForBackPromotions';

    private List<JobStep__c> deploymentTaskSteps;
    private Id pipelineId;
    private Id destinationId;
    private Boolean backPromotion;
    private Boolean isValidation;

    // CONSTRUCTOR

    public DeploymentTaskStepChecker(List<JobStep__c> deploymentTaskSteps) {
        this.backPromotion = false;
        this.isValidation = false;
        this.deploymentTaskSteps = deploymentTaskSteps;
    }

    // PUBLIC

    public DeploymentTaskStepChecker pipelineId(Id pipelineId) {
        this.pipelineId = pipelineId;
        return this;
    }

    public DeploymentTaskStepChecker destinationId(Id destinationId) {
        this.destinationId = destinationId;
        return this;
    }

    public DeploymentTaskStepChecker backPromotion(Boolean backPromotion) {
        this.backPromotion = backPromotion != null ? backPromotion : false;
        return this;
    }

    public DeploymentTaskStepChecker isValidation(Boolean isValidation) {
        this.isValidation = isValidation != null ? isValidation : false;
        return this;
    }

    @SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
    public List<JobStep__c> run() {
        List<JobStep__c> result = new List<JobStep__c>(this.deploymentTaskSteps);

        Boolean pipelineContext = pipelineId != null && destinationId != null;
        Id stageId = pipelineContext ? new PipelineDescriptor(pipelineId).getStageId(destinationId) : null;

        for (Integer i = (result.size() - 1); i >= 0; i--) {
            JobStep__c task = result[i];
            if (task.UserStory__c == null || task.ConfigJson__c == null) {
                continue;
            }

            StepConfig config = (StepConfig) JSON.deserialize(task.ConfigJson__c, StepConfig.class);

            if (this.isValidation && !getRunOnValidation(config)) {
                result.remove(i);
                continue;
            }

            if (config.parameters == null) {
                continue;
            }

            if (this.backPromotion && getDisabledForBackPromotion(config.parameters)) {
                result.remove(i);
                continue;
            }

            if (!pipelineContext) {
                continue;
            }

            List<Id> disabledStages = getDisabledStagesEnvironments(config.parameters, DISABLED_STAGES);
            List<Id> disabledEnvironments = getDisabledStagesEnvironments(config.parameters, DISABLED_ENVIRONMENTS);
            if (disabledStages.contains(stageId) || disabledEnvironments.contains(destinationId)) {
                result.remove(i);
                continue;
            }
        }
        return result;
    }

    // PRIVATE

    private Boolean getDisabledForBackPromotion(List<CopadoFunctions.FunctionParameter> parameters) {
        Boolean result = false;

        for (CopadoFunctions.FunctionParameter item : parameters) {
            if (item.name == DISABLED_FOR_BACK_PROMOTIONS) {
                result = Boolean.valueOf(item.value);
                break;
            }
        }

        return result;
    }

    private Boolean getRunOnValidation(StepConfig config) {
        Boolean result = false;

        if (config.runOnValidationDeployment != null) {
            result = config.runOnValidationDeployment;
        }

        return result;
    }

    private List<Id> getDisabledStagesEnvironments(List<CopadoFunctions.FunctionParameter> parameters, String name) {
        List<Id> result;

        for (CopadoFunctions.FunctionParameter item : parameters) {
            if (item.name == name) {
                result = (List<String>) JSON.deserialize(item.value, List<String>.class);
                break;
            }
        }

        return result != null ? result : new List<Id>();
    }

    // INNER

    public class StepConfig extends JobEngine.StepConfig {
        public Boolean runOnValidationDeployment;
    }
}