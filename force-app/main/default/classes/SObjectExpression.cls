public inherited sharing class SObjectExpression extends DynamicExpression {

    private static final Pattern FIELD_PATTERN = Pattern.compile('(?i)\\{\\s*\\$?(Context)\\.([A-Za-z0-9_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern JOB_EXECUTION_PATTERN = Pattern.compile('(?i)\\{\\s*\\$?(Job)\\.(ExecutionParent)\\.([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern JSON_PATTERN = Pattern.compile('(?i)\\{\\s*\\$?(Context)\\.([A-Za-z0-9_.]*DataJson)\\.([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern ENVIRONMENT_FIELD_PATTERN = Pattern.compile('(?i)\\{\\s*\\$?(Context)\\.(Environment)\\.([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');

    private SObject record;
    private SObject parentRecord;

    // CONSTRUCTOR
    public SObjectExpression(String contextId) {
        this.contextId = contextId;
    }

    // PUBLIC
    public override void prepare() {
        record = record();
        parentRecord = parentRecord();
    }

    public override Boolean matches(String expression) {
        Matcher matcher1 = FIELD_PATTERN.matcher(expression);
        Matcher matcher2 = JSON_PATTERN.matcher(expression);
        Matcher matcher3 = JOB_EXECUTION_PATTERN.matcher(expression);
        Matcher matcher4 = ENVIRONMENT_FIELD_PATTERN.matcher(expression);       

        return matcher1.matches() || matcher2.matches() || matcher3.matches() || matcher4.matches();
    }

    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        String result = null;

        Matcher matcher1 = FIELD_PATTERN.matcher(expression);
        Matcher matcher2 = JSON_PATTERN.matcher(expression);
        Matcher matcher3 = JOB_EXECUTION_PATTERN.matcher(expression);
        Matcher matcher4 = ENVIRONMENT_FIELD_PATTERN.matcher(expression);

        if (matcher4.matches()) {
            String fieldName = matcher4.group(3);
            String environment = getEnvironmentFromContext();
            result = getValue(record, environment + fieldName);
        }
        else if(matcher3.matches()) {
            String fieldName = matcher3.group(3);
            String value = getValue(parentRecord, fieldName);
            result = String.isBlank(matcher3.group(4)) ? value : isMatching(matcher3.group(4), value);
        }
        else if(matcher2.matches()) {
            String fieldName = matcher2.group(2);
            fieldName = fieldName.replace('DataJson', 'DataJson__c');
            String jsonValue = getValue(record, fieldName);
            String value = getValueFromJson(jsonValue, matcher2.group(3));
            result = String.isBlank(matcher2.group(4)) ? value : isMatching(matcher2.group(4), value);
        }
        else if(matcher1.matches()) {
            String propertyName = matcher1.group(2);
            String value = getValue(record, propertyName);
            result = String.isBlank(matcher1.group(3)) ? value : isMatching(matcher1.group(3), value);
        }

        return new Jobs.DynamicExpressionEvaluateResult(expression, result);
    }


    // PRIVATE
    private SObject record() {
        SObject result = null;
        List<String> fields = fields();

        Id recordId = recordId('Context');

        if(!fields.isEmpty()) {
            String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + objectName(recordId) + ' WHERE Id =:recordId WITH SECURITY_ENFORCED';
            result = Database.query( String.escapeSingleQuotes(query) ).get(0);
        }

        return result;
    }


    private List<String> fields() {
        Set<String> result = new Set<String>();

        for(String expression : expressions) {
            Matcher matcher1 = FIELD_PATTERN.matcher(expression);
            Matcher matcher2 = JSON_PATTERN.matcher(expression);
            Matcher matcher3 = JOB_EXECUTION_PATTERN.matcher(expression);
            Matcher matcher4 = ENVIRONMENT_FIELD_PATTERN.matcher(expression);

            if (matcher4.matches()) {
                String sourceFieldName = 'JobExecution__r.Source__r.' + matcher4.group(3);
                String destinationFieldName = 'JobExecution__r.Destination__r.' + matcher4.group(3);
                String parentId = 'JobExecution__r.ParentId__c';
                result.add(sourceFieldName);
                result.add(destinationFieldName);
                result.add(parentId);
            }
            else if(matcher3.matches()) {
                continue;
            }
            else if(matcher2.matches()) {
                String fieldName = matcher2.group(2);
                fieldName = fieldName.replace('DataJson', 'DataJson__c');
                result.add(fieldName);
            }
            else if(matcher1.matches()) {
                String fieldName = matcher1.group(2);
                result.add(fieldName);
            }
        }

        return new List<String>(result);
    }


    private SObject parentRecord() {
        SObject result = null;
        List<String> fields = parentFields();
        String objectName = objectName(contextId);

        if(fields.isEmpty()) {
            return result;
        }

        if(objectName != 'JobStep__c') {
            throw new ApplicationException(Label.invalidExecutionParentContext);
        }

        List<JobStep__c> steps = [SELECT Id, JobExecution__r.ParentId__c FROM JobStep__c WHERE Id = :contextId WITH SECURITY_ENFORCED];
        if(steps.isEmpty()) {
            throw new ApplicationException(Label.invalidJobStepId);
        } else if(String.isBlank(steps[0].JobExecution__r.ParentId__c)) {
            throw new ApplicationException(Label.executionParentRequired);
        }

        Id parentId = steps[0].JobExecution__r.ParentId__c;
        String parentName = objectName(parentId);

        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + parentName + ' WHERE Id =:parentId WITH SECURITY_ENFORCED';
        result = Database.query( String.escapeSingleQuotes(query) ).get(0);

        return result;
    }


    private List<String> parentFields() {
        Set<String> result = new Set<String>();

        for(String expression : expressions) {
            Matcher matcher = JOB_EXECUTION_PATTERN.matcher(expression);

            if(matcher.matches()) {
                String fieldName = matcher.group(3);
                result.add(fieldName);
            }
        }

        return new List<String>(result);
    }

    private String getEnvironmentFromContext() {
        Id parentId = (Id) getValue(record, 'JobExecution__r.ParentId__c');
        String parentObjectName = objectName(parentId);

        if(parentObjectName == 'User_Story_Commit__c' || parentObjectName == 'Promotion__c') {
            return 'JobExecution__r.Source__r.';
        } else if(parentObjectName == 'Deployment__c') {
            return 'JobExecution__r.Destination__r.';
        }

        throw new ApplicationException(Label.InvalidContextForBranchExpression);
    }
}