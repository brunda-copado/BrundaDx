@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DestinationEnvironmentBranch implements ParameterExpressionCallable {
    // GLOBAL

    global String execute(Id contextId) {
        return new EnvironmentBranchHelper(contextId).getDestinationBranchName();
    }
}