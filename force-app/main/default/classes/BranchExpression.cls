public inherited sharing class BranchExpression extends DynamicExpression {
    private static final Pattern CONTEXT_BRANCH_PATTERN = Pattern.compile('(?i)\\{\\s*\\$?Context.(Branch)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern ENVIRONMENT_BRANCH_PATTERN = Pattern.compile('(?i)\\{\\s*\\$?(Source|Destination).(Branch)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');

    private SObject record;
    private Map<Id, String> branchNameByEnvironmentId = new Map<Id, String>();

    // CONSTRUCTOR

    public BranchExpression(String contextId) {
        this.contextId = contextId;
    }


    // PUBLIC


    public override void prepare() {
        record = record();
        branchNameByEnvironmentId = branchNameByEnvironmentId();
    }


    public override Boolean matches(String expression) {
        Matcher matcher1 = CONTEXT_BRANCH_PATTERN.matcher(expression);
        Matcher matcher2 = ENVIRONMENT_BRANCH_PATTERN.matcher(expression);

        return (matcher1.matches() || matcher2.matches());
    }


    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        String result = '';
        Matcher matcher1 = CONTEXT_BRANCH_PATTERN.matcher(expression);
        Matcher matcher2 = ENVIRONMENT_BRANCH_PATTERN.matcher(expression);

        if(matcher1.matches()) {
            String dataJson = getValue(record, 'JobExecution__r.DataJson__c');
            Id parentId = (Id) getValue(record, 'JobExecution__r.ParentId__c');

            String branchKey = getBranchKeyFor(parentId);
            String value = String.isBlank(branchKey) ? '' : getValueFromJson(dataJson, branchKey);
            result = String.isBlank(matcher1.group(2)) ? value : isMatching(matcher1.group(2), value);
        }
        else if(matcher2.matches()) {
            String branchType = matcher2.group(1);
            String environmentField = branchType == 'Source' ? 'Source_Id__c' : 'Destination_Id__c';
            Id environmentId = (Id) getValue(record, environmentField);
            String value = branchNameByEnvironmentId.get(environmentId);
            result = String.isBlank(matcher2.group(3)) ? value : isMatching(matcher2.group(3), value);
        }

        return new Jobs.DynamicExpressionEvaluateResult(expression, result);
    }


    // PRIVATE


    private SObject record() {
        SObject result = null;

        Id recordId = recordId('Context');

        if(objectName(recordId) != 'JobStep__c') {
            throw new ApplicationException(
                String.format(Label.invalidContextId, new List<String>{ String.join(expressions, ', '), Label.JobStep })
            );
        }

        List<String> fields = fields();

        if(!fields.isEmpty()) {
            String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + objectName(recordId) + ' WHERE Id =:recordId WITH SECURITY_ENFORCED';
            result = Database.query( String.escapeSingleQuotes(query) ).get(0);
        }

        return result;
    }


    private List<String> fields() {
        Set<String> result = new Set<String>();

        for(String expression : expressions) {
            Matcher matcher1 = CONTEXT_BRANCH_PATTERN.matcher(expression);
            Matcher matcher2 = ENVIRONMENT_BRANCH_PATTERN.matcher(expression);

            if(matcher1.matches()) {
                result.add('JobExecution__r.DataJson__c');
                result.add('JobExecution__r.ParentId__c');
            }
            else if(matcher2.matches()) {
                if(matcher2.group(1) == 'Source') {
                    result.add('Source_Id__c');
                } else if(matcher2.group(1) == 'Destination') {
                    result.add('Destination_Id__c');
                }

                result.add('JobExecution__r.Pipeline__c');
            }
        }

        return new List<String>(result);
    }


	private String getBranchKeyFor(Id parentId){
        String objectAPIName = parentId.getSObjectType().getDescribe().getLocalName();

        if(objectAPIName == 'User_Story_Commit__c') {
            return 'featureBranchName';
        } else if(objectAPIName == 'Promotion__c') {
            return 'promotionBranchName';
        } else if(objectAPIName == 'Deployment__c') {
            return 'destinationBranchName';
        }

        throw new ApplicationException(Label.InvalidContextForBranchExpression);
	}


	private Map<Id,String> branchNameByEnvironmentId() {
        Map<Id,String> result = new Map<Id,String>();
        Set<Id> environmentIds = environmentIds();

        if(!environmentIds.isEmpty()) {
            Id pipelineId = (Id) getValue(record, 'JobExecution__r.Pipeline__c');

            for(Deployment_Flow_Step__c connection : [SELECT Id, Branch__c, Destination_Branch__c, Destination_Environment__c, Source_Environment__c
                                                        FROM Deployment_Flow_Step__c
                                                        WHERE Deployment_Flow__c = :pipelineId
                                                            AND (Destination_Environment__c IN :environmentIds OR Source_Environment__c IN :environmentIds)
                                                        WITH SECURITY_ENFORCED]) {
                result.put(connection.Source_Environment__c, connection.Branch__c);
                result.put(connection.Destination_Environment__c, connection.Destination_Branch__c);
            }
        }

        return result;
	}


    private Set<Id> environmentIds() {
        Set<Id> result = new Set<Id>();

        for(String expression : expressions) {
            Matcher matcher2 = ENVIRONMENT_BRANCH_PATTERN.matcher(expression);

            if(matcher2.matches()) {
                if(matcher2.group(1) == 'Source') {
                    result.add(getValue(record, 'Source_Id__c'));
                } else if(matcher2.group(1) == 'Destination') {
                    result.add(getValue(record, 'Destination_Id__c'));
                }
            }
        }

        return result;
    }
}