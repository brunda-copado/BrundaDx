@SuppressWarnings('PMD.CognitiveComplexity,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.CyclomaticComplexity')
public inherited sharing class StepExpression extends DynamicExpression {
    private static final Pattern PATTERN_FIRST_STEP_FIELD = Pattern.compile('(?i)\\{\\s*\\$?(Job).(FirstStep).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_PREV_STEP_FIELD = Pattern.compile('(?i)\\{\\s*\\$?(Job).(PrevStep).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_NEXT_STEP_FIELD = Pattern.compile('(?i)\\{\\s*\\$?(Job).(NextStep).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_LAST_STEP_FIELD = Pattern.compile('(?i)\\{\\s*\\$?(Job).(LastStep).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_NAMED_STEP_FIELD = Pattern.compile('(?i)\\{\\s*\\$?(Job).(Step).([A-Za-z0-9-_ ]+).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');

    private static final Pattern PATTERN_PREV_STEP_JSON = Pattern.compile('(?i)\\{\\s*\\$?(Job).(PrevStep).(JSONResult).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_FIRST_STEP_JSON = Pattern.compile('(?i)\\{\\s*\\$?(Job).(FirstStep).(JSONResult).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_NEXT_STEP_JSON = Pattern.compile('(?i)\\{\\s*\\$?(Job).(NextStep).(JSONResult).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_LAST_STEP_JSON = Pattern.compile('(?i)\\{\\s*\\$?(Job).(LastStep).(JSONResult).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');
    private static final Pattern PATTERN_NAMED_STEP_JSON = Pattern.compile('(?i)\\{\\s*\\$?(Job).(Step).([A-Za-z0-9-_ ]+).(JSONResult).([A-Za-z0-9-_.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');

    private String objectName;
    private Decimal currentOrder;
    private List<SObject> allSteps = new List<SObject>();

    // CONSTRUCTOR

    public StepExpression(String contextId) {
        this.contextId = contextId;
    }

    // PUBLIC

    public override Boolean matches(String expression) {
        return (PATTERN_FIRST_STEP_FIELD.matcher(expression).matches() ||
                PATTERN_FIRST_STEP_JSON.matcher(expression).matches() ||
                PATTERN_PREV_STEP_JSON.matcher(expression).matches() ||
                PATTERN_PREV_STEP_FIELD.matcher(expression).matches() ||
                PATTERN_NEXT_STEP_JSON.matcher(expression).matches() ||
                PATTERN_NEXT_STEP_FIELD.matcher(expression).matches() ||
                PATTERN_LAST_STEP_JSON.matcher(expression).matches() ||
                PATTERN_LAST_STEP_FIELD.matcher(expression).matches() ||
                PATTERN_NAMED_STEP_JSON.matcher(expression).matches() ||
                PATTERN_NAMED_STEP_FIELD.matcher(expression).matches());
    }

    public override void prepare() {
        objectName = objectName(recordId());
        List<String> fieldNames = fieldNames();

        if(!fieldNames.isEmpty() && objectName == 'Deployment_Job__c') {
            Deployment_Job__c currentJob = currentJob();
            currentOrder = currentJob.Step__r.Order__c;
            allSteps = allSteps(currentJob, fieldNames);
        } else if (!fieldNames.isEmpty() && objectName == 'JobStep__c') {
            JobStep__c currentStep = currentStep();
            currentOrder = currentStep.Order__c;
            allSteps = allSteps(currentStep, fieldNames);
        } else {
            throw new ApplicationException(
                String.format(Label.invalidContextId, new List<String>{ String.join(expressions, ', '), Label.JobStep })
            );
        }
    }

    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        String result = null;

        Matcher prevStepField = PATTERN_PREV_STEP_FIELD.matcher(expression);
        Matcher nextStepField = PATTERN_NEXT_STEP_FIELD.matcher(expression);
        Matcher firstStepField = PATTERN_FIRST_STEP_FIELD.matcher(expression);
        Matcher lastStepField = PATTERN_LAST_STEP_FIELD.matcher(expression);
        Matcher namedStepField = PATTERN_NAMED_STEP_FIELD.matcher(expression);

        Matcher prevStepJson = PATTERN_PREV_STEP_JSON.matcher(expression);
        Matcher nextStepJson = PATTERN_NEXT_STEP_JSON.matcher(expression);
        Matcher firstStepJson = PATTERN_FIRST_STEP_JSON.matcher(expression);
        Matcher lastStepJson = PATTERN_LAST_STEP_JSON.matcher(expression);
        Matcher namedStepJson = PATTERN_NAMED_STEP_JSON.matcher(expression);

        if(firstStepJson.matches()) {
            SObject firstStep =  getStepByOrder(1);
            String propertyName = firstStepJson.group(4);
            String jsonResult = (objectName == 'Deployment_Job__c')
                ? String.valueOf(firstStep.get('JsonResult__c'))
                : String.valueOf(firstStep.get('ResultDataJson__c'));

            String value = getValueFromJson(jsonResult, propertyName);
            result = String.isBlank(firstStepJson.group(5)) ? value : isMatching(firstStepJson.group(5), value);
        } else if (prevStepJson.matches()) {
            SObject previousStep =  previousStep();
            String propertyName = prevStepJson.group(4);
            String jsonResult = (objectName == 'Deployment_Job__c')
                ? String.valueOf(previousStep.get('JsonResult__c'))
                : String.valueOf(previousStep.get('ResultDataJson__c'));

            String value = getValueFromJson(jsonResult, propertyName);
            result = String.isBlank(prevStepJson.group(5)) ? value : isMatching(prevStepJson.group(5), value);
        } else if (nextStepJson.matches()) {
            SObject nextStep =  nextStep();
            String propertyName = nextStepJson.group(4);
            String jsonResult = (objectName == 'Deployment_Job__c')
                ? String.valueOf(nextStep.get('JsonResult__c'))
                : String.valueOf(nextStep.get('ResultDataJson__c'));

            String value = getValueFromJson(jsonResult, propertyName);
            result = String.isBlank(nextStepJson.group(5)) ? value : isMatching(nextStepJson.group(5), value);
        } else if (lastStepJson.matches()) {
            SObject lastStep =  lastStep();
            String propertyName = lastStepJson.group(4);
            String jsonResult = (objectName == 'Deployment_Job__c')
                ? String.valueOf(lastStep.get('JsonResult__c'))
                : String.valueOf(lastStep.get('ResultDataJson__c'));

            String value = getValueFromJson(jsonResult, propertyName);
            result = String.isBlank(lastStepJson.group(5)) ? value : isMatching(lastStepJson.group(5), value);
        } else if (firstStepField.matches()) {
            SObject firstStep =  getStepByOrder(1);
            String propertyName = firstStepField.group(3);

            String value = getValue(firstStep, propertyName);
            result = String.isBlank(firstStepField.group(4)) ? value : isMatching(firstStepField.group(4), value);
        } else if (prevStepField.matches()) {
            SObject previousStep =  previousStep();
            String propertyName = prevStepField.group(3);

            String value = getValue(previousStep, propertyName);
            result = String.isBlank(prevStepField.group(4)) ? value : isMatching(prevStepField.group(4), value);
        } else if (nextStepField.matches()) {
            SObject nextStep =  nextStep();
            String propertyName = nextStepField.group(3);

            String value = getValue(nextStep, propertyName);
            result = String.isBlank(nextStepField.group(4)) ? value : isMatching(nextStepField.group(4), value);
        } else if (lastStepField.matches()) {
            SObject lastStep =  lastStep();
            String propertyName = lastStepField.group(3);

            String value = getValue(lastStep, propertyName);
            result = String.isBlank(lastStepField.group(4)) ? value : isMatching(lastStepField.group(4), value);
        } else if (namedStepJson.matches()) {
            String stepName = namedStepJson.group(3);
            String propertyName = namedStepJson.group(5);

            SObject step =  getStepByName(stepName);
            String jsonResult = (objectName == 'Deployment_Job__c')
                ? String.valueOf(step.get('JsonResult__c'))
                : String.valueOf(step.get('ResultDataJson__c'));

            String value = getValueFromJson(jsonResult, propertyName);
            result = String.isBlank(namedStepJson.group(6)) ? value : isMatching(namedStepJson.group(6), value);
        } else if (namedStepField.matches()) {
            String stepName = namedStepField.group(3);
            String propertyName = namedStepField.group(4);
            SObject step =  getStepByName(stepName);

            String value = getValue(step, propertyName);
            result = String.isBlank(namedStepField.group(5)) ? value : isMatching(namedStepField.group(5), value);
        }

        return new Jobs.DynamicExpressionEvaluateResult(expression, result);
    }

    // PRIVATE

    private JobStep__c currentStep() {
        return (JobStep__c) Database.query('SELECT JobExecution__c, Order__c FROM JobStep__c WHERE Id = :contextId WITH SECURITY_ENFORCED');
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    private List<SObject> allSteps(JobStep__c step, List<String> fieldNames) {
        Id executionId = step.JobExecution__c;

        return Database.query('SELECT ' + String.join(fieldNames, ', ') + ' FROM JobStep__c WHERE JobExecution__c = :executionId WITH SECURITY_ENFORCED');
    }

    private SObject previousStep() {
        Integer previousOrder = (currentOrder != null) ? Integer.valueOf(currentOrder) - 1 : null;

        return getStepByOrder(previousOrder);
    }

    private SObject nextStep() {
        Integer nextOrder = (currentOrder != null) ? Integer.valueOf(currentOrder) + 1 : null;

        return getStepByOrder(nextOrder);
    }

    private SObject lastStep() {
        return getStepByOrder(allSteps.size());
    }

    private SObject getStepByOrder(Integer order) {
        for(SObject step : allSteps) {
            if(Integer.valueOf(step.get('Order__c')) == order) {
                return step;
            }
        }

        throw new ApplicationException(String.format(Label.Invalid_Step, new List<String> { String.join(expressions, ', ') }));
    }

    private SObject getStepByName(String stepName) {
        for(SObject step : allSteps) {
            if(String.valueOf(step.get('Name')) == stepName) {
                return step;
            }
        }

        throw new ApplicationException(String.format(Label.Invalid_Step, new List<String> { String.join(expressions, ', ') }));
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    private List<SObject> allSteps(Deployment_Job__c currentJob, List<String> stepFields) {
        Id deploymentId = currentJob.Step__r.Deployment__c;
        String query = 'SELECT Id, (SELECT ' + String.join(stepFields, ', ') + ' FROM Steps__r) FROM  Deployment__c WHERE Id = :deploymentId WITH SECURITY_ENFORCED';

        Deployment__c deployment = (Deployment__c) Database.query( String.escapeSingleQuotes(query) ).get(0);

        return deployment.Steps__r;
    }

    private Deployment_Job__c currentJob() {
        List<Deployment_Job__c> currentJobs = [SELECT Step__r.Order__c, Step__r.Deployment__c FROM Deployment_Job__c WHERE Id = :recordId() WITH SECURITY_ENFORCED];

        if(currentJobs.isEmpty()) {
            throw new ApplicationException(Label.InValidDeploymentJobId);
        }

        return currentJobs[0];
    }

    private List<String> fieldNames() {
        Set<String> result = new Set<String>();

        for(String expression : expressions) {
            Matcher prevStepField = PATTERN_PREV_STEP_FIELD.matcher(expression);
            Matcher firstStepField = PATTERN_FIRST_STEP_FIELD.matcher(expression);
            Matcher nextStepField = PATTERN_NEXT_STEP_FIELD.matcher(expression);
            Matcher lastStepField = PATTERN_LAST_STEP_FIELD.matcher(expression);
            Matcher namedStepField = PATTERN_NAMED_STEP_FIELD.matcher(expression);

            Matcher prevStepJson = PATTERN_PREV_STEP_JSON.matcher(expression);
            Matcher firstStepJson = PATTERN_FIRST_STEP_JSON.matcher(expression);
            Matcher nextStepJson = PATTERN_NEXT_STEP_JSON.matcher(expression);
            Matcher lastStepJson = PATTERN_LAST_STEP_JSON.matcher(expression);
            Matcher namedStepJson = PATTERN_NAMED_STEP_JSON.matcher(expression);

            String fieldName;

            if(prevStepJson.matches() || firstStepJson.matches() || nextStepJson.matches() || lastStepJson.matches() || namedStepJson.matches()) {
                fieldName = (objectName == 'Deployment_Job__c') ? 'JsonResult__c' : 'ResultDataJson__c';
            } else if (firstStepField.matches()) {
                fieldName = firstStepField.group(3);
            } else if (prevStepField.matches()) {
                fieldName = prevStepField.group(3);
            } else if (nextStepField.matches()) {
                fieldName = nextStepField.group(3);
            } else if (lastStepField.matches()) {
                fieldName = lastStepField.group(3);
            } else if (namedStepField.matches()) {
                fieldName = namedStepField.group(4);
            }

            result.add(fieldName);
        }

        if(!result.isEmpty()) {
            result.add('Name');
            result.add('Order__c');
        }

        return new List<String>(result);
    }
}