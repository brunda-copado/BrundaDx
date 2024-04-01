@SuppressWarnings('PMD.PropertyNamingConventions, PMD.AvoidGlobalModifier')
// PropertyNamingConventions: Needed for Skeleton Attributes, as we are using a name starting by uppercase
// AvoidGlobalModifier: As we want to expose the services as global, thus the modifier

global inherited sharing class Jobs implements CopadoDomain {
    /************ EXECUTION ************/

    // SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static Execution Execution {
        get {
            if (Execution == null) {
                Execution = new Execution();
            }
            return Execution;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Jobs Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class Execution implements CopadoService {
        global ExecutionCreateResult create(ExecutionCreateRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return CreateJobWithoutTemplateServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global ExecutionCreateFromTemplateResult createFromTemplate(ExecutionCreateFromTemplateRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return CreateJobWithTemplateServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global AddStepsResult addSteps(AddStepsRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return AddStepsServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global ExecutionResult execute(ExecutionRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return JobExecuteServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return ExecutionStatusServiceImpl.execute(jobId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }

        global ExecutionResult resume(Id jobId) {
            Savepoint sp = Database.setSavepoint();

            try {
                return ResumeExecutionServiceImpl.execute(jobId);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global ExecutionResult cancel(Id jobId) {
            try {
                return CancelExecutionServiceImpl.execute(jobId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecutionCreateRequest implements CopadoServiceRequest {
        global String transactionId; // Transaction Id to share the volumeOption. If it is specified, it will be the job Execution Id
        global String parentId; // Parent Id to know from where the execution was created
        global String pipelineId; // Pipeline Id
        global String sourceId; // Source Environment Id
        global String destinationId; // Destination environment Id
        global String callback; // Name of the Apex class to launch after the job execution ends
        global String dataJson; // Data Json for Job Execution
        global List<JobStep__c> steps; // Steps to be added to job execution
        global Id parentStepId; // Parent Job step Id (for sub job execution)
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecutionCreateResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job execution record

        // CONSTRUCTOR

        global ExecutionCreateResult(JobExecution__c jobExecution) {
            this.jobExecution = jobExecution;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecutionCreateFromTemplateRequest implements CopadoServiceRequest {
        global String templateAPIName; // Job template API name (Required)
        global String transactionId; // Transaction Id to share the volumeOption. If it is specified, it will be the job Execution Id
        global String parentId; // Parent Id to know from where the execution was created
        global String pipelineId; // Pipeline Id
        global String sourceId; // Source Environment Id
        global String destinationId; // Destination environment Id
        global String callback; // Name of the Apex class to launch after the job execution ends
        global String dataJson; // Data Json for Job Execution
        global Id parentStepId; // Parent Job step Id (for sub job execution)
        global List<ExecutionStep> steps; // Steps to be added to job execution
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecutionStep {
        global List<JobStep__c> steps; // List of job steps
        global String resourceObservation; // It should match with the step that needs to be used as an anchor to attach these steps
        global String sequence; // 'before' or 'after'. Default is 'after'. It defines how this step will be attached to the job template steps

        // CONSTRUCTOR

        @SuppressWarnings('PMD.EmptyStatementBlock')
        global ExecutionStep() {
        }

        global ExecutionStep(List<JobStep__c> steps) {
            this(steps, 'after');
        }

        global ExecutionStep(List<JobStep__c> steps, String sequence) {
            this(steps, sequence, null);
        }

        global ExecutionStep(List<JobStep__c> steps, String sequence, String resourceObservation) {
            this.steps = steps;
            this.sequence = sequence;
            this.resourceObservation = resourceObservation;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecutionCreateFromTemplateResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job execution record

        // CONSTRUCTOR

        global ExecutionCreateFromTemplateResult(JobExecution__c jobExecution) {
            this.jobExecution = jobExecution;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class AddStepsRequest implements CopadoServiceRequest {
        global Id jobExecutionId; // Job Execution Id (Required)
        global List<ExecutionStep> steps; // Steps to be added to the job execution (Required)

        // CONSTRUCTOR

        global AddStepsRequest(Id jobExecutionId, List<ExecutionStep> steps) {
            this.jobExecutionId = jobExecutionId;
            this.steps = steps;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class AddStepsResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job execution record

        // CONSTRUCTOR

        global AddStepsResult(JobExecution__c jobExecution) {
            this.jobExecution = jobExecution;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecutionRequest implements CopadoServiceRequest {
        global Id jobExecutionId; // Job Execution Id (Required)
        global String transactionId; // Transaction Id to share the volumeOption

        // CONSTRUCTOR

        global ExecutionRequest(Id jobExecutionId, String transactionId) {
            this.jobExecutionId = jobExecutionId;
            this.transactionId = transactionId;
        }

        global ExecutionRequest(Id jobExecutionId) {
            this.jobExecutionId = jobExecutionId;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ExecutionResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job execution record

        // CONSTRUCTOR

        global ExecutionResult(Id jobId) {
            this.jobExecution = new JobExecutionsSelector().byId(jobId);
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class StatusResult implements CopadoServiceResult {
        global String jobStatus; // Job Execution Status
        global List<JobStep__c> steps; // List with step statuses

        // CONSTRUCTOR

        global StatusResult(String jobStatus, List<JobStep__c> steps) {
            this.jobStatus = jobStatus;
            this.steps = steps;
        }
    }

    /************ EXECUTION ************/

    /************ DYNAMIC EXPRESSION ************/

    // SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static DynamicExpression DynamicExpression {
        get {
            if (DynamicExpression == null) {
                DynamicExpression = new DynamicExpression();
            }
            return DynamicExpression;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Jobs Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class DynamicExpression implements CopadoService {
        global List<DynamicExpressionEvaluateResult> evaluate(DynamicExpressionEvaluateRequest request) {
            // Note: not setting savepoint as this service is not writing to database
            try {
                return DynamicExpressionEvaluateServiceImpl.execute(request);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class DynamicExpressionEvaluateRequest implements CopadoServiceRequest {
        global Id contextId; // Record Id
        global List<String> dynamicExpressions = new List<String>(); // List with the Dynamic expression to be evaluated (Maximum 10). (Required)

        // CONSTRUCTOR

        global DynamicExpressionEvaluateRequest(Id contextId, List<String> dynamicExpressions) {
            this.contextId = contextId;
            this.dynamicExpressions = dynamicExpressions;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class DynamicExpressionEvaluateResult implements CopadoServiceResult {
        global String dynamicExpression; // Dynamic epxression passed in the request
        global String value; // Value of the expression
        global Boolean isSensitive = false; // Value is Sensitive?
        global String errorMessage; // Parsing Error message

        @SuppressWarnings('PMD.EmptyStatementBlock')
        global DynamicExpressionEvaluateResult() {
        }

        global DynamicExpressionEvaluateResult(String dynamicExpression) {
            this(dynamicExpression, dynamicExpression, false);
        }

        global DynamicExpressionEvaluateResult(String dynamicExpression, String value) {
            this(dynamicExpression, value, false);
        }

        global DynamicExpressionEvaluateResult(String dynamicExpression, String value, Boolean isSensitive) {
            this.dynamicExpression = dynamicExpression;
            this.value = value;
            this.isSensitive = isSensitive;
        }

        global DynamicExpressionEvaluateResult(String dynamicExpression, Exception ex) {
            this.dynamicExpression = dynamicExpression;
            this.errorMessage = ex.getMessage();
        }
    }
    /************ DYNAMIC EXPRESSION ************/
}