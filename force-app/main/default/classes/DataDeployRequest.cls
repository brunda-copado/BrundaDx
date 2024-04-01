public with sharing class DataDeployRequest {
    public enum Source {
        ENVIRONMENT,
        DATASET,
        BRANCH
    }

    public enum Destination {
        ENVIRONMENT,
        DATASET,
        BRANCH
    }

    private static final Map<String, Source> SOURCE_BY_NAME = new Map<String, Source>{
        Source.ENVIRONMENT.name() => Source.ENVIRONMENT,
        Source.DATASET.name() => Source.DATASET,
        Source.BRANCH.name() => Source.BRANCH
    };

    private static final Map<String, Destination> DESTINATION_BY_NAME = new Map<String, Destination>{
        Destination.ENVIRONMENT.name() => Destination.ENVIRONMENT,
        Destination.DATASET.name() => Destination.DATASET,
        Destination.BRANCH.name() => Destination.BRANCH
    };

    private Id dataTemplateId;
    private DataDeployRequest.Source sourceType;
    private DataDeployRequest.Destination destinationType;
    private Id sourceCredentialId;
    private Id destinationCredentialId;
    private Id sourceDataSetId;
    private Id destinationDataSetId;
    private String sourceBranchName;
    private String destinationBranchName;
    private Boolean deployNow;
    private String commitMessage;
    private Boolean overrideFilters;
    private List<DataFilter> filters;
    private String filterLogic;

    public DataDeployRequest() {
        this.deployNow = false;
        this.overrideFilters = false;
        this.filters = new List<DataFilter>();
    }

    public Id getDataTemplateId() {
        return this.dataTemplateId;
    }

    public DataDeployRequest dataTemplateId(Id dataTemplateId) {
        this.dataTemplateId = dataTemplateId;
        return this;
    }

    public DataDeployRequest.Source getSourceType() {
        return this.sourceType;
    }

    public DataDeployRequest sourceType(String sourceType) {
        this.sourceType = sourceTypeFromString(sourceType);
        return this;
    }

    public DataDeployRequest sourceType(DataDeployRequest.Source sourceType) {
        this.sourceType = sourceType;
        return this;
    }

    public DataDeployRequest.Destination getDestinationType() {
        return this.destinationType;
    }

    public DataDeployRequest destinationType(String destinationType) {
        this.destinationType = destinationTypeFromString(destinationType);
        return this;
    }

    public DataDeployRequest destinationType(DataDeployRequest.Destination destinationType) {
        this.destinationType = destinationType;
        return this;
    }

    public Id getSourceCredentialId() {
        return this.sourceCredentialId;
    }

    public DataDeployRequest sourceCredentialId(Id sourceCredentialId) {
        this.sourceCredentialId = sourceCredentialId;
        return this;
    }

    public Id getDestinationCredentialId() {
        return this.destinationCredentialId;
    }

    public DataDeployRequest destinationCredentialId(Id destinationCredentialId) {
        this.destinationCredentialId = destinationCredentialId;
        return this;
    }

    public Id getSourceDataSetId() {
        return this.sourceDataSetId;
    }

    public DataDeployRequest sourceDataSetId(Id sourceDataSetId) {
        this.sourceDataSetId = sourceDataSetId;
        return this;
    }

    public Id getDestinationDataSetId() {
        return this.destinationDataSetId;
    }

    public DataDeployRequest destinationDataSetId(Id destinationDataSetId) {
        this.destinationDataSetId = destinationDataSetId;
        return this;
    }

    public String getSourceBranchName() {
        return this.sourceBranchName;
    }

    public DataDeployRequest sourceBranchName(String sourceBranchName) {
        this.sourceBranchName = sourceBranchName;
        return this;
    }

    public String getDestinationBranchName() {
        return this.destinationBranchName;
    }

    public DataDeployRequest destinationBranchName(String destinationBranchName) {
        this.destinationBranchName = destinationBranchName;
        return this;
    }

    public Boolean getDeployNow() {
        return this.deployNow;
    }

    public DataDeployRequest deployNow(Boolean deployNow) {
        this.deployNow = deployNow;
        return this;
    }

    public String getCommitMessage() {
        return this.commitMessage;
    }

    public DataDeployRequest commitMessage(String commitMessage) {
        this.commitMessage = commitMessage;
        return this;
    }

    public Boolean getOverrideFilters() {
        return this.overrideFilters;
    }

    public DataDeployRequest overrideFilters(Boolean overrideFilters) {
        this.overrideFilters = overrideFilters;
        return this;
    }

    public List<DataFilter> getFilters() {
        return this.filters;
    }

    public DataDeployRequest filters(List<DataFilter> filters) {
        if (filters != null) {
            this.filters = filters;
        }
        return this;
    }

    public String getFilterLogic() {
        return this.filterLogic;
    }

    public DataDeployRequest filterLogic(String filterLogic) {
        this.filterLogic = filterLogic;
        return this;
    }

    @TestVisible
    private static Source sourceTypeFromString(String value) {
        return SOURCE_BY_NAME.get(value);
    }

    @TestVisible
    private static Destination destinationTypeFromString(String value) {
        return DESTINATION_BY_NAME.get(value);
    }
}