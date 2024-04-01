@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public with sharing class ContinuousDeliverySetupController {
    @TestVisible
    private static final String RULE_NAME_PROMOTION = Label.Forward_Promotions + ' - ' + AutomationRuleConstants.CONTINUOUS_DELIVERY;
    @TestVisible
    private static final String RULE_NAME_BACK_PROMOTION = Label.Back_Promotions + ' - ' + AutomationRuleConstants.CONTINUOUS_DELIVERY;

    private static final Map<String, String> CONNECTOR_BY_NAME = new Map<String, String>{
        RULE_NAME_PROMOTION => ACPromotionDeploymentToPromotion.class.getName(),
        RULE_NAME_BACK_PROMOTION => ACPromotionDeploymentToBackPromotion.class.getName()
    };

    private static Map<Id, PipelineDescriptor> descriptorByPipelineId = new Map<Id, PipelineDescriptor>();

    // PUBLIC

    @AuraEnabled
    public static void checkPermissions(Id pipelineId) {
        List<Stage_Connection__c> stages = getStageConnections(pipelineId);

        if (stages.isEmpty() || stages.size() == 1) {
            throw new ApplicationException(Label.CD_Setup_No_Stages);
        }

        List<String> messages = new List<String>();
        messages.addAll(isCreateable(Schema.SObjectType.Automation_Rule__c));
        messages.addAll(isReadable(Schema.SObjectType.Stage__c));
        messages.addAll(isReadable(Schema.SObjectType.Environment__c));
        messages.addAll(isReadable(Schema.SObjectType.Deployment_Flow__c));
        messages.addAll(isReadable(Schema.SObjectType.Deployment_Flow_Step__c));
        messages.addAll(isUpdateable(Schema.sObjectType.Deployment_Flow__c.fields.Continuous_Delivery_Enabled__c));
        messages.addAll(isUpdateable(Schema.sObjectType.Deployment_Flow__c.fields.Continuous_Delivery_Configuration_Json__c));

        if (!messages.isEmpty()) {
            throw new ApplicationException(
                String.format(Label.ContinuousDeliveryWizardPermissionsError, new List<String>{ String.join(messages, '') })
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Stage_Connection__c> getStageConnections(Id pipelineId) {
        return [
            SELECT
                Id,
                Next_Stage_Connection__c,
                Next_Stage_Connection__r.Stage__c,
                Next_Stage_Connection__r.Stage__r.Display_Name__c,
                Stage__c,
                Stage__r.Display_Name__c
            FROM Stage_Connection__c
            WHERE Pipeline__c = :pipelineId
            WITH SECURITY_ENFORCED
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Environment__c> getEnvironments(Id pipelineId, List<Id> stageIds) {
        List<Environment__c> result = new List<Environment__c>();
        PipelineDescriptor pipelineDescriptor = getPipelineDescriptor(pipelineId);
        Map<Id, PipelineDescriptor.Stage> stagesById = pipelineDescriptor.stages();

        for (Id stageId : stageIds) {
            if (stagesById.containsKey(stageId)) {
                result.addAll(stagesById.get(stageId).environmentsById.values());
            }
        }
        return result;
    }

    @AuraEnabled
    public static List<AutomationRule> getAutomationRules(Id pipelineId) {
        List<Automation_Rule__c> existingRules = getContinuousDeliveryRules(pipelineId);
        List<AutomationRule> result = new List<AutomationRule>();
        for (Automation_Rule__c rule : existingRules) {
            result.add(new AutomationRule(rule).getStagesAndEnvironments());
        }
        return result;
    }

    @AuraEnabled
    public static void activateAutomations(Id pipelineId, String automationConfig) {
        try {
            ConfigurationJSON configJSON = (ConfigurationJSON) JSON.deserialize(automationConfig, ConfigurationJSON.class);

            deleteExistingRules(pipelineId);

            List<Automation_Rule__c> rules = new List<Automation_Rule__c>();
            rules.addAll(getConfiguredRule(RULE_NAME_PROMOTION, pipelineId, configJSON.promotionSettings));
            rules.addAll(getConfiguredRule(RULE_NAME_BACK_PROMOTION, pipelineId, configJSON.backpromotionSettings));

            if (!rules.isEmpty()) {
                DML.safeInsert(
                    rules,
                    'Could not insert the Automation Rule during the Continuous Delivery Setup ( ContinuousDeliverySetupController.activateAutomations class )'
                );
            }

            Set<Id> rulesIds = (new Map<Id, Automation_Rule__c>(rules)).keySet();
            new ActivateAutomationRule(rulesIds).execute();
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static List<Automation_Rule__c> getDuplicatedAutomationRule(Id pipelineId, String automationConfig) {
        try {
            ConfigurationJSON configJSON = (ConfigurationJSON) JSON.deserialize(automationConfig, ConfigurationJSON.class);

            List<Automation_Rule__c> rules = new List<Automation_Rule__c>();
            rules.addAll(getConfiguredRule(RULE_NAME_PROMOTION, pipelineId, configJSON.promotionSettings));
            rules.addAll(getConfiguredRule(RULE_NAME_BACK_PROMOTION, pipelineId, configJSON.backpromotionSettings));

            List<Automation_Rule__c> result = new AutomationRuleDuplicatesChecker(rules).execute();
            for (Integer i = result.size() - 1; i >= 0; i--) {
                if (
                    String.isNotBlank(result[i].Automated_Action__c) &&
                    result[i].Automated_Action__c.contains(AutomationRuleConstants.CONTINUOUS_DELIVERY)
                ) {
                    result.remove(i);
                }
            }
            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static List<String> isReadable(Schema.DescribeSObjectResult describeSObject) {
        List<String> result = new List<String>();
        if (!describeSObject.isAccessible()) {
            result.add(String.format(Label.Permission_Check_Read_Access_On_Object, new List<String>{ describeSObject.Label }));
        }
        return result;
    }

    private static List<String> isCreateable(Schema.DescribeSObjectResult describeSObject) {
        List<String> result = new List<String>();
        if (!describeSObject.isCreateable()) {
            result.add(String.format(Label.Permission_Check_Read_and_Create_Access_On_Object, new List<String>{ describeSObject.Label }));
        }
        return result;
    }

    private static List<String> isUpdateable(Schema.DescribeFieldResult describeField) {
        List<String> result = new List<String>();
        if (!describeField.isUpdateable()) {
            result.add(String.format(Label.Permission_Check_Read_Access_On_Object, new List<String>{ describeField.getLabel() }));
        }
        return result;
    }

    private static void deleteExistingRules(Id pipelineId) {
        if (!Schema.sObjectType.Automation_Rule__c.isDeletable()) {
            throw new ApplicationException(Label.NoPermissionsToDeleteAutomationRules);
        }
        List<Automation_Rule__c> automationRules = getContinuousDeliveryRules(pipelineId);
        Set<Id> automationRuleIds = new Map<Id, Automation_Rule__c>(automationRules).keySet();
        new DeactivateAutomationRule(automationRuleIds).execute();
        delete automationRules;
    }

    private static List<Automation_Rule__c> getContinuousDeliveryRules(Id pipelineId) {
        final List<String> connectorClasses = CONNECTOR_BY_NAME.values();
        return [
            SELECT Id, Name, Pipeline__c, Stage__c, Environment__c
            FROM Automation_Rule__c
            WHERE
                Pipeline__c = :pipelineId
                AND Automation_Connector__c IN :connectorClasses
                AND Automated_Action__c LIKE :'%' + AutomationRuleConstants.CONTINUOUS_DELIVERY + '%'
            WITH SECURITY_ENFORCED
        ];
    }

    private static List<Automation_Rule__c> getConfiguredRule(String ruleName, Id pipelineId, ConfigurationSettings configSettings) {
        List<Automation_Rule__c> result = new List<Automation_Rule__c>();

        //Note: Skip step scenario - No rule created.
        if (configSettings == null || (configSettings.selectedEnvironments == null && configSettings.uptoStage == null)) {
            return result;
        }

        String className = getClassName(ruleName);
        Automation_Rule__c rule = new Automation_Rule__c(
            Name = ruleName,
            Automated_Action__c = AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + getAutomatedActionFromConnector(className),
            Automation_Connector__c = className,
            Execution__c = AutomationRuleConstants.EXECUTION_IMMEDIATE,
            Pipeline__c = pipelineId,
            Source_Action__c = ActionConstants.PROMOTION_DEPLOYMENT,
            Source_Action_Status__c = AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL
        );

        populateEnvironmentOrStage(rule, configSettings);

        result.add(rule);

        return result;
    }

    private static void populateEnvironmentOrStage(Automation_Rule__c rule, ConfigurationSettings configSettings) {
        PipelineDescriptor pipelineDescriptor = getPipelineDescriptor(rule.Pipeline__c);
        Map<Id, PipelineDescriptor.Stage> stagesById = pipelineDescriptor.stages();
        Map<Id, Environment__c> environmentsById = pipelineDescriptor.environments();
        Map<String, Stage__c> stageByName = new Map<String, Stage__c>();
        Map<String, Environment__c> environmentByName = new Map<String, Environment__c>();
        for (PipelineDescriptor.Stage stageDescriptor : stagesById.values()) {
            stageByName.put(stageDescriptor.stage.Display_Name__c, stageDescriptor.stage);
        }
        for (Environment__c environment : environmentsById.values()) {
            environmentByName.put(environment.Name, environment);
        }
        if (configSettings.selectedEnvironments != null && !configSettings.selectedEnvironments.isEmpty()) {
            Set<Id> environmentIds = new Set<Id>();
            for (String environmentName : configSettings.selectedEnvironments) {
                if (environmentByName.containsKey(environmentName)) {
                    environmentIds.add(environmentByName.get(environmentName).Id);
                }
            }
            rule.Environment__c = String.join(new List<Id>(environmentIds), ',');
        } else if (configSettings.uptoStage != null && !configSettings.uptoStage.isEmpty()) {
            Set<Id> stageIds = new Set<Id>();
            for (String stageName : configSettings.uptoStage) {
                if (stageByName.containsKey(stageName)) {
                    stageIds.add(stageByName.get(stageName).Id);
                }
            }
            rule.Stage__c = String.join(new List<Id>(stageIds), ',');
        }
    }

    private static String getClassName(String ruleName) {
        return CONNECTOR_BY_NAME.get(ruleName);
    }

    private static String getAutomatedActionFromConnector(String className) {
        Type classType = Type.forName(namespace(className), name(className));
        AutomationConnector automationConnector = (AutomationConnector) classType.newInstance();
        return automationConnector.getAutomatedActionName();
    }

    private static String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private static String name(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

    private static PipelineDescriptor getPipelineDescriptor(Id pipelineId) {
        if (!descriptorByPipelineId.containsKey(pipelineId)) {
            descriptorByPipelineId.put(pipelineId, new PipelineDescriptor(pipelineId));
        }
        return descriptorByPipelineId.get(pipelineId);
    }

    // WRAPPER

    public with sharing class AutomationRule {
        private Automation_Rule__c rule;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String stages;
        @AuraEnabled
        public String environments;

        public AutomationRule(Automation_Rule__c rule) {
            this.rule = rule;
            this.name = rule.Name;
            this.environments = Label.ALL;
            this.stages = Label.ALL;
        }

        public AutomationRule getStagesAndEnvironments() {
            PipelineDescriptor pipelineDescriptor = getPipelineDescriptor(rule.Pipeline__c);
            Map<Id, PipelineDescriptor.Stage> stagesById = pipelineDescriptor.stages();
            Map<Id, Environment__c> environmentsById = pipelineDescriptor.environments();
            Set<String> stageIds = new Set<String>();
            if (String.isNotBlank(rule.Environment__c)) {
                List<String> environmentNames = new List<String>();
                for (String environmentId : rule.Environment__c.split(',')) {
                    if (environmentsById.containsKey(environmentId)) {
                        environmentNames.add(environmentsById.get(environmentId).Name);
                    }
                    String stageId = pipelineDescriptor.getStageId(environmentId);
                    if (String.isNotBlank(stageId)) {
                        stageIds.add(stageId);
                    }
                }
                this.environments = String.join(environmentNames, ', ');
            } else if (String.isNotBlank(rule.Stage__c)) {
                stageIds = new Set<String>(rule.Stage__c.split(','));
            }
            if (!stageIds.isEmpty()) {
                List<String> stageNames = new List<String>();
                for (String stageId : stageIds) {
                    if (stagesById.containsKey(stageId)) {
                        stageNames.add(stagesById.get(stageId).stage.Display_Name__c);
                    }
                }
                this.stages = String.join(stageNames, ', ');
            }
            return this;
        }
    }

    @TestVisible
    private with sharing class ConfigurationJSON {
        @TestVisible
        private ConfigurationSettings promotionSettings;
        @TestVisible
        private ConfigurationSettings backpromotionSettings;
    }

    @TestVisible
    private with sharing class ConfigurationSettings {
        @TestVisible
        private List<String> uptoStage;
        @TestVisible
        private List<String> selectedEnvironments;
    }
}