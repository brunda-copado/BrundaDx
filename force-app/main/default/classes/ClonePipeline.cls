public with sharing class ClonePipeline {
    private static final Set<String> SYSTEM_FIELDS = new Set<String>{
        'isdeleted',
        'createddate',
        'lastmodifieddate',
        'createdbyid',
        'lastmodifiedbyid',
        'systemmodstamp',
        'lastvieweddate',
        'lastreferenceddate',
        'ownerid',
        Schema.sObjectType.Deployment_Flow__c.fields.Manage_Branches__c.getName().toLowerCase()
    };

    // PUBLIC

    @AuraEnabled(cacheable=false)
    public static String getData(Id recordId) {
        try {
            return new RecordData(recordId).asJsonString();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String saveCopy(String data) {
        try {
            return new CloneData((RecordData) JSON.deserialize(data, RecordData.class)).save();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // PRIVATE

    private with sharing abstract class Pipeline {
        protected Deployment_Flow__c pipeline;
        protected List<Deployment_Flow_Step__c> connections;
        protected List<Environment__c> environments;
        protected List<System_Property__c> properties;
        protected String platform {
            get {
                return pipeline.Platform__c;
            }
        }

        // PROTECTED

        protected void setPipeline(Id id) {
            pipeline = Database.query(byId());
        }

        private void connections(Id pipelineId) {
            connections = Database.query(byPipeline());
        }

        @SuppressWarnings('PMD.UnusedLocalVariable')
        protected void environments() {
            //NOTE: environmentIds is used on the query because byIds method return the String with the query using this parameter.
            Set<Id> environmentIds = environmentIds();
            environments = Database.query(byIds());
        }

        protected abstract String byId();
        protected abstract String byPipeline();
        protected abstract String byIds();

        // PRIVATE

        private Set<Id> environmentIds() {
            Set<Id> result = new Set<Id>();

            for (Deployment_Flow_Step__c connection : connections) {
                result.add(connection.Source_Environment__c);
                result.add(connection.Destination_Environment__c);
            }

            return result;
        }
    }

    private class RecordData extends Pipeline {
        // CTOR
        Boolean useExistingEnvironments;
        Boolean copySystemPropertyValues;
        public RecordData(Id id) {
            setPipeline(id);
            connections(id);
            environments();
            useExistingEnvironments = platform == null || platform == 'Salesforce' ? false : true;
            copySystemPropertyValues = true;
        }

        // PUBLIC
        public String asJsonString() {
            return JSON.serialize(this);
        }

        // PROTECTED

        protected override String byId() {
            return 'SELECT Name, Git_Repository__c, Main_Branch__c, Platform__c FROM Deployment_Flow__c WHERE Id = :id WITH SECURITY_ENFORCED';
        }

        protected override String byPipeline() {
            return 'SELECT Branch__c, Source_Environment__c, Destination_Environment__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipelineId WITH SECURITY_ENFORCED';
        }

        protected override String byIds() {
            return 'SELECT Name FROM Environment__c WHERE Id IN :environmentIds WITH SECURITY_ENFORCED';
        }
    }

    @SuppressWarnings('PMD.CyclomaticComplexity') // to avoid large refactor
    private with sharing class CloneData extends Pipeline {
        private RecordData record;

        // CTOR

        public CloneData(RecordData record) {
            this.record = record;
            setPipeline(record.pipeline.Id);
            connections(record.pipeline.Id);
            environments();
            properties(record.pipeline.Id);
        }

        // PUBLIC

        public Id save() {
            setPipeline(clonePipeline().Id);
            Map<Id, Environment__c> environmentClones = platform == 'Salesforce' ? new Map<Id, Environment__c>() : cloneEnvironments();
            cloneProperties(environmentClones);
            cloneConnections(environmentClones);

            return pipeline.Id;
        }

        // PROTECTED

        private void properties(Id pipelineId) {
            properties = Database.query(byParentIds());
        }

        protected override String byId() {
            return 'SELECT ' + pipelineFields() + ' FROM Deployment_Flow__c WHERE Id = :id WITH SECURITY_ENFORCED';
        }

        protected override String byPipeline() {
            return 'SELECT ' +
                connectionFields() +
                ' FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipelineId' +
                ' WITH SECURITY_ENFORCED';
        }

        protected override String byIds() {
            return 'SELECT ' + environmentFields() + ' FROM Environment__c WHERE Id IN :environmentIds WITH SECURITY_ENFORCED';
        }

        // PRIVATE

        private String byParentIds() {
            Boolean bothLevels = platform != 'Salesforce' && !record.useExistingEnvironments;
            String query = 'SELECT ' + propertyFields() + ' FROM System_Property__c WHERE (Pipeline__c = :pipelineId';
            if (bothLevels) {
                query += ' OR Environment__c IN :environments)';
            }
            query += ' AND Is_Global__c = FALSE ' + (!bothLevels ? ')' : '');
            query += ' WITH SECURITY_ENFORCED';

            return query;
        }

        private String pipelineFields() {
            return String.join(
                stripSystemFields(Deployment_Flow__c.sObjectType.getDescribe(SObjectDescribeOptions.FULL).fields.getMap().keySet()),
                ','
            );
        }

        private String connectionFields() {
            return String.join(
                stripSystemFields(Deployment_Flow_Step__c.sObjectType.getDescribe(SObjectDescribeOptions.FULL).fields.getMap().keySet()),
                ','
            );
        }

        private String environmentFields() {
            return String.join(stripSystemFields(Environment__c.sObjectType.getDescribe(SObjectDescribeOptions.FULL).fields.getMap().keySet()), ',');
        }

        private String propertyFields() {
            return String.join(
                stripSystemFields(System_Property__c.sObjectType.getDescribe(SObjectDescribeOptions.FULL).fields.getMap().keySet()),
                ','
            );
        }

        private List<String> stripSystemFields(Set<String> fields) {
            List<String> result = new List<String>();

            for (String field : fields) {
                if (!ClonePipeline.SYSTEM_FIELDS.contains(field)) {
                    result.add(field);
                }
            }

            return result;
        }

        @SuppressWarnings('PMD.ApexCRUDViolation')
        private Deployment_Flow__c clonePipeline() {
            Deployment_Flow__c result = pipeline.clone();

            result.Name = record.pipeline.Name;
            result.Git_Repository__c = record.pipeline.Git_Repository__c;
            result.Main_Branch__c = record.pipeline.Main_Branch__c;
            result.Active__c = false;
            DML.safeInsert(result, 'Could not create a Pipeline object on the cloning process ( ClonePipeline.clonePipeline class )');

            return result;
        }

        private Map<Id, Environment__c> cloneEnvironments() {
            if (record.useExistingEnvironments) {
                return environmentInputs();
            }

            List<Environment__c> records = clonedRecords();
            // StripInaccessible removes the clone source id from the cloned record, so Secure_DML is used instead.
            Utilities.Secure_DML(records, Utilities.DML_Action.INS, SObjectType.Environment__c);

            Map<Id, Environment__c> result = new Map<Id, Environment__c>();
            for (Environment__c clone : records) {
                result.put(clone.getCloneSourceId(), clone);
            }

            return result;
        }

        private List<Environment__c> clonedRecords() {
            List<Environment__c> result = new List<Environment__c>();
            Map<Id, Environment__c> environmentInputs = environmentInputs();

            for (Environment__c environment : environments) {
                Environment__c clone = environment.clone();
                clone.Name = environmentInputs.get(environment.Id)?.Name;
                clone.Org_ID__c = null;
                clone.Latest_Deployment__c = null;
                result.add(clone);
            }

            return result;
        }

        private Map<Id, Environment__c> environmentInputs() {
            Map<Id, Environment__c> result = new Map<Id, Environment__c>();

            if (record.environments != null) {
                for (Environment__c environment : record.environments) {
                    result.put(environment.Id, environment);
                }
            }

            return result;
        }

        private void cloneProperties(Map<Id, Environment__c> environmentClones) {
            List<System_Property__c> result = new List<System_Property__c>();

            for (System_Property__c property : properties) {
                System_Property__c clone = property.clone();
                clone.ParentId__c = null;
                clone.Value__c = record.copySystemPropertyValues ? clone.Value__c : null;
                if (String.isNotBlank(clone.Pipeline__c)) {
                    clone.Pipeline__c = pipeline.Id;
                } else if (String.isNotBlank(clone.Environment__c)) {
                    clone.Environment__c = environmentClones.get(property.Environment__c)?.Id;
                }
                result.add(clone);
            }

            DML.safeInsert(
                Security.stripInaccessible(AccessType.CREATABLE, result).getRecords(),
                'Unable to create system properties while cloning pipelines'
            );
        }

        private Map<Id, Deployment_Flow_Step__c> connectionInputs() {
            Map<Id, Deployment_Flow_Step__c> result = new Map<Id, Deployment_Flow_Step__c>();

            if (record.connections != null) {
                result = new Map<Id, Deployment_Flow_Step__c>(record.connections);
            }

            return result;
        }

        private void cloneConnections(Map<Id, Environment__c> environmentClones) {
            List<Deployment_Flow_Step__c> result = new List<Deployment_Flow_Step__c>();

            Map<Id, Deployment_Flow_Step__c> inputs = connectionInputs();
            Map<String, String> branchesByOldName = branchesByOldName(inputs);

            for (Deployment_Flow_Step__c connection : connections) {
                String branch = inputs.get(connection.Id)?.Branch__c;
                String destinationBranch = branchesByOldName.get(connection.Destination_Branch__c);

                Deployment_Flow_Step__c clone = connection.clone();
                clone.Deployment_Flow__c = pipeline.Id;
                clone.Branch__c = branch;
                clone.Destination_Branch__c = String.isBlank(destinationBranch) ? pipeline.Main_Branch__c : destinationBranch;
                clone.Source_Environment__c = environmentClones.get(connection.Source_Environment__c)?.Id;
                clone.Destination_Environment__c = environmentClones.get(connection.Destination_Environment__c)?.Id;
                // Note: need to clear stage information, as stage connections will be different for the new pipeline (and we don't clone the stage connections yet)
                clone.Stage_Connection__c = null;
                result.add(clone);
            }

            insert Security.stripInaccessible(AccessType.CREATABLE, result).getRecords();
        }

        private Map<String, String> branchesByOldName(Map<Id, Deployment_Flow_Step__c> inputs) {
            Map<String, String> result = new Map<String, String>();

            for (Deployment_Flow_Step__c connection : connections) {
                result.put(connection.Branch__c, inputs.get(connection.Id)?.Branch__c);
            }

            return result;
        }
    }
}