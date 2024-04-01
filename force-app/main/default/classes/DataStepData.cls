public inherited sharing class DataStepData {
    public String dataTemplateId { get; set; }
    public String dataTemplateName { get; set; }
    public String commitMessage { get; set; }
    public String filterLogic { get; set; }
    public List<QueryEditor.CriteriaWrapper> queryFilterList { get; set; }
    public StepSource source { get; set; }
    public StepDestination destination { get; set; }

    @TestVisible
    private DataStepData() {
    }

    public DataStepData(DataDeployRequest request) {
        if (request.getSourceType() == DataDeployRequest.Source.ENVIRONMENT) {
            this.dataTemplateId = request.getDataTemplateId();
        }
        this.source = new StepSource(request);
        this.destination = new StepDestination(request);

        this.commitMessage = String.isNotBlank(request.getCommitMessage()) ? request.getCommitMessage() : null;

        // if we are overriding the filters and removing all the filters, create dummy filter
        // this will be removed once the backend is adapted to override filters by empty filters
        if (request.getOverrideFilters()) {
            List<DataFilter> dataFilters = request.getFilters();
            String filterLogic = request.getFilterLogic();
            if (dataFilters.isEmpty()) {
                DataFilter dummyDataFilter = createDummyFilter();
                dataFilters.add(dummyDataFilter);
                filterLogic = '1';
            }
            this.queryFilterList = !dataFilters.isEmpty() ? convertFilters(dataFilters) : null;
            this.filterLogic = String.isNotBlank(filterLogic) ? filterLogic : null;
        }
    }

    private DataFilter createDummyFilter() {
        DataFilter result = new DataFilter();
        result.order = 1;
        result.fieldName = 'Id';
        result.fieldType = 'String';
        result.operatorCode = 'n';
        result.value = '';
        return result;
    }

    private List<QueryEditor.CriteriaWrapper> convertFilters(List<DataFilter> filters) {
        // convert DataFilter to CriteriaWrapper (compatibility)
        List<QueryEditor.CriteriaWrapper> result = new List<QueryEditor.CriteriaWrapper>();
        for (DataFilter filter : filters) {
            result.add(filter.toQueryCriteria());
        }
        return result;
    }

    public inherited sharing class StepSource {
        public DataDeployRequest.Source type { get; set; }
        public String id { get; set; }
        public String branchName { get; set; }

        public StepSource() {
        }

        public StepSource(DataDeployRequest request) {
            this.type = request.getSourceType();
            switch on request.getSourceType() {
                when DATASET {
                    this.id = request.getSourceDataSetId();
                }
            }
        }
    }

    public inherited sharing class StepDestination {
        public DataDeployRequest.Destination type { get; set; }
        public String id { get; set; }
        public String branchName { get; set; }

        public StepDestination() {
        }

        public StepDestination(DataDeployRequest request) {
            this.type = request.getDestinationType();
            switch on request.getDestinationType() {
                when DATASET {
                    this.id = request.getDestinationDataSetId();
                }
            }
        }
    }
}