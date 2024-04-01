@SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.AvoidGlobalModifier,PMD.ExcessivePublicCount')
// VariableNamingConventions: needed for Skeleton Attributes, as we are using a name starting by uppercase
// PropertyNamingConventions: needed for Skeleton Attributes, as we are using a name starting by uppercase
// AvoidGlobalModifier: As we want to expose the services as global, thus the modifier
global inherited sharing class Actions implements CopadoDomain {
    /************ COMMIT ***********************/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static CommitService CommitService {
        get {
            if (CommitService == null) {
                CommitService = new CommitService();
            }
            return CommitService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class CommitService implements CopadoService {
        global CommitResult execute(CommitRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return CommitServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class CommitRequest implements CopadoServiceRequest {
        global String baseBranch; // Base branch for the commit. If not provided, a default value is calculated based on User Story, Release, or Pipeline
        global CommitChange[] changes; // List of changes to commit. See below for details
        global String commitId; // Id of an existing git commit with the changes. Likely specified when commiting from CLI
        global Boolean executeCommit = true; // If set to false, actual commit behaviour will be skipped and only operations in Copado will happen. Likely specified to false when commiting from CLI. Defaults to true
        global String otherInformation; // Additional commit information in JSON format (255 characters)
        global String message; // Commit message. If not provided, a default value is calculated based on User Story Name and Title
        global Boolean recreateFeatureBranch = false; // If specified, previous branch and User Story Metadata records already committed will be deleted. Defaults to false
        global Id userStoryId; // User Story where to commit the changes
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback, invoked after job execution completion. Its functional purpose is to inject post-execution logic needed by the action consumer.
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class CommitChange {
        global String a; // Platform-dependant action: add, del … for copadodx also fullpps, permission-only
        global String c; // category of this item (sfdx, mulesoft, other, ...).
        global String m; // module directory. The path of the file
        global String n; // name (either filename or metadata name)
        global String t; // type (either file extension or metadata type)
        global String j; // otherInformation, any other information that this technology needs per item.
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class CommitResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job execution handling the action operation
        global User_Story_Commit__c userStorycommit; // User Story Commit record as result of the action
    }

    /************ COMMIT ***********************/

    /******** PROMOTION ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static PromotionService PromotionService {
        get {
            if (PromotionService == null) {
                PromotionService = new PromotionService();
            }
            return PromotionService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class PromotionService implements CopadoService {
        global PromotionResult execute(PromotionRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return PromotionServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PromotionRequest implements CopadoServiceRequest {
        global Id promotionId; // Id of the Promotion record. If it is not defined, Copado will create a new promotion with the parameter values provided.
        global Id transactionId; // Optional Id of the transaction. It will be used to send to deploy action for queue management.
        global List<Id> userStoryIds; // Ids of the user stories to be included in the promotion.
        global Boolean executePromotion; // Include this parameter if you want to run the promote job template. Default true
        global Boolean executeDeployment; // Execute Deployment. Default FALSE
        global Boolean deploymentDryRun; // Deployment Dry Run. Default FALSE
        global String otherInformation; // Additional information that can be passed for the job execution in JSON format
        global Id sourceEnvironmentId; // Id of the promotion’s source environment. Copado will use this parameter to populate the destination environment if no promotion Id is specified.
        global Id projectId; // Id of the Project record that will be used to define the pipeline details and pipeline connections.
        global Boolean isBackPromotion; // Include this parameter if the promotion that will be executed is a back-promotion. Default FALSE
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PromotionResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job execution handling the action operation
        global Promotion__c promotion; // Promotion record as result of the action
    }

    /******** PROMOTION ********/

    /******** PROMOTION DEPLOYMENT ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static PromotionDeploymentService PromotionDeploymentService {
        get {
            if (PromotionDeploymentService == null) {
                PromotionDeploymentService = new PromotionDeploymentService();
            }
            return PromotionDeploymentService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class PromotionDeploymentService implements CopadoService {
        global PromotionDeploymentResult execute(PromotionDeploymentRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return PromotionDeploymentServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PromotionDeploymentRequest implements CopadoServiceRequest {
        global Id promotionId; // Id of the Promotion record. If it is not defined, Copado will create a new promotion with the parameter values provided.
        global Id transactionId; // Optional Id transaction. If your process is Promote and Deploy and is not defined, Copado will populate it with id of the Promotion Job Execution.
        global Boolean deploymentDryRun; // Deployment Dry Run. Default FALSE
        global String otherInformation; // Additional information that can be passed for the job execution in JSON format
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PromotionDeploymentResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job execution handling the action operation
    }

    /******** PROMOTION DEPLOYMENT ********/

    /************ PACKAGE CREATE ***********************/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static PackageCreateService PackageCreateService {
        get {
            if (PackageCreateService == null) {
                PackageCreateService = new PackageCreateService();
            }
            return PackageCreateService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class PackageCreateService implements CopadoService {
        global PackageCreateResult execute(PackageCreateRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return PackageCreateServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PackageCreateRequest implements CopadoServiceRequest {
        global Id packageId; // Id of the Package
        global String otherInformation; // Additional information that can be passed for the job execution in JSON format
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PackageCreateResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job Execution created record for the Action
    }

    /************ PACKAGE CREATE ***********************/

    /******** PACKAGE VERSION CREATE ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static PackageVersionCreateService PackageVersionCreateService {
        get {
            if (PackageVersionCreateService == null) {
                PackageVersionCreateService = new PackageVersionCreateService();
            }
            return PackageVersionCreateService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class PackageVersionCreateService implements CopadoService {
        global PackageVersionCreateResult execute(PackageVersionCreateRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return PackageVersionCreateServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PackageVersionCreateRequest implements CopadoServiceRequest {
        global Id packageId; // Id of the Package
        global String versionName; // Name of the package version
        global String versionNumber; // Number of the package version
        global String description; // Description of the package version
        global String otherInformation; // Additional information that can be passed for the job execution in JSON format
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PackageVersionCreateResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job Execution created record for the Action
    }

    /******** PACKAGE VERSION CREATE ********/

    /******** PACKAGE DISTRIBUTE ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static PackageDistributeService PackageDistributeService {
        get {
            if (PackageDistributeService == null) {
                PackageDistributeService = new PackageDistributeService();
            }
            return PackageDistributeService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class PackageDistributeService implements CopadoService {
        global PackageDistributeRequestResult execute(PackageDistributeRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return PackageDistributeServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PackageDistributeRequest implements CopadoServiceRequest {
        global Id packageVersionId; // Id of the Package Version to distribute
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class PackageDistributeRequestResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job Execution created record for the Action
    }

    /******** PACKAGE DISTRIBUTE ********/

    /******** RUN TEST ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static RunTestService RunTestService {
        get {
            if (RunTestService == null) {
                RunTestService = new RunTestService();
            }
            return RunTestService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class RunTestService implements CopadoService {
        global RunTestResult execute(RunTestRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return RunTestServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class RunTestRequest implements CopadoServiceRequest {
        global String tool; // Master label of the Test Tool custom metadata type record that applies to all Test\'s Tool Configurations.
        global List<Id> contextIds; // List of Salesforce Record Ids that contain Tests. It might be multiple test records, user stories, features or applications.
        global String extensionConfigurationId; // Id of the Extension Configuration Record
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback
        global String resultId; // Id of the Result Record
        global String acceptanceCriteria; // Acceptance Criteria
        global String environmentId; // Id of the Environment to run the Test
        global String otherInformation; // Additional information in JSON format
        global String transactionId; // Contains the transaction Id to be used in case the volume needs to be preserved across job executions
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class RunTestResult implements CopadoServiceResult {
        global JobExecution__c jobExecution; // Job Execution created record for the Run Test Action
    }

    /******** RUN TEST ********/

    /******** SNAPSHOT ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    global static GitSnapshotService GitSnapshotService {
        get {
            if (GitSnapshotService == null) {
                GitSnapshotService = new GitSnapshotService();
            }
            return GitSnapshotService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    global inherited sharing class GitSnapshotService implements CopadoService {
        global ConfigureGitSnapshotResult configure(ConfigureGitSnapshotRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return ConfigureGitSnapshotServiceImpl.configure(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global TakeGitSnapshotResult takeSnapshot(TakeGitSnapshotRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return TakeGitSnapshotServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        global StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database

            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ConfigureGitSnapshotRequest implements CopadoServiceRequest {
        global String name; // Snapshot name
        global String credentialId; // Source environment where the metadata/code will be retrieved from
        global String branch; // Branch where the metadata/code will be committed to.
        global String externalId; // External Id. If it is blank it will be populated with the Salesforce Id
        global String repositoryId; // Git Repository that the branch belongs to
        global String pipelineId; // Used to define the pipeline that the environments belong to, in case it’s used in more than one pipeline
        global String additionalInformation; // Indicates a list of additional settings that the action can receive to implement additional functionality. For example Environment Variable and Global Find and Replace can be included in the Additional Information Json
        global String scope; // Indicates an inclusion or exclusion list of files (text) for the retrieve.
        global String configurationFile; // List of configuration files that may be needed to push to the branch
        global String cronExpression; // If it’s empty the frequency will be none, in other scenario it will be scheduled
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class ConfigureGitSnapshotResult implements CopadoServiceResult {
        global Git_Backup__c snapshot; // Upserted Snapshot Record
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class TakeGitSnapshotRequest implements CopadoServiceRequest {
        @InvocableVariable(label='Snapshot Id' description='Id or External Id of the Git Snapshot Record' required=true)
        global String snapshotId; // Id or External Id of the Git Snapshot Record

        @InvocableVariable(label='Snapshot Commit Message' description='Commit message' required=false)
        global String message; // Commit message

        @InvocableVariable(
            label='Additional Information'
            description='Additional snapshot information in JSON format (255 characters)'
            required=false
        )
        global String otherInformation; // Additional snapshot information in JSON format (255 characters)

        @InvocableVariable(label='Callback' description='Apex Callback Class that implements JobExecutionCallback' required=false)
        global String actionCallback; // Apex Callback Class that implements JobExecutionCallback
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class TakeGitSnapshotResult implements CopadoServiceResult {
        @InvocableVariable(label='job Execution Record' description='' required=false)
        global JobExecution__c jobExecution; // Job Execution created record for the Take Snapshot Action
        @InvocableVariable(label='Snapshot Commit Record' description='' required=false)
        global Git_Org_Commit__c snapshotCommit; // Snapshot Commit record as result of the action
    }

    /******** SNAPSHOT ********/

    /******** USB ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static UserStoryBundleService UserStoryBundleService {
        get {
            if (UserStoryBundleService == null) {
                UserStoryBundleService = new UserStoryBundleService();
            }
            return UserStoryBundleService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public with sharing class UserStoryBundleService implements CopadoService {
        public CreateUserStoryBundleResult create(CreateUserStoryBundleRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return CreateUserStoryBundleServiceImpl.create(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public AddUserStoryBundleResult add(AddUserStoryBundleRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return AddUserStoryBundleServiceImpl.add(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public RemoveUserStoryBundleResult remove(RemoveUserStoryBundleRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return RemoveUserStoryBundleServiceImpl.remove(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public ExecuteUserStoryBundleResult execute(ExecuteUserStoryBundleRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return ExecuteUserStoryBundleServiceImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database

            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class CreateUserStoryBundleRequest implements CopadoServiceRequest {
        public Artifact_Version__c packageVersion; // Pre populated Package Version record to create for the User Story Bundle Action
        public List<Id> userStoryIds; // List of User Story Ids that will be included in the bundle
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class CreateUserStoryBundleResult implements CopadoServiceResult {
        public Artifact_Version__c packageVersion; // Package Version created record for the User Story Bundle Action
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class AddUserStoryBundleRequest implements CopadoServiceRequest {
        public Id packageVersionId; // Package version id that is created for user story bundle.
        public List<Id> userStoryIds; // List of User Story Ids that will be included in the bundle
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class AddUserStoryBundleResult implements CopadoServiceResult {
        public List<Bundled_Story__c> bundledUserStories; // List of Bundled User Stories that is created under Package Version record
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class RemoveUserStoryBundleRequest implements CopadoServiceRequest {
        public Id packageVersionId; // Package version id that is created for user story bundle.
        public List<Id> userStoryIds; // List of User Story Ids that will be removed from the bundle
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class RemoveUserStoryBundleResult implements CopadoServiceResult {
        public List<Bundled_Story__c> bundledUserStories; // List of Bundled User Stories that is remained under Package Version record
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class ExecuteUserStoryBundleRequest implements CopadoServiceRequest {
        public Id packageVersionId; // Package version id that is created for user story bundle.
        public User_Story__c bundleUserStory; // Pre populated User Story record to create for the User Story Bundle
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class ExecuteUserStoryBundleResult implements CopadoServiceResult {
        public User_Story__c bundleUserStory; // User Story Dundled created record with Utility record type
        public CommitResult commitResult; // Commit Action result
    }

    /******** USB ********/

    /******** SUBMITUSERSTORY ********/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static SubmitUserStoryService SubmitUserStoryService {
        get {
            if (SubmitUserStoryService == null) {
                SubmitUserStoryService = new SubmitUserStoryService();
            }
            return SubmitUserStoryService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Actions Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public with sharing class SubmitUserStoryService implements CopadoService {
        public MatchAutomationRuleResult match(MatchAutomationRuleRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return SubmitUserStoryServiceImpl.match(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public SubmitUserStoryResult submit(SubmitUserStoryRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                return SubmitUserStoryServiceImpl.submit(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public StatusResult status(Id jobExecutionId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database

            try {
                return StatusServiceImpl.status(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class SubmitUserStoryRequest implements CopadoServiceRequest {
        public Id userStoryId; // User Story Id
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class SubmitUserStoryResult implements CopadoServiceResult {
        public Automation_Event__c automationEvent; // Automation Event record that service created
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class MatchAutomationRuleRequest implements CopadoServiceRequest {
        public Id userStoryId; // User Story Id
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class MatchAutomationRuleResult implements CopadoServiceResult {
        public Automation_Rule__c automationRule; // Automation rule record that matches with the user story fields (environment, stage, pipeline, ...)
        public User_Story__c userStory; // User Story Record
    }

    /******** SUBMITUSERSTORY ********/

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class StatusResult implements CopadoServiceResult {
        global String jobStatus; // Job Execution Status
        global JobStep__c[] steps; // list with step statuses
    }
}