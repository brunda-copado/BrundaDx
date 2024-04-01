@IsTest
public class AutomationConnectorMock extends AutomationConnector {
    private CustomRequest request;

    public override List<AutomationConnector> getConnectors(AutomationConnectorContext context) {
        this.request = new CustomRequest();
        this.request.message = '';
        for (Automation_Event__c event : context.automationEvents) {
            this.request.message += event.Action_Result__c;
        }

        if (this.request.message == 'Throw Connect Exception') {
            throw new ApplicationException(this.request.message);
        }

        if (this.request.message == 'Multiple Executions') {
            AutomationConnectorMock mock1 = new AutomationConnectorMock();
            mock1.context = context;
            mock1.request = new CustomRequest();
            mock1.request.message = 'Mock 1';
            AutomationConnectorMock mock2 = new AutomationConnectorMock();
            mock2.context = context;
            mock2.request = new CustomRequest();
            mock2.request.message = 'Mock 2';
            AutomationConnectorMock mock3 = new AutomationConnectorMock();
            mock3.context = context;
            mock3.request = new CustomRequest();
            mock3.request.message = 'Throw Exception';
            return new List<AutomationConnector>{ mock1, mock2, mock3 };
        }

        return new List<AutomationConnector>{ this };
    }

    public override String executeAutomation() {
        if (this.request.message == 'Throw Exception') {
            throw new ApplicationException(this.request.message);
        }

        JobExecution__c jobExecution = new JobExecution__c();
        jobExecution.ErrorMessage__c = this.request.message;
        insert jobExecution;

        return jobExecution.Id;
    }

    public override String getAutomatedActionName() {
        return 'Mock Action';
    }

    public override String getUIComponentName() {
        return 'c:mockScopeConfigurator';
    }

    class CustomRequest {
        private String message;
    }
}