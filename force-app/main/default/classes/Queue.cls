public with sharing class Queue {
    public static final String QUEUE_TOPIC_URI = '/event/copado/v1/queue-resume/';
    private static final Pattern TEMPLATE_PATTERN = Pattern.compile(
        '\\{\\$?[a-zA-Z_][a-zA-Z0-9_]*\\.[a-zA-Z_][a-zA-Z0-9_.]*(\\.[a-zA-Z_][a-zA-Z0-9_]*)?\\}'
    );
    private static final String BLOCKED = 'Blocked';

    public static AddResponse add(AddRequest request) {
        assertRequiredParameter(request);
        Logger.trace(request.contextId, 'Queue.add', 'start', request);

        String resolvedResource = parseResource(request.contextId, request.resource);
        List<Queue__c> existingQueue = [SELECT Id, transaction__c, Status__c FROM Queue__c WHERE Resource__c = :resolvedResource WITH USER_MODE];

        List<Queue__c> blockedQueue = blockedQueues(existingQueue, request.transactionId);

        if(!blockedQueue.isEmpty()) {
            DML.deleteAsSystem(blockedQueue, '');
        }
        String jobStatus = (existingQueue.isEmpty() || !blockedQueue.isEmpty()) ? 'In Progress' : 'Queued';

        DML.insertAsSystem(
            new Queue__c(Name = request.contextName, Resource__c = resolvedResource, ContextId__c = request.contextId, Status__c = jobStatus, Transaction__c = request.transactionId),
            ''
        );

        if(jobStatus == 'In Progress') {
            String callbackName = request.callback.getName();
            Type callback = Type.forName(ns(callbackName), localClass(callbackName));
            ((CopadoQueueable) callback.newInstance()).execute(request.payload);
        } else {
            Map<String, String> flowParameter = new Map<String, String> {
                'payload' => request.payload,
                'resource' => resolvedResource,
                'contextId' => request.contextId,
                'callback' => request.callback.getName()
            };

            new Flow.Interview.QueueOrcestrator(flowParameter).start();
        }

        Logger.trace(request.contextId, 'Queue.add', 'end', jobStatus);

        return new AddResponse(existingQueue.size() - blockedQueue.size() + 1, jobStatus);
    }

    public static void remove(Set<Id> contextIds) {
        if(contextIds.isEmpty()) {
            throw new ApplicationException(String.format(Label.MissingParameterValue, new List<String> {  'Context Id' } ));
        }

        List<Queue__c> queuedJobs = [SELECT Id, ContextId__c, Status__c FROM Queue__c WHERE ContextId__c IN :contextIds WITH USER_MODE];

        if(!queuedJobs.isEmpty() && queuedJobs[0].Status__c == 'In Progress') {
            throw new ApplicationException(Label.JobInProgress);
        }

        DML.deleteAsSystem(queuedJobs, '');
        List<Event__e> events = new List<Event__e>();

        for(Queue__c queuedJob : queuedJobs) {
            String topicUri = QUEUE_TOPIC_URI + queuedJob.ContextId__c;
            events.add(new Event__e(Topic_Uri__c = topicUri, Payload__c = 'Remove'));
        }

        Eventbus.publish(events);
    }

    public static void remove(Id contextId) {
        Logger.trace(contextId, 'Queue.remove', 'start', null);
        remove(new Set<Id> { contextId });
        Logger.trace(contextId, 'Queue.remove', 'end', null);
    }

    public static void block(Set<Id> contextIds) {
        List<Queue__c> completedJobs = [SELECT Id, Status__c, Resource__c FROM Queue__c WHERE ContextId__c IN :contextIds  AND Status__c = 'In Progress' WITH USER_MODE];

        // Note: ignore a release resource call for an outdated job
        if(completedJobs.isEmpty()) {
            return;
        }

        for(Queue__c queue : completedJobs) {
            queue.Status__c = BLOCKED;
        }

        DML.updateAsSystem(completedJobs, '');
    }

    public static void block(Id contextId) {
        block(new Set<Id>{contextId});
    }

    public static void releaseResource(Set<Id> contextIds) {
        List<Queue__c> completedJobs = [SELECT Id, Status__c, Resource__c, Transaction__c FROM Queue__c WHERE ContextId__c IN :contextIds WITH USER_MODE];

        // Note: ignore a release resource call for an outdated job
        if(completedJobs.isEmpty()) {
            return;
        }

        DML.deleteAsSystem(completedJobs, '');
        Set<String> resources = getResourcesFrom(completedJobs);
        List<Queue__c> allJobs = [
            SELECT Id, ContextId__c, Status__c, Resource__c, Transaction__c
            FROM Queue__c
            WHERE Resource__c IN :resources
            WITH USER_MODE
            ORDER BY CreatedDate ASC
        ];
        List<Queue__c> nextJobs = getNextJobsFor(allJobs, completedJobs);

        if(nextJobs.isEmpty()) {
            return;
        }

        List<Event__e> events = new List<Event__e>();

        for(Queue__c nextJob : nextJobs) {
            String topicUri = QUEUE_TOPIC_URI + nextJob.ContextId__c;
            events.add(new Event__e(Topic_Uri__c = topicUri, Payload__c = 'Execute'));
        }

        Eventbus.publish(events);
    }

    public static void releaseResource(Id contextId) {
        Logger.trace(contextId, 'Queue.releaseResource', 'start', null);
        releaseResource(new Set<Id> { contextId });
        Logger.trace(contextId, 'Queue.releaseResource', 'end', null);
    }

    @InvocableMethod(label='Resume Queue')
    public static void resume(List<ResumeRequest> requests) {
        new ResumeQueue(requests).execute();
    }

    private static List<Queue__c> blockedQueues(List<Queue__c> allQueue, String transactionId) {
        List<Queue__c> result = new List<Queue__c>();

        for(Queue__c queue : allQueue) {
            if(queue.transaction__c == transactionId && queue.Status__c == BLOCKED) {
                result.add(queue);
            }
        }

        return result;
    }

    private with sharing class ResumeQueue implements Queueable, Finalizer, Database.AllowsCallouts {
        private List<ResumeRequest> requests;

        public ResumeQueue(List<ResumeRequest> requests) {
            this.requests = requests;
        }

        @SuppressWarnings('PMD.OperationWithLimitsInLoop')
        public void execute() {
            Integer loopLimit = Math.min(requests.size(), 25);

            for(Integer i = 0; i < loopLimit; i++) {
                ResumeRequest request = requests.remove(0);
                if(Test.isRunningTest()) {
                    resume(request);
                } else {
                    System.enqueueJob(new ResumeQueue(new List<ResumeRequest> {request}));
                }
            }

            if(!requests.isEmpty()) {
                System.enqueueJob(this);
            }
        }

        public void execute(QueueableContext context) {
            ResumeRequest request = requests.remove(0);

            Logger.trace(request.contextId, 'Queue.resume', 'start', request);
            resume(request);
            Logger.trace(request.contextId, 'Queue.resume', 'end', null);

            if(!requests.isEmpty()) {
                System.attachFinalizer(this);
            }
        }

        private void resume(ResumeRequest request) {
            List<Queue__c> queuedJobs = [SELECT Id, Status__c FROM Queue__c WHERE ContextId__c = :request.contextId WITH USER_MODE];

            if(request.action == 'Execute') {
                queuedJobs[0].Status__c = 'In Progress';
                DML.updateAsSystem(queuedJobs, '');
                executeCallback(request.callback, request.payload);
            } else {
                executeCancel(request.callback, request.payload);
            }
        }

        public void execute(FinalizerContext ctx) {
            if(!requests.isEmpty()) {
                new ResumeQueue(requests).execute();
            }
        }

        private void executeCallback(String callbackName, String payload) {
            Type callback = Type.forName(ns(callbackName), localClass(callbackName));
            ((CopadoQueueable) callback.newInstance()).execute(payload);
        }

        private void executeCancel(String callbackName, String payload) {
            Type callback = Type.forName(ns(callbackName), localClass(callbackName));
            ((CopadoQueueable) callback.newInstance()).cancel(payload);
        }
    }

    // PRIVATE

    private static String parseResource(Id contextId, String resource) {
        List<String> dynamicExpressions = dynamicExpressions(resource);
        Logger.info(contextId, 'queue.parseResource, dynamicExpressions', resource, dynamicExpressions);

        if(dynamicExpressions.isEmpty()) {
            return resource;
        }

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(contextId, dynamicExpressions);
        List<Jobs.DynamicExpressionEvaluateResult> responses = new Jobs.DynamicExpression().evaluate(request);

        for(Jobs.DynamicExpressionEvaluateResult response : responses) {
            String value = response.value == null ? '' : response.value;
            resource = resource.replace(response.dynamicExpression, value);
        }
        Logger.info(contextId, 'queue.parseResource, before replace', resource, responses);

        return resource;
    }

    private static List<String> dynamicExpressions(String content) {
        List<String> result = new List<String>();

        Matcher m = TEMPLATE_PATTERN.matcher(content);

        while(m.find()) {
			result.add(m.group());
        }

        return result;
    }


    private static String ns(String callback) {
        return callback.contains('.') ? callback.substringBefore('.') : '';
    }

    private static String localClass(String callback) {
        return callback.contains('.') ? callback.substringAfter('.') : callback;
    }

	private static void assertRequiredParameter(AddRequest request) {
        List<String> errors = new List<String>();
        if(request?.contextId == null) {
            errors.add('Context Id');
        }

        if(String.isBlank(request?.resource)) {
            errors.add('Resource');
        }

        if(request?.callback == null) {
            errors.add('Callback');
        }

        if(!errors.isEmpty()) {
            throw new ApplicationException(String.format(Label.MissingParameterValue, new List<String> { String.join(errors, ', ') } ));
        }
	}

	private static void assertRequiredParameter(Id contextId, String resource) {
        List<String> errors = new List<String>();
        if(contextId == null) {
            errors.add('Context Id');
        }

        if(String.isBlank(resource)) {
            errors.add('Resource');
        }

        if(!errors.isEmpty()) {
            throw new ApplicationException(String.format(Label.MissingParameterValue, new List<String> { String.join(errors, ', ') } ));
        }
	}

    private static Set<String> getResourcesFrom(List<Queue__c> jobs) {
        Set<String> result = new Set<String>();

        for(Queue__c job : jobs) {
            result.add(job.Resource__c);
        }

		return result;
	}

    private static List<Queue__c> getNextJobsFor(List<Queue__c> allJobs, List<Queue__c> completedJobs) {
        Map<String, Queue__c> result = new Map<String, Queue__c>();

        Map<String, String> transactionIdByResource = new Map<String, String>();

        for(Queue__c job : completedJobs) {
            transactionIdByResource.put(job.Resource__c, job.Transaction__c);
        }

        // Note: We give priority to Job with same transaction id over created date here
        for(Queue__c job : allJobs) {
            String relevantTransactionId = transactionIdByResource.get(job.Resource__c);
            if(!result.containsKey(job.Resource__c) && relevantTransactionId == job.Transaction__c) {
                result.put(job.Resource__c, job);
            }
        }

        for(Queue__c job : allJobs) {
            if(!result.containsKey(job.Resource__c)) {
                result.put(job.Resource__c, job);
            }
        }

		return result.values();
	}

    // INNER

    public class AddRequest {
        public Id contextId;
        public String payload;
        public String resource;
        public String contextName;
        public String transactionId;
        public System.Type callback;
    }

    public class AddResponse {
        public Integer position;
        public String status;

        public AddResponse(Integer position, String status) {
            this.position = position;
            this.status = status;
        }
    }

    public class ResumeRequest {
        @InvocableVariable(label='Context Id' description='Context Id of queued job' required=true)
        public Id contextId;
        @InvocableVariable(label='Payload' description='Queued job\'s payload' required=true)
        public String payload;
        @InvocableVariable(label='Callback' description='Class that implements copado.Queable interface' required=true)
        public String callback;
        @InvocableVariable(label='Action' description='Action(Possible values are: Execute, Remove)' required=true)
        public String action;
    }
}