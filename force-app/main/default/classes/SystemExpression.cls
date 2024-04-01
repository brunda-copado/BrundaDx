@SuppressWarnings('PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity')
public inherited sharing class SystemExpression extends DynamicExpression {
    private static final String CONTEXT_REGEX1 = '(?i)\\{\\s*\\$?(Source|Destination|Pipeline)\\.([A-Za-z0-9_\\.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}';
    private static final String CONTEXT_REGEX2 = '(?i)\\{\\s*\\$?(Source|Destination|Pipeline|User|Global|Context)\\.Property\\.([A-Za-z0-9_]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}';
    private static final String CONTEXT_REGEX3 = '(?i)\\{\\s*\\$?Property\\.([A-Za-z0-9_]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}';

    private static final String GLOBAL_PROPERTY = 'Global';
    private static final String USER = 'User';
    private static final String DESTINATION = 'Destination';
    private static final String SOURCE = 'Source';
    private static final String PIPELINE = 'Pipeline';

    private static final Pattern CONTEXT_PATTERN1 = Pattern.compile(CONTEXT_REGEX1);
    private static final Pattern CONTEXT_PATTERN2 = Pattern.compile(CONTEXT_REGEX2);
    private static final Pattern CONTEXT_PATTERN3 = Pattern.compile(CONTEXT_REGEX3);

    private SObject record;
    private Map<Id, SObject> recordsByParentId;
    private Map<String, System_Property__c> propertiesByUId;

    private Map<Id, Set<String>> fieldsByParentIds = new Map<Id, Set<String>>();
    private Set<String> uIds = new Set<String>();

    // CONSTRUCTOR

    public SystemExpression(String contextId) {
        this.contextId = contextId;
    }

    // PUBLIC

    public override Boolean matches(String expression) {
        return (CONTEXT_PATTERN1.matcher(expression).matches() ||
        CONTEXT_PATTERN2.matcher(expression).matches() ||
        CONTEXT_PATTERN3.matcher(expression).matches());
    }

    public override void prepare() {
        if (String.isNotBlank(contextId)) {
            String objectName = objectName(recordId());
            record = getParentRecord(objectName);
        }

        parseExpressions();
        propertiesByUId = new SystemPropertiesSelector().byUID(uIds);
        recordsByParentId = recordsByParentId();
    }

    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        String value = null;
        Boolean isSensitive = false;

        Matcher contextMatcher1 = CONTEXT_PATTERN1.matcher(expression);
        Matcher contextMatcher2 = CONTEXT_PATTERN2.matcher(expression);
        Matcher contextMatcher3 = CONTEXT_PATTERN3.matcher(expression);

        if (contextMatcher3.matches()) {
            String propertyName = contextMatcher3.group(1);
            System_Property__c systemProperty = getPropertyByPrecedence(propertyName, expression);

            value = String.isBlank(contextMatcher3.group(2))
                ? systemProperty?.Value__c
                : isMatching(contextMatcher3.group(2), systemProperty?.Value__c);
            isSensitive = systemProperty != null ? systemProperty?.Is_Sensitive__c : false;
        } else if (contextMatcher2.matches()) {
            String contextType = contextMatcher2.group(1).equalsIgnoreCase('Context') && objectName(contextId) == 'JobStep__c' ? getEnvironmentFromContext(): contextMatcher2.group(1);
            String propertyName = contextMatcher2.group(2);
            String uID = contextType == GLOBAL_PROPERTY ? propertyName : parentId(contextType, expression) + '-' + propertyName;
            System_Property__c systemProperty = propertiesByUId.get(uID);

            value = String.isBlank(contextMatcher2.group(3))
                ? systemProperty?.Value__c
                : isMatching(contextMatcher2.group(3), systemProperty?.Value__c);
            isSensitive = systemProperty != null ? systemProperty?.Is_Sensitive__c : false;
        } else if (contextMatcher1.matches()) {
            String contextType = contextMatcher1.group(1);
            String propertyName = contextMatcher1.group(2);
            String parentId = parentId(contextType, expression);

            SObject record = recordsByParentId.get(parentId);

            value = String.isBlank(contextMatcher1.group(3))
                ? getValue(record, propertyName)
                : isMatching(contextMatcher1.group(3), getValue(record, propertyName));
        }

        return new Jobs.DynamicExpressionEvaluateResult(expression, value, isSensitive);
    }

    // PRIVATE

    private void parseExpressions() {
        for (String expression : expressions) {
            String value = expression;

            Matcher contextMatcher1 = CONTEXT_PATTERN1.matcher(value);
            Matcher contextMatcher2 = CONTEXT_PATTERN2.matcher(value);
            Matcher contextMatcher3 = CONTEXT_PATTERN3.matcher(value);

            if (contextMatcher3.matches()) {
                String propertyName = contextMatcher3.group(1);

                addToUids(propertyName, expression);
            } else if (contextMatcher2.matches()) {
                String contextType = contextMatcher2.group(1).equalsIgnoreCase('Context') && objectName(contextId) == 'JobStep__c' ? getEnvironmentFromContext(): contextMatcher2.group(1);
                String propertyName = contextMatcher2.group(2);
                addPropertyWithContext(contextType, propertyName, expression);
            } else if (contextMatcher1.matches()) {
                String contextType = contextMatcher1.group(1);
                String propertyName = contextMatcher1.group(2);

                Id parentId = parentId(contextType, expression);
                if (parentId == null) {
                    throw new ApplicationException(String.format(Label.contextRequired, new List<String>{ contextType, expression }));
                }

                if (!fieldsByParentIds.containsKey(parentId)) {
                    fieldsByParentIds.put(parentId, new Set<String>());
                }

                fieldsByParentIds.get(parentId).add(propertyName);
            }
        }
    }

    private SObject getParentRecord(String objectName) {
        SObject result;
        List<String> fields = getFields();

        //NOTE : Check on fields.size() to avoid a soql query when the expression is {$Context.*}
        if (String.isNotBlank(objectName) && fields.size() > 1) {
            String query =
                'SELECT ' +
                String.join(fields, ', ') +
                ' FROM ' +
                String.escapeSingleQuotes(objectName) +
                ' WHERE Id = :contextId WITH USER_MODE';
            try {
                result = Database.query(String.escapeSingleQuotes(query));
            } catch (Exception ex) {
                objectName = Settings.ns + objectName;
                String objectLabel = Schema.getGlobalDescribe().get(objectName).getDescribe().getLabel();
                throw new ApplicationException(
                    String.format(Label.invalidField, new List<String>{ Settings.ns + ex.getMessage().substringBetween('\'', '\''), objectLabel })
                );
            }
        }

        return result;
    }

    private List<String> getFields() {
        Set<String> result = new Set<String>{ 'Id' };

        Set<String> nonQueryableContexts = new Set<String>{ 'user', 'context', 'global' };

        for (String expression : expressions) {
            Matcher contextMatcher1 = CONTEXT_PATTERN1.matcher(expression);
            Matcher contextMatcher2 = CONTEXT_PATTERN2.matcher(expression);
            Matcher contextMatcher3 = CONTEXT_PATTERN3.matcher(expression);

            if (contextMatcher3.matches()) {
                // NOTE : For hierarchical properties, these 3 fields are required to be queried on job step / deployment job
                result.add('Source_Id__c');
                result.add('Destination_Id__c');
                result.add('Pipeline_Id__c');
            } else if (contextMatcher2.matches() && contextMatcher2.group(1).equalsIgnoreCase('Context') && objectName(contextId) == 'JobStep__c') {
                result.add('Source_Id__c');
                result.add('Destination_Id__c');
                result.add('JobExecution__r.ParentId__c');
            } else if (contextMatcher2.matches() && !nonQueryableContexts.contains(contextMatcher2.group(1).toLowerCase())) {
                result.add(contextMatcher2.group(1) + '_Id__c');
            } else if (contextMatcher1.matches() && !nonQueryableContexts.contains(contextMatcher1.group(1).toLowerCase())) {
                result.add(contextMatcher1.group(1) + '_Id__c');
            }
        }

        return new List<String>(result);
    }

    // NOTE: The SOQL query inside loop is necessary because expression support polymorphic record Ids(false positive)
    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    private Map<Id, Sobject> recordsByParentId() {
        Map<Id, Sobject> result = new Map<Id, Sobject>();

        for (Id parentId : fieldsByParentIds.keySet()) {
            String objectName = objectName(parentId);
            List<String> fields = new List<String>(fieldsByParentIds.get(parentId));
            String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + objectName + ' WHERE Id = :parentId WITH USER_MODE';
            SObject record = Database.query(String.escapeSingleQuotes(query));

            result.put(parentId, record);
        }

        return result;
    }

    private Id parentId(String contextType, String expression) {
        String result = null;

        if (String.isBlank(contextId) && !contextType.equalsIgnoreCase(USER)) {
            throw new ApplicationException(String.format(Label.invalidContextId, new List<String>{ expression, Label.Record }));
        }

        if (contextType.equalsIgnoreCase(USER)) {
            result = UserInfo.getUserId();
        } else if (contextType.equalsIgnoreCase('Context') || record == null) {
            result = contextId;
        } else if (record != null) {
            String fieldName = contextType + '_Id__c';
            result = (String) record?.get(fieldName);
        }

        return result;
    }

    private void addToUids(String propertyName, String expression) {
        Set<String> contextTypes = new Set<String>{ USER, DESTINATION, SOURCE, PIPELINE };

        for (String contextType : contextTypes) {
            uIds.add(parentId(contextType, expression) + '-' + propertyName);
        }
        // NOTE : This is for Global System Properties
        uIds.add(propertyName);
    }

    private void addPropertyWithContext(String contextType, String propertyName, String expression) {
        if (contextType == GLOBAL_PROPERTY) {
            uIds.add(propertyName);
        } else {
            uIds.add(parentId(contextType, expression) + '-' + propertyName);
        }
    }

    private System_Property__c getPropertyByPrecedence(String propertyName, String expression) {
        System_Property__c result = null;

        List<String> uIdsbyPrecedence = new List<String>{
            parentId(USER, expression) +
            '-' +
            propertyName,
            parentId(DESTINATION, expression) +
            '-' +
            propertyName,
            parentId(SOURCE, expression) +
            '-' +
            propertyName,
            parentId(PIPELINE, expression) +
            '-' +
            propertyName,
            propertyName
        };

        for (String key : uIdsbyPrecedence) {
            if (propertiesByUId.containsKey(key)) {
                result = propertiesByUId.get(key);
                break;
            }
        }

        return result;
    }

    private String getEnvironmentFromContext() {
        Id parentId = (Id) getValue(record, 'JobExecution__r.ParentId__c');
        String parentObjectName = objectName(parentId);

        if(parentObjectName == 'User_Story_Commit__c' || parentObjectName == 'Promotion__c') {
            return 'Source';
        } else if(parentObjectName == 'Deployment__c') {
            return 'Destination';
        }

        throw new ApplicationException(Label.InvalidContextForBranchExpression);
    }
}