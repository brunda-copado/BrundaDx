@SuppressWarnings('PMD.AvoidGlobalModifier')
// AvoidGlobalModifier: As we want to expose the services as global, thus the modifier

global inherited sharing class CopadoFunctions implements CopadoDomain {
    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Functions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */

    global static ExecuteResponse execute(ExecuteRequest request) {
        Savepoint sp = Database.setSavepoint();

        try {
            return FunctionExecutionServiceImpl.execute(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Functions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static StatusResponse status(Id resultId) {
        try {
            return FunctionStatusServiceImpl.execute(resultId);
        } catch (Exception e) {
            throw new ApplicationException(e.getMessage());
        }
    }

    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Functions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static CancelResult cancel(String resultId) {
        try {
            return CancelFunctionServiceImpl.execute(resultId);
        } catch (Exception e) {
            throw new ApplicationException(e.getMessage());
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecuteRequest implements CopadoServiceRequest {
        global String functionApiName; // Function Api Name (Required)
        global Id contextId; // Context  Record Id
        global List<FunctionParameter> parameters; // List of function parameters
        global List<FunctionParameter> options; // List of options
        global String callback; // The callback that needs to be lauched after the function.  Callback can be a Flow or an Apex class that implements MCCallBack
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class FunctionParameter {
        global String name; // Name of the parameter (Required)
        global String value; // Value of the parameter (Required)
        global Boolean required = false; // If the parameter is required
        global Boolean sensitive = false; // If the parameter is sensitive

        global FunctionParameter(String name, String value) {
            this.name = name;
            this.value = value;
        }

        global FunctionParameter sensitive(Boolean sensitive) {
            this.sensitive = sensitive;
            return this;
        }

        global FunctionParameter required(Boolean required) {
            this.required = required;
            return this;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecuteResponse implements CopadoServiceResult {
        global Result__c result; // Result record

        // CONSTRUCTOR

        global ExecuteResponse(Id resultId) {
            this.result = new ResultsSelector().byId(resultId);
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class StatusResponse implements CopadoServiceResult {
        global Result__c result; // Result record

        // CONSTRUCTOR

        global StatusResponse(Result__c result) {
            this.result = result;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class CancelResult implements CopadoServiceResult {
        global Result__c result; // Result record

        // CONSTRUCTOR

        global CancelResult(Id resultId) {
            this.result = new ResultsSelector().byId(resultId);
        }
    }
}