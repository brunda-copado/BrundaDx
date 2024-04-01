public with sharing class DuplicateStageConnectionCheck {
    private List<Stage_Connection__c> stageConnections;

    // CONSTRUCTOR

    public DuplicateStageConnectionCheck(List<Stage_Connection__c> records) {
        stageConnections = records;
    }

    // PUBLIC

    public void execute() {
        List<Stage_Connection__c> existingStageConnections = findExistingStageConnectionsOnPipeline();
        Map<Stage_Connection__c, String> nextStageByStageConnection = calculateNextStages();

        for(Stage_Connection__c stageConnection : stageConnections) {
            for(Stage_Connection__c existingStageConnection : existingStageConnections) {
                Boolean pipelineMatch = stageConnection.Pipeline__c == existingStageConnection.Pipeline__c;
                Boolean stageMatch = stageConnection.Stage__c == existingStageConnection.Stage__c;
                Boolean nextStageMatch = nextStageByStageConnection.get(stageConnection) == existingStageConnection.Next_Stage_Connection__r.Stage__c;
                
                if(pipelineMatch && stageMatch && nextStageMatch) {
                    stageConnection.addError(Label.Duplicate_Stage_Connection_Error);
                    break;
                }

                if(pipelineMatch && existingStageConnection.Next_Stage_Connection__c != null && nextStageMatch) {
                    stageConnection.addError(Label.Duplicate_Next_Stage_Connection_Error);
                    break;
                }
            }
        }
    }

    // PRIVATE

    private Map<Stage_Connection__c, String> calculateNextStages() {
        Map<Stage_Connection__c, String> result = new Map<Stage_Connection__c, String>();
        List<Stage_Connection__c> nextStageConnections = [SELECT Id, Stage__c FROM Stage_Connection__c WHERE Id IN :getFieldValues('Next_Stage_Connection__c') WITH SECURITY_ENFORCED];
        
        for(Stage_Connection__c stageConnection : stageConnections) {
            for(Stage_Connection__c nextStageConnection : nextStageConnections) {
                if(stageConnection.Next_Stage_Connection__c == nextStageConnection.Id) {
                    result.put(stageConnection, nextStageConnection.Stage__c);
                    break;
                }
            }
        }
        
        return result;
    }

    private List<Stage_Connection__c> findExistingStageConnectionsOnPipeline() {
        return [SELECT Id, Pipeline__c, Stage__c, Next_Stage_Connection__r.Stage__c FROM Stage_Connection__c WHERE Pipeline__c IN :getFieldValues('Pipeline__c') WITH SECURITY_ENFORCED];
    }

    private Set<Id> getFieldValues(String fieldApiName) {
        Set<Id> result = new Set<Id>();
        for(Stage_Connection__c stageConnection : stageConnections) {
            result.add((Id) stageConnection.get(Settings.ns + fieldApiName));
        }

        return result;
    }
}