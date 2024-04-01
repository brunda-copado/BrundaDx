@SuppressWarnings('PMD.AvoidGlobalModifier')
global class SourceEnvironmentBranch implements ParameterExpressionCallable {
    // GLOBAL

    global String execute(Id contextId) {
        return new EnvironmentBranchHelper(contextId).getSourceBranchName();
    }
}