@SuppressWarnings('PMD.AvoidGlobalModifier')
global class GlobalFindAndReplaceDestinationId extends GlobalFindAndReplaceHelper implements ParameterExpressionCallable {
    global String execute(Id contextId) {
        return getContentVersionOfYamlFile(contextId, false);
    }
}