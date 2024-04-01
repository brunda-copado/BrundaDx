public with sharing class DataCommitRequest {
    public enum Source {
        ENVIRONMENT,
        DATASET
    }

    private static final Map<String, Source> SOURCE_BY_NAME = new Map<String, Source>{
        Source.ENVIRONMENT.name() => Source.ENVIRONMENT,
        Source.DATASET.name() => Source.DATASET
    };

    private Id userStoryId;
    private DataCommitRequest.Source sourceType;
    private Id dataTemplateId;
    private Id dataSetId;
    private String commitMessage;
    private List<DataFilter> filters;
    private String filterLogic;

    public DataCommitRequest() {
        filters = new List<DataFilter>();
    }

    public Id getUserStoryId() {
        return this.userStoryId;
    }

    public DataCommitRequest userStoryId(Id userStoryId) {
        this.userStoryId = userStoryId;
        return this;
    }

    public DataCommitRequest.Source getSourceType() {
        return this.sourceType;
    }

    public DataCommitRequest sourceType(String sourceType) {
        return sourceType(sourceTypeFromString(sourceType));
    }

    public DataCommitRequest sourceType(DataCommitRequest.Source sourceType) {
        this.sourceType = sourceType;
        return this;
    }

    public Id getDataTemplateId() {
        return this.dataTemplateId;
    }

    public DataCommitRequest dataTemplateId(Id dataTemplateId) {
        this.dataTemplateId = dataTemplateId;
        return this;
    }

    public Id getDataSetId() {
        return this.dataSetId;
    }

    public DataCommitRequest dataSetId(Id dataSetId) {
        this.dataSetId = dataSetId;
        return this;
    }

    public String getCommitMessage() {
        return this.commitMessage;
    }

    public DataCommitRequest commitMessage(String commitMessage) {
        this.commitMessage = commitMessage;
        return this;
    }

    public List<DataFilter> getFilters() {
        return this.filters;
    }

    public DataCommitRequest filters(List<DataFilter> filters) {
        if (filters != null) {
            this.filters = filters;
        }
        return this;
    }

    public String getFilterLogic() {
        return this.filterLogic;
    }

    public DataCommitRequest filterLogic(String filterLogic) {
        this.filterLogic = filterLogic;
        return this;
    }

    @TestVisible
    private static Source sourceTypeFromString(String value) {
        return SOURCE_BY_NAME.get(value);
    }
}