public with sharing class SprintWallChartController extends ChartController {
    @TestVisible
    private static final String BURNUP_LINE_CHART = 'Line Burnup';
    @TestVisible
    private static final String BURNDOWN_LINE_CHART = 'Line Burndown';

    @AuraEnabled
    public static MappingConfig getMappingConfig(String plannedVelocityField, String actualVelocityField) {
        try {
            Map<String, String> snapshotSprintMapping = getSnapshotSprintMapping();
            MappingConfig config = new MappingConfig();
            if (snapshotSprintMapping.containsKey(plannedVelocityField)) {
                config.sprintPlannedVelocity = snapshotSprintMapping.get(plannedVelocityField);
            }
            if (snapshotSprintMapping.containsKey(actualVelocityField)) {
                config.sprintActualVelocity = snapshotSprintMapping.get(actualVelocityField);
            }
            return config;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void saveChartData(String sprintId, String chartFileName, String chartData) {
        try {
            new Files().upsertFile(sprintId, chartFileName, chartData);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static ChartDataResponse getChartData(String request) {
        try {
            ChartController.ChartDataRequest cdr = (ChartController.ChartDataRequest) JSON.deserialize(
                request,
                ChartController.ChartDataRequest.class
            );
            return new ChartData(cdr).getChartData();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Map<String, String> getSnapshotSprintMapping() {
        Map<String, String> snapshotSprintMapping = new Map<String, String>();
        for (Copado_Setting__mdt copadoSetting : getCopadoSetting()) {
            snapshotSprintMapping.put(SprintSnapshotConstants.SNAPSHOT_PLANNED_VELOCITY, SprintSnapshotConstants.SPRINT_PLANNED_VELOCITY);
            snapshotSprintMapping.put(SprintSnapshotConstants.SNAPSHOT_ACTUAL_VELOCITY, SprintSnapshotConstants.SPRINT_ACTUAL_VELOCITY);

            if (copadoSetting.Enabled__c && String.isNotBlank(copadoSetting.Text_Field__c)) {
                String jsonText = copadoSetting.Text_Field__c;
                Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
                for (String sprintFieldName : fieldMap.keyset()) {
                    snapshotSprintMapping.put((String) fieldMap.get(sprintFieldName), sprintFieldName);
                }
            }
        }
        return snapshotSprintMapping;
    }

    private static List<Copado_Setting__mdt> getCopadoSetting() {
        return [
            SELECT Id, Text_Field__c, Enabled__c
            FROM Copado_Setting__mdt
            WHERE DeveloperName = :SprintSnapshotConstants.SPRINT_TO_SNAPSHOT_FIELD_MAPPING
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    @SuppressWarnings(
        'PMD.CognitiveComplexity, PMD.StdCognitiveComplexity, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity, PMD.FieldNamingConventions, PMD.ExcessiveParameterList'
    )
    private with sharing class ChartData {
        private final String QUERY_TEMPLATE = 'SELECT {0} FROM {1} WHERE {2} = \'\'{3}\'\' WITH SECURITY_ENFORCED LIMIT {4}';
        private final String WHERE_CLAUSE = 'Sprint__c = \'\'{0}\'\' AND CreatedDate >= {1} AND CreatedDate <= {2} WITH SECURITY_ENFORCED';
        private final String RECORD_LIMIT = '1';
        private final String ID_FIELD = Schema.SObjectType.Sprint__c.fields.Id.getName();
        private final String SPRINT_OBJECT = Schema.SObjectType.Sprint__c.getName();
        private Set<String> sprintFields = new Set<String>{
            Schema.SObjectType.Sprint__c.fields.Id.getName(),
            Schema.SObjectType.Sprint__c.fields.Name.getName(),
            Schema.SObjectType.Sprint__c.fields.Start_Date__c.getName(),
            Schema.SObjectType.Sprint__c.fields.End_Date__c.getName(),
            Schema.SObjectType.Sprint__c.fields.InitialPlannedVelocity__c.getName(),
            Schema.SObjectType.Sprint__c.fields.Status__c.getName()
        };
        private final String SNAPSHOT_OBJECT = Schema.SObjectType.Burndown_Item__c.getName();
        private Set<String> snapshotFields = new Set<String>{
            Schema.SObjectType.Burndown_Item__c.fields.Id.getName(),
            Schema.SObjectType.Burndown_Item__c.fields.Sprint__c.getName(),
            Schema.SObjectType.Burndown_Item__c.fields.Snapshot_Date__c.getName()
        };
        private Map<String, String> snapshotVelocityFields = new Map<String, String>();
        private Map<String, String> sprintVelocityFields = new Map<String, String>();
        private ChartDataRequest request;

        private ChartData(ChartDataRequest request) {
            this.snapshotVelocityFields = getSnapshotVelocityFieldsFromRequest(request);
            this.sprintVelocityFields = getSprintVelocityFieldsFromRequest(request);
            this.sprintFields.addAll(sprintVelocityFields.values());
            this.request = request;
        }

        private ChartDataResponse getChartData() {
            ChartDataResponse result = new ChartDataResponse();

            List<Sprint__c> sprints = Database.query(getFormattedQuery());

            if (sprints == null || sprints.isEmpty() || sprints.size() <> 1) {
                throw new ApplicationException(System.Label.Sprint_Size_Exception_Message);
            }

            Sprint__c sprint = sprints[0];
            result.xAxisValues = getPlottingDates(sprint);

            if (sprint.Status__c == 'Completed') {
                result.chartDataJson = getChartDataFromFile();
                if (String.isNotEmpty(result.chartDataJson)) {
                    return result;
                }
            }

            result.chartDataJson = getChartDataJson(sprint, result.xAxisValues);
            return result;
        }

        private Map<String, String> getSnapshotVelocityFieldsFromRequest(ChartDataRequest cdr) {
            return new Map<String, String>{
                'plannedVelocity' => String.escapeSingleQuotes(cdr.plannedVelocityField),
                'actualVelocity' => String.escapeSingleQuotes(cdr.actualVelocityField)
            };
        }

        private Map<String, String> getSprintVelocityFieldsFromRequest(ChartDataRequest cdr) {
            return new Map<String, String>{
                'plannedVelocity' => String.escapeSingleQuotes(cdr.sprintPlannedVelocityField),
                'actualVelocity' => String.escapeSingleQuotes(cdr.sprintActualVelocityField)
            };
        }

        private String getFormattedQuery() {
            return String.format(
                QUERY_TEMPLATE,
                new List<String>{
                    String.join(new List<String>(this.sprintFields), ','),
                    this.SPRINT_OBJECT,
                    this.ID_FIELD,
                    String.escapeSingleQuotes(this.request.objectId),
                    RECORD_LIMIT
                }
            );
        }

        private String[] getPlottingDates(Sprint__c sprint) {
            String[] result = new List<String>{};
            Date startDate = sprint.Start_Date__c;
            Date endDate = sprint.End_Date__c;
            while (startDate <= endDate) {
                Integer weekDay = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(startDate), 7);
                if (weekday != 0 && weekday != 6) {
                    result.add(startDate.format());
                }
                startDate = startDate.addDays(1);
            }
            return result;
        }

        @TestVisible
        private String getChartDataFromFile() {
            ContentDocumentLink[] cdls = [
                SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :this.request.objectId
                WITH SECURITY_ENFORCED
            ];

            if (cdls == null || cdls.isEmpty()) {
                return '';
            }

            Set<String> contentDocumentIds = new Set<String>();
            for (ContentDocumentLink cdl : cdls) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }

            ContentVersion[] cvs = [
                SELECT Id, ContentDocumentId, ContentBodyId, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds AND PathOnClient = :this.request.chartFileName
                WITH SECURITY_ENFORCED
            ];

            return cvs == null || cvs.isEmpty() ? '' : cvs[0].VersionData.toString();
        }

        private String getChartDataJson(Sprint__c sprint, List<String> dates) {
            Map<String, Map<String, String>> velocitiesByDate = getVelocitiesByDate(
                SprintSnapshotRecordsCollector.getTrackedHistoryTrending(prepareSprintSnapshotRequest(sprint)),
                this.request.type,
                sprint
            );
            Decimal idealPlannedVelocity = getIdealPlannedPoints(sprint, dates.size());
            Decimal plannedVelocity = null;

            return this.request.type == BURNUP_LINE_CHART
                ? createBurnUpChartDataJson(plannedVelocity, idealPlannedVelocity, dates, velocitiesByDate)
                : createBurnDownChartDataJson(
                      (Decimal) sprint.get(sprintVelocityFields.get('plannedVelocity')),
                      idealPlannedVelocity,
                      dates,
                      velocitiesByDate
                  );
        }

        private Map<String, Map<String, String>> getVelocitiesByDate(
            List<SprintSnapshotRecordsCollector.SprintSnapshotResponse> response,
            String type,
            Sprint__c sprint
        ) {
            Map<String, String> plannedVelocityByDate = new Map<String, String>();
            Map<String, String> actualVelocityByDate = new Map<String, String>();

            String formattedDate = (response == null || response.isEmpty()) ? sprint.Start_Date__c.format() : Date.today().format();
            plannedVelocityByDate.put(formattedDate, String.valueOf(sprint.get(sprintVelocityFields.get('plannedVelocity'))));
            actualVelocityByDate.put(formattedDate, String.valueOf(sprint.get(sprintVelocityFields.get('actualVelocity'))));


            // Use data from Snapshot Collector to read previous information for previous dates
            for (SprintSnapshotRecordsCollector.SprintSnapshotResponse sprintHistory : response) {
                formattedDate = sprintHistory?.snapshotDate?.format();

                if (Date.today() != sprintHistory?.snapshotDate) {
                    for (SprintSnapshotRecordsCollector.SnapshotFieldResponse fieldResponse : sprintHistory.snapshotFields) {
                        if (fieldResponse.fieldName == snapshotVelocityFields.get('plannedVelocity')) {
                            plannedVelocityByDate.put(formattedDate, fieldResponse.value != null ? String.valueof(fieldResponse.value) : null);
                        } else if (fieldResponse.fieldName == snapshotVelocityFields.get('actualVelocity')) {
                            actualVelocityByDate.put(formattedDate, fieldResponse.value != null ? String.valueof(fieldResponse.value) : null);
                        }
                    }
                }
            }
            return new Map<String, Map<String, String>>{
                'plannedVelocityByDate' => plannedVelocityByDate,
                'actualVelocityByDate' => actualVelocityByDate,
                'pendingVelocityByDate' => type == BURNDOWN_LINE_CHART ? preparePendingPointsMaps(plannedVelocityByDate, actualVelocityByDate) : null
            };
        }

        private Decimal getIdealPlannedPoints(Sprint__c sprint, Integer totalNumberOfDates) {
            Decimal plannedVelocity = (Decimal) sprint.get(sprintVelocityFields.get('plannedVelocity'));
            return plannedVelocity != null ? plannedVelocity / totalNumberOfDates : 0;
        }

        private String createBurnUpChartDataJson(
            Decimal plannedVelocity,
            Decimal idealPlannedVelocity,
            List<String> dates,
            Map<String, Map<String, String>> velocitiesByDate
        ) {
            ChartDataResponseElement[] completedPoints = new List<ChartDataResponseElement>{};
            ChartDataResponseElement[] plannedPoints = new List<ChartDataResponseElement>{};
            String previousPlannedPoints = String.valueOf(plannedVelocity);
            String previousActualPoints = '0';
            String currentPlannedPoints;
            String currentActualPoints = null;

            for (String dateString : dates) {
                currentActualPoints = getVelocityByDate(dateString, velocitiesByDate.get('actualVelocityByDate'), previousActualPoints, false);
                currentPlannedPoints = getVelocityByDate(dateString, velocitiesByDate.get('plannedVelocityByDate'), previousPlannedPoints, true);

                completedPoints.add(new ChartDataResponseElement(dateString, currentActualPoints));
                plannedPoints.add(new ChartDataResponseElement(dateString, currentPlannedPoints));

                previousActualPoints = currentActualPoints;
                previousPlannedPoints = currentPlannedPoints;
            }

            return JSON.serialize(new List<ChartDataResponseElement[]>{ completedPoints, plannedPoints });
        }

        private String createBurnDownChartDataJson(
            Decimal plannedVelocity,
            Decimal idealPlannedVelocity,
            List<String> dates,
            Map<String, Map<String, String>> velocitiesByDate
        ) {
            ChartDataResponseElement[] pendingPoints = new List<ChartDataResponseElement>{};
            ChartDataResponseElement[] burndownIdealPoints = new List<ChartDataResponseElement>{};
            Decimal idealPlottingValue = plannedVelocity;

            String previousPendingPoints;
            String currentPendingPoints;

            for (String dateString : dates) {
                if (idealPlottingValue != null) {
                    idealPlottingValue -= idealPlannedVelocity;
                    if (idealPlottingValue < 0) {
                        idealPlottingValue = 0;
                    }
                }

                currentPendingPoints = getVelocityByDate(dateString, velocitiesByDate.get('pendingVelocityByDate'), previousPendingPoints, false);
                pendingPoints.add(new ChartDataResponseElement(dateString, currentPendingPoints));
                previousPendingPoints = currentPendingPoints;
                burndownIdealPoints.add(new ChartDataResponseElement(dateString, String.valueOf(idealPlottingValue)));
            }

            return JSON.serialize(new List<ChartDataResponseElement[]>{ pendingPoints, burndownIdealPoints });
        }

        private Map<String, String> preparePendingPointsMaps(Map<String, String> plannedVelocityByDate, Map<String, String> actualVelocityByDate) {
            Map<String, String> result = new Map<String, String>();
            Decimal plannedPoints;
            Decimal actualPoints;
            for (String dateString : plannedVelocityByDate.keyset()) {
                if (String.isNotEmpty(plannedVelocityByDate.get(dateString))) {
                    plannedPoints = Decimal.valueOf(plannedVelocityByDate.get(dateString));
                    actualPoints = actualVelocityByDate.get(dateString) != null ? Decimal.valueOf(actualVelocityByDate.get(dateString)) : 0;
                    result.put(dateString, String.valueOf(plannedPoints - actualPoints));
                }
            }
            return result;
        }

        private String getVelocityByDate(
            String dateString,
            Map<String, String> plannedVelocityByDate,
            String previousPlannedVelocity,
            Boolean calculateForFuture
        ) {
            Date d = Date.parse(dateString);
            if (!calculateForFuture && d > Date.today()) {
                return null;
            }

            return plannedVelocityByDate.get(dateString) != null ? plannedVelocityByDate.get(dateString) : previousPlannedVelocity;
        }

        private SprintSnapshotRecordsCollector.SprintSnapshotRequest prepareSprintSnapshotRequest(Sprint__c sprint) {
            SprintSnapshotRecordsCollector.SprintSnapshotRequest request = new SprintSnapshotRecordsCollector.SprintSnapshotRequest();
            request.objectId = sprint.id;
            request.objectName = SNAPSHOT_OBJECT;
            request.fields = new Set<String>(snapshotFields);
            request.fields.addAll(snapshotVelocityFields.values());

            if (sprint.Start_Date__c != null && sprint.End_Date__c != null) {
                request.filterClause = String.format(
                    WHERE_CLAUSE,
                    new List<String>{
                        sprint.id,
                        applyStringFormatToDateTime(sprint.Start_Date__c),
                        applyStringFormatToDateTime(sprint.End_Date__c.addDays(1))
                    }
                );
            }
            return request;
        }

        private String applyStringFormatToDateTime(DateTime dateTimeInput) {
            return dateTimeInput.formatGMT('yyyy-MM-dd\'T\'HH:mm:ssZ');
        }
    }

    public class MappingConfig {
        @AuraEnabled
        public String sprintPlannedVelocity { get; set; }
        @AuraEnabled
        public String sprintActualVelocity { get; set; }
    }
}