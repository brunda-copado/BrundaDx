public inherited sharing class FunctionStatusServiceImpl {
    // PUBLIC

    public static CopadoFunctions.StatusResponse execute(Id resultId) {
        if (resultId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String>{ 'Result Id' }));
        }

        return new CopadoFunctions.StatusResponse(
            [
                SELECT
                    Id,
                    Name,
                    Function__c,
                    Progress_Status__c,
                    Error_Message__c,
                    Result_Data__c,
                    Status__c,
                    JobStep__c,
                    Start_Time__c,
                    End_Time__c,
                    ApexCallback__c,
                    Function_Worker_Size__c,
                    Custom_Function_Used_Minutes__c,
                    Custom_Function_Used_Credits__c
                FROM Result__c
                WHERE Id = :resultId
                WITH SECURITY_ENFORCED
            ]
        );
    }
}