public with sharing class PreventDeletionOfStagesInUse {
    private List<Stage__c> stages;

    // CONSTRUCTOR

    public PreventDeletionOfStagesInUse(List<Stage__c> records) {
        stages = records;
    }

    // PUBLIC

    public void execute() {
        Map<Id, List<Stage_Connection__c>> stageConnectionsByStage = getConnectionsByStage();

        for (Stage__c stage : stages) {
            if (stageConnectionsByStage.containsKey(stage.Id) && !stageConnectionsByStage.get(stage.Id).isEmpty()) {
                stage.addError(Label.Stages_In_Use_Cannot_Be_Deleted);
            }
        }
    }

    // PRIVATE

    private Map<Id, List<Stage_Connection__c>> getConnectionsByStage() {
        Set<Id> stageIds = new Map<Id, Stage__c>(stages).keySet();
        return new StageConnectionsSelector().byStage(stageIds);
    }
}