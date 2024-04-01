@SuppressWarnings('PMD.AvoidGlobalModifier')
global class GlobalFindAndReplaceSourceId extends GlobalFindAndReplaceHelper implements ParameterExpressionCallable {
    global String execute(Id contextId) {
        return getContentVersionOfYamlFile(contextId, true);
    }
}