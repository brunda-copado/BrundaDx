public with sharing class ApexTestRunResult {
    public List<TestMethodResult> records;

    private static final String FAILURE = 'Fail';

    public Integer getNumberOfFailures() {
        Integer result = 0;

        for (TestMethodResult testMethodResult : records) {
            if (testMethodResult.Outcome == FAILURE) {
                result++;
            }
        }

        return result;
    }

    public Integer getTotalExecutionTime() {
        Integer result = 0;

        for (TestMethodResult testMethodResult : records) {
            result += testMethodResult.RunTime;
        }

        return result;
    }

    // INNER CLASSES
    public class TestMethodResult {
        public String Message; // NOPMD: Suppressing as this and below are mandated by the Apex Tests Json format.
        public Integer RunTime; // NOPMD
        public String Outcome; // NOPMD
        public String MethodName; // NOPMD
        public ApexClassDto ApexClass; // NOPMD
    }

    public class ApexClassDto {
        public String Name; // NOPMD
        public ApexMetadataAttributes attributes;
    }

    class ApexMetadataAttributes {
        public String url;
        public String type;
    }
}