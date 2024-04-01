public with sharing class ApexCoverageService {
    // PUBLIC

    public AggregateCoverageResult queryResults(String credentialId, String userStoryId, String testClassNames) {
        AggregateCoverageResult result;

        String apexMetadataExcludingTests = getUserStoryApexFilesExcludingTests(userStoryId, testClassNames);

        if (String.isNotBlank(apexMetadataExcludingTests)) {
            AggregateCoverageResult coverageByTestMethods = queryCoverageByExecutedTestMethod(
                credentialId,
                apexMetadataExcludingTests,
                testClassNames
            );

            result = aggregateByApexFile(coverageByTestMethods);

            AggregateCoverageResult globalCoverageByClass = queryGlobalCoverageByApexFile(credentialId, apexMetadataExcludingTests);
            result = addClassesWithoutCoverage(result, globalCoverageByClass);
        }

        return result;
    }

    // PRIVATE

    private String getUserStoryApexFilesExcludingTests(String userStoryId, String testClassNames) {
        String result = '';

        String classType = 'ApexClass';
        String triggerType = 'ApexTrigger';

        List<Metadata> metadataFiles = getMetadataFilesFrom(userStoryId);

        for (Metadata metadata : metadataFiles) {
            if ((metadata.t == classType || metadata.t == triggerType) && !testClassNames.split(',').contains(metadata.n)) {
                result += '\'' + metadata.n + '\',';
            }
        }

        for (User_Story_Metadata__c usMetadata : new UserStoryMetadataSelector().byUserStoryId(userStoryId)) {
            if (
                (usMetadata.Type__c == classType || usMetadata.Type__c == triggerType) &&
                !testClassNames.split(',').contains(usMetadata.Metadata_API_Name__c)
            ) {
                result += '\'' + usMetadata.Metadata_API_Name__c + '\',';
            }
        }

        result = result.removeEnd(',');

        return result;
    }

    private List<Metadata> getMetadataFilesFrom(Id userStoryId) {
        List<Metadata> result = new List<Metadata>();

        List<Attachment> metadataAttachments = new AttachmentsSelector()
            .byParentIdAndName(new Set<Id>{ userStoryId }, new Set<String>{ 'MetaData', 'Git MetaData' });

        for (Attachment metadataAttachment : metadataAttachments) {
            result.addAll((List<Metadata>) JSON.deserialize(metadataAttachment.Body.toString(), List<Metadata>.class));
        }

        return result;
    }

    private AggregateCoverageResult queryCoverageByExecutedTestMethod(String credentialId, String apexMetadataExcludingTests, String testClassNames) {
        String queryMethodCoverage =
            'SELECT+ApexClassOrTrigger.Name,NumLinesCovered,NumLinesUncovered,Coverage+FROM+ApexCodeCoverage' +
            '+WHERE+ApexClassOrTrigger.Name+IN+(' +
            apexMetadataExcludingTests +
            ')' +
            '+AND+ApexTestClass.Name+IN+(' +
            shapeStringListForQuery(testClassNames) +
            ')';

        SalesforceAPIProxyResponse responseCoverageByTestMethods = queryOrg(
            'Get Class Coverage By Executed Tests',
            queryMethodCoverage,
            credentialId
        );
        return (AggregateCoverageResult) JSON.deserialize(responseCoverageByTestMethods.content, AggregateCoverageResult.class);
    }

    private String shapeStringListForQuery(String testClassNames) {
        String result = '';

        List<String> testClassNamesList = testClassNames.split(',');

        for (String testClassName : testClassNamesList) {
            result += '\'' + testClassName + '\',';
        }

        result = result.removeEnd(',');

        return result;
    }

    private AggregateCoverageResult aggregateByApexFile(AggregateCoverageResult coverageByTestMethods) {
        AggregateCoverageResult result = new AggregateCoverageResult();
        result.records = new List<AggregateCoverageResult.FileCoverageResult>();

        Map<String, AggregateCoverageResult.Coverage> coverageByApexFile = getCoverageByApexFile(coverageByTestMethods);
        Map<String, String> metadataTypeByFileName = getMetadataTypesByFilename(coverageByTestMethods);

        for (String classOrTriggerName : coverageByApexFile.keySet()) {
            AggregateCoverageResult.FileCoverageResult apexFileCoverage = consolidateApexFileCoverage(
                coverageByApexFile,
                classOrTriggerName,
                metadataTypeByFileName.get(classOrTriggerName)
            );
            result.records.add(apexFileCoverage);
        }

        return result;
    }

    private Map<String, AggregateCoverageResult.Coverage> getCoverageByApexFile(AggregateCoverageResult coverageByTestMethods) {
        Map<String, AggregateCoverageResult.Coverage> result = new Map<String, AggregateCoverageResult.Coverage>();

        for (AggregateCoverageResult.FileCoverageResult methodCoverageResult : coverageByTestMethods.records) {
            AggregateCoverageResult.Coverage methodCoverage = result.get(methodCoverageResult.ApexClassOrTrigger.Name);

            if (methodCoverage == null) {
                methodCoverage = new AggregateCoverageResult.Coverage();

                methodCoverage.coveredLines = methodCoverageResult.Coverage.coveredLines;
                methodCoverage.uncoveredLines = methodCoverageResult.Coverage.uncoveredLines;
            } else {
                for (Integer newCoveredLine : methodCoverageResult.Coverage.coveredLines) {
                    if (!methodCoverage.coveredLines.contains(newCoveredLine)) {
                        methodCoverage.coveredLines.add(newCoveredLine);
                        methodCoverage.uncoveredLines.remove(methodCoverage.uncoveredLines.indexOf(newCoveredLine));
                    }
                }
            }

            result.put(methodCoverageResult.ApexClassOrTrigger.Name, methodCoverage);
        }

        return result;
    }

    private Map<String, String> getMetadataTypesByFilename(AggregateCoverageResult coverageByTestMethods) {
        Map<String, String> result = new Map<String, String>();

        for (AggregateCoverageResult.FileCoverageResult methodCoverageResult : coverageByTestMethods.records) {
            String metadataType = methodCoverageResult.ApexClassOrTrigger.attributes.url.contains('ApexClass') ? 'ApexClass' : 'ApexTrigger';
            result.put(methodCoverageResult.ApexClassOrTrigger.Name, metadataType);
        }

        return result;
    }

    private AggregateCoverageResult.FileCoverageResult consolidateApexFileCoverage(
        Map<String, AggregateCoverageResult.Coverage> coverageByApexFile,
        String fileName,
        String metadataType
    ) {
        AggregateCoverageResult.FileCoverageResult result = new AggregateCoverageResult.FileCoverageResult();

        result.NumLinesCovered = coverageByApexFile.get(fileName).coveredLines.size();
        result.NumLinesUncovered = coverageByApexFile.get(fileName).uncoveredLines.size();
        result.ApexClassOrTrigger = new AggregateCoverageResult.ApexClassDto();
        result.ApexClassOrTrigger.Name = fileName;
        result.ApexClassOrTrigger.attributes = new AggregateCoverageResult.ApexMetadataAttributes();
        result.ApexClassOrTrigger.attributes.type = metadataType;
        result.ApexClassOrTrigger.attributes.url = metadataType;

        return result;
    }

    private AggregateCoverageResult queryGlobalCoverageByApexFile(String credentialId, String apexMetadataExcludingTests) {
        String queryClassCoverage =
            'SELECT+ApexClassOrTrigger.Name,NumLinesCovered,NumLinesUncovered+FROM+ApexCodeCoverageAggregate' +
            '+WHERE+ApexClassOrTrigger.Name+IN+(' +
            apexMetadataExcludingTests +
            ')';

        SalesforceAPIProxyResponse responseGlobalCoverageByClass = queryOrg(
            'Get Global Aggregated Coverage By Apex File',
            queryClassCoverage,
            credentialId
        );
        return (AggregateCoverageResult) JSON.deserialize(responseGlobalCoverageByClass.content, AggregateCoverageResult.class);
    }

    private AggregateCoverageResult addClassesWithoutCoverage(
        AggregateCoverageResult customAggregate,
        AggregateCoverageResult globalCoverageByClass
    ) {
        AggregateCoverageResult result = customAggregate;

        for (AggregateCoverageResult.FileCoverageResult classCoverage : globalCoverageByClass.records) {
            String metadataItemName = classCoverage.ApexClassOrTrigger.Name;

            Boolean isCoveredByProvidedTests = false;
            for (AggregateCoverageResult.FileCoverageResult existingClassCoverage : customAggregate.records) {
                if (existingClassCoverage.ApexClassOrTrigger.Name == metadataItemName) {
                    isCoveredByProvidedTests = true;
                }
            }

            if (!isCoveredByProvidedTests) {
                // Note: since globalCoverageByClass is per all test classes and in this case it is not covered by any provided test class, we only want to retrieve the coverable lines from the global coverage.
                classCoverage.NumLinesUncovered = classCoverage.NumLinesCovered + classCoverage.NumLinesUncovered;
                classCoverage.NumLinesCovered = 0;

                result.records.add(classCoverage);
            }
        }

        return result;
    }

    public static SalesforceAPIProxyResponse queryOrg(String queryIdentifier, String query, String credentialId) {
        String toolingApiPath = '/services/data/v52.0/tooling';
        String queryPath = '/query/?q=';

        SalesforceAPIProxyRequest proxyPayload = new SalesforceAPIProxyRequest(toolingApiPath + queryPath + query, credentialId)
            .logLabelIdentifier(queryIdentifier);

        return (SalesforceAPIProxyResponse) new SalesforceAPIProxyCallout()
            .default()
            .body(proxyPayload)
            .request()
            .type(SalesforceAPIProxyResponse.class)
            .parseResponse();
    }

    // INNER CLASSES

    public class Metadata {
        String t;
        String n;
    }
}