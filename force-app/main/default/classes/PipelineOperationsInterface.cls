public interface PipelineOperationsInterface {
    PipelineManagerExtension.PipelineOperationsServiceJobsResult validation(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    );
    PipelineManagerExtension.PipelineOperationsServiceJobsResult createPromotionAndPromotedUserStories(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    );
    PipelineManagerExtension.PipelineOperationsServiceJobsResult deploy(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    );
    PipelineManagerExtension.PipelineOperationsServiceJobsResult promoteAndDeploy(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    );
}