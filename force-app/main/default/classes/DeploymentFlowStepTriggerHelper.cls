@SuppressWarnings(
    'PMD.StdCyclomaticComplexity,PMD.NcssMethodCount,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.FormalParameterNamingConventions,PMD.AvoidDebugStatements,PMD.DebugsShouldUseLoggingLevel,PMD.LocalVariableNamingConventions,PMD.ApexCRUDViolation,PMD.AvoidDeeplyNestedIfStmts'
)
public without sharing class DeploymentFlowStepTriggerHelper {
    public static Integer existingFlows = 0;
    public static Integer existingSteps = 0;
    public static Integer newStepCount = 0;
    public static boolean isFeatureEnabled = false;

    private static LicenseManagerController lmc = new LicenseManagerController();
    private static final String SALESFORCE = 'Salesforce';

    public static void prepareData() {
        isFeatureEnabled = FeatureHelper.isFeatureEnabled('Branch Management');

        Set<Id> idset = new Set<Id>();
        for (SObject so : Trigger.new) {
            if (so.Id != null) {
                idset.add(so.Id);
            }
        }

        existingSteps = [
            SELECT COUNT()
            FROM Deployment_Flow_Step__c
            WHERE
                Deployment_Flow__r.Active__c = TRUE
                AND (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') // MY: Added to exclude scratch orgs from used CBM licenses
                AND Deployment_Flow__r.Main_Branch__c != NULL
                AND Deployment_Flow__r.Git_Repository__c != NULL
                AND Branch__c != NULL
                AND (NOT Id IN :idset)
        ];

        newStepCount = 0;
        for (SObject so : Trigger.new) {
            Deployment_Flow_Step__c dfs = (Deployment_Flow_Step__c) so;
            if (
                dfs.Source_Environment__c != null &&
                (String.isNotBlank(dfs.Source_Environment__r.Type__c) && !dfs.Source_Environment__r.Type__c.startsWithIgnoreCase('Scratch Org'))
            ) {
                // MY: Added to exclude scratch orgs from used CBM licenses
                if (isValidFlowStep(dfs)) {
                    newStepCount++;
                }
            }
        }
        Integer totalCount = existingSteps + newStepCount;
        Integer allowedCount = lmc.cbmBranchesAvailable;
        for (SObject so : Trigger.new) {
            Deployment_Flow_Step__c dfs = (Deployment_Flow_Step__c) so;
            if (isValidFlowStep(dfs)) {
                if (!isFeatureEnabled) {
                    dfs.addError(Label.BRANCH_MGMT_NOT_ENABLED);
                } else if (totalCount > allowedCount) {
                    dfs.addError(Label.BRANCH_MGMT_LICENSE_EXCEEDED);
                }
            }
        }
    }
    public static boolean isValidFlowStep(Deployment_Flow_Step__c dfs) {
        return (String.isNotBlank(dfs.branch__c) && dfs.Deployment_Flow__r.Active__c == true);
    }

    public static void firePossibleFlowValidations(List<Deployment_Flow_Step__c> Ldfs) {
        System.Debug('Enter firePossibleFlowValidations');

        Map<Id, Deployment_Flow__c> MdfIds = new Map<Id, Deployment_Flow__c>();

        for (Deployment_Flow_Step__c dfs : Ldfs) {
            Deployment_Flow__c df = new Deployment_Flow__c();
            df.Id = dfs.Deployment_Flow__c;
            MdfIds.put(df.Id, df);
        }

        try {
            update MdfIds.values();
        } catch (Exception e) {
            String mess = e.getMessage();
            String validationException = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
            mess = mess.substring(mess.indexOf(validationException) + validationException.length() + 2, mess.length() - 1);
            System.Debug('Exception mess = ' + mess);
            throw new applicationException(mess);
        }
    }

    public static void validateOnEnvironmentStageChangePartOfAutomationRule() {
        Boolean isDelete = Trigger.isDelete;
        Boolean isUpdate = Trigger.isUpdate;
        List<SObject> pipelineConnections;
        Map<Id, SObject> oldPipelineConnections;

        pipelineConnections = isDelete ? Trigger.old : Trigger.new;
        oldPipelineConnections = isUpdate ? Trigger.oldMap : null;

        Map<Id, List<Deployment_Flow_Step__c>> pipelineConnectionsByEnvironmentIds = new Map<Id, List<Deployment_Flow_Step__c>>();
        Map<Id, List<Deployment_Flow_Step__c>> pipelineConnectionsByStageIds = new Map<Id, List<Deployment_Flow_Step__c>>();
        List<SObject> platformPipelineConnections = new List<SObject>();
        Map<Id, SObject> oldPlatformPipelineConnections = new Map<Id, SObject>();
        Set<Id> stageConnectionIds = new Set<Id>();
        Map<Id, Stage_Connection__c> stageConnectionIdByStageConnection;

        Set<Id> pipelines = new Set<Id>();

        for (SObject so : pipelineConnections) {
            Deployment_Flow_Step__c pipeConnection = (Deployment_Flow_Step__c) so;
            if (String.isNotBlank(pipeConnection.Platform__c) && pipeConnection.Platform__c != SALESFORCE) {
                platformPipelineConnections.add(so);
                if (oldPipelineConnections != null) {
                    sObject oldPipelineConnection = oldPipelineConnections.get(so.Id);
                    oldPlatformPipelineConnections.put(so.Id, oldPipelineConnection);
                    if (String.isNotEmpty(((Deployment_Flow_Step__c) oldPipelineConnection).Stage_Connection__c)) {
                        stageConnectionIds.add(((Deployment_Flow_Step__c) oldPipelineConnection).Stage_Connection__c);
                    }
                }
                if (isDelete) {
                    stageConnectionIds.add(pipeConnection.Stage_Connection__c);
                }
            }
        }

        if (!stageConnectionIds.isEmpty()) {
            stageConnectionIdByStageConnection = new Map<Id, Stage_Connection__c>(
                [SELECT Id, Stage__c FROM Stage_Connection__c WHERE Id IN :stageConnectionIds WITH USER_MODE]
            );
        }

        for (SObject so : platformPipelineConnections) {
            Deployment_Flow_Step__c pipeConnection = (Deployment_Flow_Step__c) so;

            Deployment_Flow_Step__c oldPipeConnection = isUpdate
                ? (Deployment_Flow_Step__c) oldPlatformPipelineConnections.get(pipeConnection.Id)
                : pipeConnection;

            //Destination Environment
            if (
                isFieldChanged(
                    pipeConnection,
                    oldPipeConnection,
                    Schema.SObjectType.Deployment_Flow_Step__c.fields.Destination_Environment__c.getName()
                ) || isDelete
            ) {
                if (!pipelineConnectionsByEnvironmentIds.containsKey(oldPipeConnection.Destination_Environment__c)) {
                    pipelineConnectionsByEnvironmentIds.put(oldPipeConnection.Destination_Environment__c, new List<Deployment_Flow_Step__c>());
                }
                pipelineConnectionsByEnvironmentIds.get(oldPipeConnection.Destination_Environment__c).add(pipeConnection);
            }

            //Source Environment
            if (
                isFieldChanged(
                    pipeConnection,
                    oldPipeConnection,
                    Schema.SObjectType.Deployment_Flow_Step__c.fields.Source_Environment__c.getName()
                ) || isDelete
            ) {
                if (!pipelineConnectionsByEnvironmentIds.containsKey(oldPipeConnection.Source_Environment__c)) {
                    pipelineConnectionsByEnvironmentIds.put(oldPipeConnection.Source_Environment__c, new List<Deployment_Flow_Step__c>());
                }
                pipelineConnectionsByEnvironmentIds.get(oldPipeConnection.Source_Environment__c).add(pipeConnection);
            }

            //Stage Connection
            if (
                (isFieldChanged(pipeConnection, oldPipeConnection, Schema.SObjectType.Deployment_Flow_Step__c.fields.Stage_Connection__c.getName()) ||
                isDelete) && String.isNotBlank(oldPipeConnection.Stage_Connection__c)
            ) {
                Id stageId = stageConnectionIdByStageConnection != null
                    ? stageConnectionIdByStageConnection.get(oldPipeConnection.Stage_Connection__c)?.Stage__c
                    : null;

                if (!pipelineConnectionsByStageIds.containsKey(stageId)) {
                    pipelineConnectionsByStageIds.put(stageId, new List<Deployment_Flow_Step__c>());
                }
                pipelineConnectionsByStageIds.get(stageId).add(pipeConnection);
            }

            //Pipeline
            if (
                isDelete ||
                (oldPlatformPipelineConnections.containsKey(pipeConnection.Id) &&
                isSourceOrDestinationOrStageChanged(pipeConnection, oldPlatformPipelineConnections.get(pipeConnection.Id)))
            ) {
                pipelines.add(pipeConnection.Deployment_Flow__c);
            }
        }

        if (!pipelines.isEmpty()) {
            for (Automation_Rule__c automationRule : [
                SELECT Id, Stage__c, Environment__c, Pipeline__c, Excluded_Environments__c
                FROM Automation_Rule__c
                WHERE Active__c = TRUE AND Pipeline__c IN :pipelines
                WITH USER_MODE
            ]) {
                pipelineConnectionPartOfAutomationRule(automationRule, pipelineConnectionsByEnvironmentIds, pipelineConnectionsByStageIds);
            }
        }
    }

    //PRIVATE
    private static Boolean isFieldChanged(SObject so, SObject oldSo, String fieldName) {
        return so.get(fieldName) != oldSo.get(fieldName);
    }

    private static Boolean isSourceOrDestinationOrStageChanged(Deployment_Flow_Step__c pipeConnection, SObject oldPlatformPipelineConnection) {
        Boolean isChangedDestinationEnvironment = isFieldChanged(
            pipeConnection,
            oldPlatformPipelineConnection,
            Schema.SObjectType.Deployment_Flow_Step__c.fields.Destination_Environment__c.getName()
        );

        Boolean isChangedSourceEnvironment = isFieldChanged(
            pipeConnection,
            oldPlatformPipelineConnection,
            Schema.SObjectType.Deployment_Flow_Step__c.fields.Source_Environment__c.getName()
        );

        Boolean isChangedStageConnection = isFieldChanged(
            pipeConnection,
            oldPlatformPipelineConnection,
            Schema.SObjectType.Deployment_Flow_Step__c.fields.Stage_Connection__c.getName()
        );

        return isChangedDestinationEnvironment || isChangedSourceEnvironment || isChangedStageConnection;
    }

    private static void pipelineConnectionPartOfAutomationRule(
        Automation_Rule__c automationRule,
        Map<Id, List<Deployment_Flow_Step__c>> pipelineConnectionsByEnvironmentIds,
        Map<Id, List<Deployment_Flow_Step__c>> pipelineConnectionsByStageIds
    ) {
        if (String.isNotBlank(automationRule.Environment__c) && !pipelineConnectionsByEnvironmentIds.isEmpty()) {
            Set<String> pipeConnectionEnvironments = isPartOfAutomation(pipelineConnectionsByEnvironmentIds.keySet(), automationRule.Environment__c);

            for (String environmentId : pipeConnectionEnvironments) {
                for (Deployment_Flow_Step__c pipelineConnection : pipelineConnectionsByEnvironmentIds.get(environmentId)) {
                    pipelineConnection.addError(Label.PipelineConnectionEnvironmentUpdateValidationError);
                }
            }
        }
        if (String.isNotBlank(automationRule.Stage__c) && !pipelineConnectionsByStageIds.isEmpty()) {
            Set<String> stageConnectionStages = isPartOfAutomation(pipelineConnectionsByStageIds.keySet(), automationRule.Stage__c);

            for (String stageId : stageConnectionStages) {
                for (Deployment_Flow_Step__c pipelineConnection : pipelineConnectionsByStageIds.get(stageId)) {
                    pipelineConnection.addError(Label.PipelineConnectionEnvironmentUpdateValidationError);
                }
            }
        }
        if (String.isNotBlank(automationRule.Excluded_Environments__c) && !pipelineConnectionsByEnvironmentIds.isEmpty()) {
            Set<String> pipeConnectionEnvironments = isPartOfAutomation(
                pipelineConnectionsByEnvironmentIds.keySet(),
                automationRule.Excluded_Environments__c
            );

            for (String environmentId : pipeConnectionEnvironments) {
                for (Deployment_Flow_Step__c pipelineConnection : pipelineConnectionsByEnvironmentIds.get(environmentId)) {
                    pipelineConnection.addError(Label.PipelineConnectionEnvironmentUpdateValidationError);
                }
            }
        }
    }

    private static Set<String> isPartOfAutomation(Set<Id> pipelineConnectionEnvironmentIds, String automationEnvironments) {
        Set<String> pipelineConnectionEnvironments = (Set<String>) JSON.deserialize(
            JSON.serialize(pipelineConnectionEnvironmentIds),
            Set<String>.class
        );
        List<String> automationRuleEnvironments = automationEnvironments.split(',');
        pipelineConnectionEnvironments.retainAll(automationRuleEnvironments);
        return pipelineConnectionEnvironments;
    }
}