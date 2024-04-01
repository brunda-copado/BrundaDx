public with sharing class ActionCallback {
    private String actionCallback;
    private JobExecution__c job;
    private String status;

    @TestVisible
    private static String mockCallback;

    // CONSTRUCTOR

    public ActionCallback(String actionCallback, JobExecution__c job, String status) {
        this.actionCallback = actionCallback;
        this.job = job;
        this.status = status;
    }

    // PUBLIC

    public void run() {
        if (Test.isRunningTest() && String.isNotBlank(mockCallback)) {
            actionCallback = mockCallback;
        }
        if (String.isBlank(actionCallback)) {
            return;
        }
        String apexCallback = selectClass(actionCallback);
        if (String.isNotBlank(apexCallback)) {
            executeApex(apexCallback);
        } else {
            String flowCallback = selectFlow(actionCallback);
            if (String.isNotBlank(flowCallback)) {
                executeFlow(flowCallback);
            }
        }
    }

    // PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private String selectClass(String actionCallback) {
        String namespace = namespace(actionCallback);
        String className = name(actionCallback);
        // Note: False positive
        List<ApexClass> apexClasses = [
            SELECT Name, NamespacePrefix
            FROM ApexClass
            WHERE Name = :className AND NamespacePrefix = :namespace AND Status = 'Active'
            LIMIT 1
        ];
        return !apexClasses.isEmpty()
            ? (String.isNotBlank(apexClasses[0].NamespacePrefix) ? apexClasses[0].NamespacePrefix + '.' : '') + apexClasses[0].Name
            : null;
    }

    private String selectFlow(String actionCallback) {
        String namespace = namespace(actionCallback);
        String flowName = name(actionCallback);
        List<FlowDefinitionView> flows = [
            SELECT ApiName, NamespacePrefix
            FROM FlowDefinitionView
            WHERE ApiName = :flowName AND NamespacePrefix = :namespace AND IsActive = TRUE
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return !flows.isEmpty() ? (String.isNotBlank(flows[0].NamespacePrefix) ? flows[0].NamespacePrefix + '.' : '') + flows[0].ApiName : null;
    }

    private String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private String name(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

    private void executeApex(String apexCallback) {
        Type callback = Type.forName(namespace(apexCallback), name(apexCallback));
        if (callback == null) {
            throw new ApplicationException(Label.InvalidCallback + ' ' + actionCallback);
        }
        ((JobExecutionCallback) callback.newInstance()).execute(job, status);
    }

    private void executeFlow(String flowCallback) {
        Map<String, Object> parameters = new Map<String, Object>{ 'job' => job, 'status' => status };
        Flow.Interview.createInterview(namespace(flowCallback), name(flowCallback), parameters).start();
    }
}