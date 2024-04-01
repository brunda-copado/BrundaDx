public with sharing class RollbackDeploymentService implements DeploymentInterface {
    private String namespace = Settings.ns;
    private static final String C_ID = 'id';
    private static final String METADATA_PRESELECTION_ID = 'MetadataPreselectionId';
    private static final String DELETE_PRESELECTION_ID = 'DeleteMetadataPreselectionId';
    private static final String METADATA = 'MetaData';
    private static final String TESTCLASS_PRESELECTION_ID = 'TestClassPreselectionId';
    private static final String FILENAME_GIT_PROMOTION = 'Selected items to rollback_Git Promotion';
    private static final String FILENAME_DELETE_METADATA = 'Selected items to rollback_Delete Metadata';
    private static final String TEST_CLASSES = 'Test Classes';

    @SuppressWarnings('PMD.FieldNamingConventions')
    private enum PossibleWizardSteps {
        RollbackWizardStart,
        DW_SelectChanges,
        DW_Overview,
        DW_Deployment,
        DW_Summary
    }

    private Map<String, String> stepsPageNameByLabel = new Map<String, String>{
        'RollbackWizardStart' => 'Start',
        'DW_SelectChanges' => 'Select & Compare',
        'DW_Overview' => 'Overview',
        'DW_Deployment' => 'Deployment',
        'DW_Summary' => 'Summary'
    };

    public DeploymentInterface getInstance() {
        return new RollbackDeploymentService();
    }

    public List<String> returnAvailableSteps() {
        List<String> steps = new List<String>();
        for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
            if (stepsPageNameByLabel.containsKey(possibleWizardStepItem.name())) {
                steps.add(stepsPageNameByLabel.get(possibleWizardStepItem.name()));
            }
        }
        return steps;
    }

    public List<String> returnAvailablePages() {
        List<String> pages = new List<String>();
        for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
            pages.add(possibleWizardStepItem.name());
        }
        return pages;
    }

    @SuppressWarnings('PMD.ApexOpenRedirect')
    public PageReference goToNextStep(Deployment__c deployment, String deploymentActionType) {
        PageReference pReference;
        if (deployment.Id != null) {
            Integer currentComponentOrder = 0;
            for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
                if (
                    deployment.Deployment_Last_Step__c != null &&
                    deployment.Deployment_Last_Step__c.containsIgnoreCase(String.valueOf(possibleWizardStepItem))
                ) {
                    currentComponentOrder = possibleWizardStepItem.ordinal();
                    break;
                }
            }
            String newComponentName = String.valueOf(PossibleWizardSteps.values()[currentComponentOrder]);
            String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
            String currentURLHost = Url.getSalesforceBaseUrl().getHost();
            String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
            pReference = new PageReference(newComponentURL);
            pReference.getParameters().put(C_ID, deployment.Id);
            setPageParameters(pReference, deployment);

            if (String.isNotBlank(deploymentActionType)) {
                pReference.getParameters().put('deploymentActionType', deploymentActionType);
            }
        } else {
            pReference = Page.DW_Source;
        }
        pReference.setRedirect(true);
        return pReference;
    }

    @SuppressWarnings('PMD.ApexOpenRedirect')
    public PageReference goToPreviousStep(Deployment__c deployment) {
        PageReference pReference;
        if (deployment.Id != null) {
            Integer currentComponentOrder = 0;
            String currentURL = ApexPages.currentPage().getUrl();
            for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
                if (String.isNotBlank(currentURL) && currentURL.containsIgnoreCase(String.valueOf(possibleWizardStepItem))) {
                    currentComponentOrder = possibleWizardStepItem.ordinal();
                    break;
                }
            }

            Integer order = currentComponentOrder - 1;
            Integer validComponentOrder = (order < 0) ? (order + 1) : order;
            String newComponentName = String.valueOf(PossibleWizardSteps.values()[validComponentOrder]);
            String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
            String currentURLHost = Url.getSalesforceBaseUrl().getHost();
            String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
            pReference = new PageReference(newComponentURL);
            pReference.getParameters().put(C_ID, deployment.Id);
            setPageParameters(pReference, deployment);
            pReference.setRedirect(true);
            return pReference;
        } else {
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            return new PageReference(url);
        }
    }

    private void setPageParameters(PageReference pReference, Deployment__c deployment) {
        String gitPromotionFileId = returnFileIdFromStep(deployment.Id, FILENAME_GIT_PROMOTION);
        if (String.isNotBlank(gitPromotionFileId)) {
            pReference.getParameters().put(METADATA_PRESELECTION_ID, gitPromotionFileId);
        }
        String deleteMetadataFileId = returnFileIdFromStep(deployment.Id, FILENAME_DELETE_METADATA);
        if (String.isNotBlank(deleteMetadataFileId)) {
            pReference.getParameters().put(DELETE_PRESELECTION_ID, deleteMetadataFileId);
        }
        String testclassFileId = returnFileIdFromStep(deployment.Id, TEST_CLASSES);
        if (String.isNotBlank(testclassFileId)) {
            pReference.getParameters().put(TESTCLASS_PRESELECTION_ID, testclassFileId);
        }
    }

    public Integer getComponentIndex(String valueToCheck) {
        Integer currentComponentOrder = 0;
        for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
            if (String.isNotBlank(valueToCheck) && valueToCheck.containsIgnoreCase(String.valueOf(possibleWizardStepItem))) {
                currentComponentOrder = possibleWizardStepItem.ordinal();
            }
        }
        return currentComponentOrder;
    }

    private String returnFileIdFromStep(String deploymentId, String title) {
        List<Step__c> steps = new List<Step__c>();
        try {
            steps = new StepsSelector().byDeploymentIdFilteringTypes(new List<Id>{ deploymentId }, new List<String>{ 'Rollback' });

            Set<Id> contentDocumentIds = new Set<Id>();
            if (!steps.isEmpty()) {
                for (ContentDocumentLink cdl : new ContentDocumentLinksSelector().byLinkedEntityId(new Set<Id>{ steps[0].Id })) {
                    contentDocumentIds.add(cdl.ContentDocumentId);
                }
                if (!contentDocumentIds.isEmpty()) {
                    List<ContentVersion> cvs = new ContentVersionsSelector().byContentDocumentIdFilteringTitles(contentDocumentIds, title);
                    return cvs.isEmpty() ? '' : cvs[0].Id;
                }
            }
        } catch (System.QueryException exceptions) {
            throw new ApplicationException(exceptions.getMessage());
        }
        return '';
    }

    public String getStepGeneralHeader() {
        return Label.RollbackBeta;
    }

    public List<String> getSourceTypeList() {
        return new List<String>();
    }
}