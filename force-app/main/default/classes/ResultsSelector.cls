public inherited sharing class ResultsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Result__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Result__c.Id,
            Result__c.Name,
            Result__c.Function__c,
            Result__c.Progress_Status__c,
            Result__c.Error_Message__c,
            Result__c.Error_Code__c,
            Result__c.Result_Data__c,
            Result__c.Status__c,
            Result__c.ParentId__c,
            Result__c.Job_Type__c,
            Result__c.Job_Id__c,
            Result__c.JobStep__c,
            Result__c.Start_Time__c,
            Result__c.End_Time__c,
            Result__c.ApexCallback__c,
            Result__c.Function_Worker_Size__c,
            Result__c.Test__c,
            Result__c.Custom_Function_Used_Minutes__c,
            Result__c.Custom_Function_Used_Credits__c,
            Result__c.LastModifiedDate,
            Result__c.Link__c
        };
    }

    public Result__c byId(Id recordId) {
        List<Result__c> result = byIds(new Set<Id>{ recordId });
        return result.isEmpty() ? null : result[0];
    }

    public List<Result__c> byIds(Set<Id> ids) {
        return Database.query(selectFields().setCondition('Id IN :ids').toSOQL());
    }

    public List<Result__c> inProgressByIds(Set<Id> ids) {
        return Database.query(
            selectFields().setCondition('Id IN :ids AND Function__c != NULL AND Status__c IN (\'Not Started\',\'In Progress\')').toSOQL()
        );
    }

    public Result__c byJobExecutionId(Id jobExecutionId) {
        List<Result__c> results = Database.query(
            selectFields()
                .setCondition('JobStep__r.JobExecution__c = :jobExecutionId')
                .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );

        return !results.isEmpty() ? results[0] : null;
    }

    public Result__c getLatestResultByTestId(Id testId) {
        List<Result__c> results = Database.query(
            selectFields().setCondition('Result__c.Test__c = :testId').setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        return !results.isEmpty() ? results[0] : null;
    }

    public Result__c getLatestFinalResultByTestId(Id testId) {
        List<Result__c> results = Database.query(
            selectFields()
                .setCondition('Result__c.Test__c = :testId AND Status__c IN (\'Success\',\'Failed\')')
                .setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );

        return !results.isEmpty() ? results[0] : null;
    }

    public Result__c byJobStepId(Id jobStepId) {
        List<Result__c> results = Database.query(
            selectFields().setCondition('JobStep__c = :jobStepId').setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        return !results.isEmpty() ? results[0] : null;
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectField('Test__r.Name')
            .selectField('Function__r.Type__c')
            .selectField('Function__r.API_Name__c')
            .selectField('Function__r.Script__c')
            .selectField('Function__r.Image_Name__c')
            .selectField('Function__r.Worker_Size__c')
            .selectField('Function__r.Result_Viewer_Component__c')
            .selectField('JobStep__r.Name')
            .selectField('JobStep__r.Type__c')
            .selectField('JobStep__r.JobExecution__c')
            .selectField('JobStep__r.Source_Id__c')
            .selectField('JobStep__r.ConfigJson__c')
            .selectField('JobStep__r.Destination_Id__c')
            .selectField('JobStep__r.Pipeline_Id__c')
            .selectField('JobStep__r.Quality_Gate_Rule__c')
            .selectField('JobStep__r.Quality_Gate_Rule__r.Name')
            .selectField('JobStep__r.Quality_Gate_Rule__r.Tool__c')
            .selectField('JobStep__r.JobExecution__r.Name')
            .selectField('JobStep__r.JobExecution__r.Context__c')
            .selectField('JobStep__r.JobExecution__r.ParentId__c')
            .selectField('JobStep__r.JobExecution__r.DataJson__c')
            .selectField('JobStep__r.Sub_Job_Execution__c')
            .selectField('JobStep__r.Result_Viewer_Component__c')
            .selectField('JobStep__r.JobExecution__r.Job_Step__c')
            .selectField('JobStep__r.JobExecution__r.Job_Step__r.Name')
            .selectField('JobStep__r.JobExecution__r.Job_Step__r.CustomType__c');
    }
}