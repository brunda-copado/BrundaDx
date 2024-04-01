public with sharing class AggregateCoverageResult {
    public List<FileCoverageResult> records;

    public Double calculateCoveragePercentage() {
        Double result = 0;

        Integer totalLinesCovered = 0;
        Integer totalLines = 0;

        for (FileCoverageResult classCoverage : records) {
            totalLinesCovered += classCoverage.NumLinesCovered;
            totalLines += classCoverage.NumLinesCovered + classCoverage.NumLinesUncovered;
        }

        if (totalLines > 0) {
            result = ((Double) totalLinesCovered / (Double) totalLines) * 100;
        }

        return result;
    }

    public Integer calculateMetadataFilesWithoutCoverage(Decimal usMinimumCoverage, String metadataType) {
        Integer result = 0;

        for (AggregateCoverageResult.FileCoverageResult fileCoverage : records) {
            if (
                fileCoverage.ApexClassOrTrigger.attributes.url.contains(metadataType) &&
                (fileCoverage.NumLinesCovered + fileCoverage.NumLinesUncovered > 0)
            ) {
                if(fileCoverage.calculateFileCoveragePercentage() < usMinimumCoverage) {
                    result++;
                }
            }
        }

        return result;
    }

    public class FileCoverageResult {
        public Integer NumLinesUncovered; // NOPMD: Suppressing as this and below are mandated by the Apex Tests Json format.
        public Integer NumLinesCovered; // NOPMD
        public ApexClassDto ApexClassOrTrigger; // NOPMD
        public Coverage Coverage; // NOPMD

        public Double calculateFileCoveragePercentage() {
            return ((Double) NumLinesCovered / (Double) (NumLinesCovered + NumLinesUncovered)) * 100;
        }
    }

    public class Coverage {
        public List<Integer> coveredLines;
        public List<Integer> uncoveredLines;
    }

    public class ApexClassDto {
        public String Name; // NOPMD
        public ApexMetadataAttributes attributes;
    }

    public class ApexMetadataAttributes {
        public String url;
        public String type;
    }
}