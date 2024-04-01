/**
 * Resolve Conflicts Controller
 * Allows users to mark conflicted files in a promotion as AUTO RESOLVED or RESOLVED
 * When marked as AUTO RESOLVED, the Copado backend will auto resolve the component.
 * When marked as RESOLVED, the Copado backend will merge the file as it was saved by the user.
 * @see ResolveConflicts.page
 * @version 1.0
 * @author David VENEGAS
 * @version 1.1
 * @author Umit Can Uckan
 * @version 1.2
 * @author Pranjal SINGH
 * @version 1.3
 * @author Umit Can Uckan
 * @description attachments query body removal and query addition when body is needed for the given id(s)
 */
@SuppressWarnings('PMD')
public with sharing class ResolveConflictsController {
    public String preDefinedAttSource { get; set; }
    public String preDefinedAttTarget { get; set; }
    public Promotion__c promotion { get; set; }
    public List<Attachment> attachments = new List<Attachment>();
    public Attachment attachmentToResolve { get; set; }
    public String jsonStr { get; set; }
    public List<Attachment> attConflictFileDelete = new List<Attachment>();
    public List<Attachment> attachmentsToResolve {
        get {
            if (attachmentsToResolve == null) {
                attachmentsToResolve = new List<Attachment>();
            }
            return attachmentsToResolve;
        }
        set;
    }
    public Boolean goToPromotion { get; set; }
    public Boolean showHeader { get; set; }
    public List<Attachment> gitRepoConflictFile = new List<Attachment>();
    public Boolean disableAutoResolve {
        get {
            Personal_Settings__c settings = Personal_Settings__c.getInstance();
            return settings != null ? settings.Disable_Auto_Resolve__c : false;
        }
    }
    public String namespace { get; set; }
    public List<String> outOfPromotionMetadataAttachmentIds { get; set; }
    public String excludedMetadataAttachmentIds {
        get {
            if (String.isBlank(excludedMetadataAttachmentIds) && null != outOfPromotionMetadataAttachmentIds) {
                excludedMetadataAttachmentIds = String.join(outOfPromotionMetadataAttachmentIds, ',');
            }
            return excludedMetadataAttachmentIds;
        }
        set;
    }
    public Map<String, String> attachmentTypeMap;
    public List<AttachmentWrapper> attachmentWrapper { get; set; }
    public String userStoryForSmartConflict;
    public String attachmentName { get; set; }
    public static final String COMMIT_CONTENT = 'Not in Promotion Metadata';
    public static final String BIT_BUCKET = 'Bitbucket';
    public static final String MICROSOFT_TEAM_SERVICE = 'Microsoft Team Service';

    /**
     * constructor
     * @return [description]
     */
    public ResolveConflictsController() {
        attachments = new List<Attachment>();
        attachmentToResolve = null;
        goToPromotion = false;
        namespace = Settings.ns;
        outOfPromotionMetadataAttachmentIds = new List<String>();
        attachmentTypeMap = populateAttachmentTypeMap();
        attachmentWrapper = new List<AttachmentWrapper>();
        userStoryForSmartConflict = '';
        attachmentName = '';

        // Get URL promotionId parameter
        String promotionId = ApexPages.currentPage().getParameters().get('promotionId');
        if (String.isBlank(promotionId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CONFLICT_RESOLUTION_NO_PROMOTION));
            return;
        }
        // get promotion values
        try {
            String query = 'SELECT ';
            for (Schema.FieldSetMember field : this.getHeaderFields()) {
                String fieldPath = field.getFieldPath();
                if (fieldPath != 'Name') {
                    query += fieldPath + ', ';
                }
            }
            query += ' Name, Platform__c ,(SELECT Name FROM Deployments__r WHERE Promotion__c != null), Project__r.Deployment_Flow__r.Git_Repository__r.Branch_Base_URL__c,Project__r.Deployment_Flow__r.Git_Repository__c,Project__r.Deployment_Flow__r.Git_Repository__r.Git_Provider__c,Project__r.Deployment_Flow__r.Git_Repository__r.Tag_Base_URL__c FROM Promotion__c WHERE Id =:promotionId WITH SECURITY_ENFORCED LIMIT 1';
            promotion = Database.query(query);
        } catch (Exception excp) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, excp.getMessage()));
        }
    }

    public List<Schema.FieldSetMember> getHeaderFields() {
        List<Schema.FieldSetMember> fields = SObjectType.Promotion__c.FieldSets.Copado_Header_Fields.getFields();
        return fields;
    }

    /**
     *  Called by an apex:repeat in the page.
     */
    public List<AttachmentWrapper> getAttachments() {
        if (promotion == null || !attachments.isEmpty()) {
            return attachmentWrapper;
        }
        try {
            attachments = [
                SELECT Id, Name, ParentId
                FROM Attachment
                WHERE ParentId = :promotion.Id AND (Name LIKE 'AUTO RESOLVED%' OR Name LIKE 'RESOLVED%' OR NAME LIKE 'US-%')
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1000
            ];
        } catch (Exception excp) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, excp.getMessage()));
        }

        attachmentWrapper = populateAttachment(attachments);
        promotionMetadataProcess();
        return attachmentWrapper;
    }

    /*
     *  Selects an attachment from the list and saves it in the attachmentToResolve variable
     *  The attachmentToResolve variable is used by the CodeMirror text editor
     */
    public void openAttachment() {
        String attIndex = Apexpages.currentPage().getParameters().get('attIndex');
        if (attIndex != null && attachmentWrapper[Integer.valueOf(attIndex)].smartOnlineResolutionKey != null) {
            gitRepoConflictFile = [
                SELECT Id, Name, ParentId, Body
                FROM Attachment
                WHERE
                    ParentId = :promotion.Project__r.Deployment_Flow__r.Git_Repository__c
                    AND Name LIKE :attachmentWrapper[Integer.valueOf(attIndex)].smartOnlineResolutionKey
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (attachmentWrapper[Integer.valueOf(attIndex)].Name.startsWith('SMART_ONLINE')) {
                attachmentName = userStoryForSmartConflict + attachmentWrapper[Integer.valueOf(attIndex)].Name.replace('SMART_ONLINE', '');
                attachmentToResolve = !gitRepoConflictFile.isEmpty() ? gitRepoConflictFile[0] : new Attachment();
            }
        }
        if (attIndex != null && attachmentWrapper[Integer.valueOf(attIndex)].attachmentId != null) {
            attachmentToResolve = [
                SELECT Id, Name, Body, ParentId
                FROM Attachment
                WHERE
                    Id = :attachmentWrapper[Integer.valueOf(attIndex)].attachmentId
                    AND (Name LIKE 'AUTO RESOLVED%'
                    OR Name LIKE 'RESOLVED%'
                    OR NAME LIKE 'US-%')
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        }
    }

    /*
     *  Perform openAttachment() method above for multiple selected attachments.
     */
    public void openAttachmentSelected() {
        String attIDsList = Apexpages.currentPage().getParameters().get('attIDsList');
        Set<Id> attachmentIDSet = (attIDsList == null) ? new Set<Id>() : (Set<Id>) JSON.deserialize(attIDsList, Set<Id>.class);
        if (!attachmentIDSet.isEmpty()) {
            attachmentsToResolve.addAll(
                [
                    SELECT Id, Name, ParentId, Body
                    FROM Attachment
                    WHERE Id IN :attachmentIDSet AND (Name LIKE 'AUTO RESOLVED%' OR Name LIKE 'RESOLVED%' OR NAME LIKE 'US-%')
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                    LIMIT 100
                ]
            );
            jsonStr = JSON.serialize(attachmentsToResolve);
        }
    }

    /**
     * Getting user story metadatas included in the promotion record to find which attachments are related to promotion
     */
    private void promotionMetadataProcess() {
        Set<String> metadataNames = getUserStoryMetadatas();
        List<AttachmentWrapper> promotionMetadataAttachments = new List<AttachmentWrapper>();
        List<AttachmentWrapper> outOfPromotionMetadataAttachments = new List<AttachmentWrapper>();
        Set<Id> promotionMetadataAttachmentIds = new Set<Id>();
        for (String metadataItem : metadataNames) {
            String metadataName = metadataItem.substring(metadataItem.indexOf('.') + 1);

            for (Integer i = 0; i < attachmentWrapper.size(); i++) {
                if (
                    attachmentWrapper[i].Name.toLowerCase().contains(metadataName.toLowerCase()) &&
                    !promotionMetadataAttachmentIds.contains(attachmentWrapper[i].attachmentId)
                ) {
                    promotionMetadataAttachments.add(attachmentWrapper[i]);
                    promotionMetadataAttachmentIds.add(attachmentWrapper[i].attachmentId);
                }
            }
        }

        for (Integer i = 0; i < attachmentWrapper.size(); i++) {
            if (attachmentWrapper[i].attachmentId == null) {
                if (!attachmentWrapper[i].Name.contains('SMART_ONLINE')) {
                    attachmentWrapper[i].commitContent = COMMIT_CONTENT;
                }
            } else if (!promotionMetadataAttachmentIds.contains(attachmentWrapper[i].attachmentId)) {
                outOfPromotionMetadataAttachments.add(attachmentWrapper[i]);
                outOfPromotionMetadataAttachmentIds.add(attachmentWrapper[i].attachmentId);
                if (!attachmentWrapper[i].Name.contains('AUTO RESOLVED')) {
                    attachmentWrapper[i].Name = 'AUTO RESOLVED ' + attachmentWrapper[i].Name;
                }
                attachmentWrapper[i].commitContent = COMMIT_CONTENT;
            }
        }
    }

    /**
     * Populate attachment name after resolve and auto resolve
     */
    private Attachment populateAttachmentName(Integer attachmentIndex) {
        AttachmentWrapper attWrapper = attachmentWrapper[attachmentIndex];
        Attachment autoResolvedFile;

        if (attWrapper.Name.startsWith('SMART_ONLINE') && attWrapper.smartOnlineResolutionKey != null) {
            List<Attachment> gitRepoConflictAttachment = [
                SELECT Id, Name, ParentId, Body
                FROM Attachment
                WHERE ParentId = :promotion.Project__r.Deployment_Flow__r.Git_Repository__c AND Name LIKE :attWrapper.smartOnlineResolutionKey
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            String attachmentName = 'AUTO RESOLVED ' + userStoryForSmartConflict + attWrapper.Name.replace('SMART_ONLINE', '');

            List<Attachment> promotionAttachment = [
                SELECT Id, Name, ParentId, Body
                FROM Attachment
                WHERE ParentId = :promotion.Id AND Name LIKE :attachmentName
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!promotionAttachment.isEmpty()) {
                promotionAttachment[0].body = (!gitRepoConflictAttachment.isEmpty() ? gitRepoConflictAttachment[0].Body : Blob.valueOf(' '));
                autoResolvedFile = promotionAttachment[0];
            } else {
                autoResolvedFile = new Attachment(
                    ParentId = promotion.Id,
                    Name = 'AUTO RESOLVED ' + userStoryForSmartConflict + attWrapper.Name.replace('SMART_ONLINE', ''),
                    Body = (!gitRepoConflictAttachment.isEmpty() ? gitRepoConflictAttachment[0].Body : Blob.valueOf(' '))
                );
            }

            if (attWrapper.Name.startsWith('SMART_ONLINE')) {
                attWrapper.Name = attWrapper.Name.replace('SMART_ONLINE', 'AUTO RESOLVED');
                attWrapper.userStory = userStoryForSmartConflict;
            }
            return autoResolvedFile;
        } else {
            Attachment attachmentRecord;
            Integer index = 0;
            for (Attachment attachment : attachments) {
                if (attWrapper.attachmentId == attachment.Id) {
                    attachmentRecord = attachment;
                    break;
                }
                index++;
            }

            if (attWrapper.Name.startsWith('RESOLVED')) {
                attWrapper.Name = attWrapper.Name.replace('RESOLVED', 'AUTO RESOLVED');
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, System.label.CreateDeploymentMessage));
            } else if (attWrapper.Name.startsWith('US-')) {
                attachmentRecord.Name = 'AUTO RESOLVED ' + attachmentRecord.Name;
                attWrapper.Name = 'AUTO RESOLVED ' + attWrapper.Name;
            }
            if (!Schema.sObjectType.Attachment.fields.Name.isUpdateable() || !Schema.sObjectType.Attachment.fields.Name.isCreateable()) {
                return null;
            }
            attachments.set(index, attachmentRecord);
            attachmentWrapper.set(attachmentIndex, attWrapper);
            return attachmentRecord;
        }
    }

    /**
     * Update attachments
     */
    private void updateAttachments(List<Attachment> updatedAttachments) {
        Utilities.Secure_DML(updatedAttachments, Utilities.DML_Action.UPS, Schema.Sobjecttype.Attachment);
    }

    /**
     *  Updates the attachment name to start with "AUTO RESOLVED"
     */
    public void saveAutoResolveAttachment() {
        String attachmentIndex = Apexpages.currentPage().getParameters().get('attIndex');
        Boolean isResolved = true;
        List<Attachment> updateAttachmentList = new List<Attachment>();
        Set<String> smartResolutionKeySet = new Set<String>();
        if (String.isEmpty(attachmentIndex)) {
            String attIDsList = Apexpages.currentPage().getParameters().get('attIDsList');
            Set<Id> attachmentIDSet = attIDsList == null ? new Set<Id>() : (Set<Id>) JSON.deserialize(attIDsList, Set<Id>.class);
            for (Integer index = 0; index < attachmentWrapper.size(); index++) {
                if (attachmentIDSet.contains(attachmentWrapper[index].attachmentId)) {
                    Attachment updatedAttachment = populateAttachmentName(index);
                    if (updatedAttachment != null) {
                        updateAttachmentList.add(updatedAttachment);
                        if (attachmentWrapper[index].smartOnlineResolutionKey != null) {
                            smartResolutionKeySet.add(attachmentWrapper[index].smartOnlineResolutionKey);
                        }
                    }
                }
            }
            if (!updateAttachmentList.isEmpty()) {
                updateAttachments(updateAttachmentList);
                updateAttachmentList.clear();
                performConflictFileDeletionGitRepo('', smartResolutionKeySet);
                if (isResolved) {
                    updatePromotionAsResolved();
                }
            }
        } else if (attachmentIndex != null && Integer.valueOf(attachmentIndex) != null) {
            Attachment updatedAttachment = populateAttachmentName(Integer.valueOf(attachmentIndex));
            if (updatedAttachment != null) {
                updateAttachments(new List<Attachment>{ updatedAttachment });
                for (AttachmentWrapper attachmentRecord : attachmentWrapper) {
                    if (attachmentRecord.Name.startsWith('US-')) {
                        isResolved = false;
                        break;
                    }
                }
                performConflictFileDeletionGitRepo(attachmentIndex, new Set<String>());
                if (isResolved) {
                    updatePromotionAsResolved();
                }
            }
        }
    }

    public void performConflictFileDeletionGitRepo(String attachmentIndex, Set<String> smartResolutionKeySet) {
        List<Attachment> attachmentToDelete = new List<Attachment>();
        try {
            if (Attachment.getSObjectType().getDescribe().isAccessible()) {
                if (!String.isBlank(attachmentIndex) && attachmentWrapper[Integer.valueOf(attachmentIndex)].smartOnlineResolutionKey != null) {
                    attachmentToDelete = [
                        SELECT Name
                        FROM Attachment
                        WHERE
                            Name = :attachmentWrapper[Integer.valueOf(attachmentIndex)].smartOnlineResolutionKey
                            AND ParentId = :promotion.Project__r.Deployment_Flow__r.Git_Repository__c
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                } else if (!smartResolutionKeySet.isEmpty()) {
                    attachmentToDelete = [
                        SELECT Name
                        FROM Attachment
                        WHERE Name IN :smartResolutionKeySet AND ParentId = :promotion.Project__r.Deployment_Flow__r.Git_Repository__c
                        ORDER BY CreatedDate DESC
                    ];
                }
                if (!attachmentToDelete.isEmpty() && Attachment.getSObjectType().getDescribe().isDeletable()) {
                    delete attachmentToDelete;
                }
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, System.label.ConflictStrategySuccess));
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, System.label.CreateDeploymentMessage));
            }
        } catch (Exception excp) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, excp.getMessage()));
        }
    }

    public void updatePromotionAsResolved() {
        promotion.Status__c = 'Conflicts Resolved';
        Utilities.Secure_DML(promotion, Utilities.DML_Action.UPD, schema.Sobjecttype.Promotion__c);
    }

    /**
     *  Updates the attachment name to start with "RESOLVED"
     */
    public void saveResolvedAttachment() {
        Integer index = 0;
        Boolean isResolvedManual = true;

        if (attachmentToResolve != null) {
            for (AttachmentWrapper attachmentRecord : attachmentWrapper) {
                if (attachmentRecord.attachmentId == attachmentToResolve.Id) {
                    if (attachmentRecord.Name.startsWith('AUTO RESOLVED')) {
                        attachmentRecord.Name = attachmentRecord.Name.replace('AUTO RESOLVED', 'RESOLVED');
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, System.label.CreateDeploymentMessage));
                    } else if (!attachmentRecord.Name.startsWith('RESOLVED')) {
                        attachmentRecord.Name = 'RESOLVED ' + attachmentRecord.Name;
                    }

                    attachmentWrapper.set(index, attachmentRecord); // The attachment is upserted via Javascript
                    //break;
                }
                if (attachmentRecord.Name.startsWith('US-')) {
                    isResolvedManual = false;
                    //break; commented out to prevent attachment items to not to show up as resolved if not started to resolve with the first attachment
                }

                index = index + 1;
            }

            try {
                if (
                    !gitRepoConflictFile.isEmpty() &&
                    Attachment.getSObjectType().getDescribe().isAccessible() &&
                    Attachment.getSObjectType().getDescribe().isDeletable()
                ) {
                    delete gitRepoConflictFile;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, System.label.ConflictStrategySuccess));
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, System.label.CreateDeploymentMessage));
                }
            } catch (Exception excp) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.label.ConflictStrategyFailed));
            }

            if (isResolvedManual) {
                updatePromotionAsResolved();
            }
        }
    }

    /**
     *  Checks that all attachments are marked as RESOLVED or AUTO RESOLVED.
     *  If True the user is redirected to the Promotion page.
     */
    public void createDeployment() {
        goToPromotion = true;
    }

    /**
     *  Checks if we can proceed with creating deployment after validating that resolution is done.
     */
    public void isCreateDeployReady() {
        for (AttachmentWrapper attWrapper : attachmentWrapper) {
            if (
                !attWrapper.Name.startsWith('RESOLVED') &&
                !attWrapper.Name.startsWith('AUTO RESOLVED') &&
                !attWrapper.Name.startsWith('SMART_ONLINE')
            ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CONFLICT_RESOLUTION_PENDING));
                return;
            }
        }
    }

    /**
     * Returns all metadata names in the promotion to check if conflicts are in the promotion or not
     */
    public Set<String> getUserStoryMetadatas() {
        Set<Id> userStoryIds = new Set<Id>();
        Set<String> userStoryMetadataAPINames = new Set<String>();
        Map<String, String> userStoryMetadataMap = new Map<String, String>();
        try {
            String promotedUserStoryQuery =
                'SELECT User_Story__c, User_Story__r.Name FROM Promoted_User_Story__c WHERE Promotion__c = \'' +
                String.escapeSingleQuotes(promotion.Id) +
                '\' WITH SECURITY_ENFORCED';
            for (Promoted_User_Story__c promotedUSerStory : Database.query(promotedUserStoryQuery)) {
                userStoryIds.add(promotedUSerStory.User_Story__c);
            }

            if (!userStoryIds.isEmpty()) {
                String userStoryMetadataQuery = 'SELECT Id, Metadata_API_Name__c, User_Story__c , User_Story__r.Name FROM User_Story_Metadata__c WHERE User_Story__c IN :userStoryIds WITH SECURITY_ENFORCED ORDER BY Last_Commit_Date__c DESC LIMIT 1000';
                for (User_Story_Metadata__c usMetadata : Database.query(userStoryMetadataQuery)) {
                    if (!userStoryMetadataAPINames.contains(usMetadata.Metadata_API_Name__c)) {
                        userStoryMetadataAPINames.add(usMetadata.Metadata_API_Name__c);
                        userStoryMetadataMap.put(usMetadata.Metadata_API_Name__c, usMetadata.User_Story__r.Name);
                    }
                }

                if (!userStoryMetadataMap.isEmpty()) {
                    String gitBranch = promotion.Project__r.Deployment_Flow__r.Git_Repository__r.Branch_Base_URL__c;
                    for (AttachmentWrapper attWrapper : attachmentWrapper) {
                        if (attWrapper.Name.contains('SMART_ONLINE')) {
                            attWrapper.commitContent =
                                gitBranch +
                                'feature/' +
                                userStoryMetadataMap.get(attWrapper.metadataType + '.' + attWrapper.metadataName) +
                                '/' +
                                attWrapper.commitContent;
                            attWrapper.userStory = String.isNotBlank(
                                    userStoryMetadataMap.get(attWrapper.metadataType + '.' + attWrapper.metadataName)
                                )
                                ? userStoryMetadataMap.get(attWrapper.metadataType + '.' + attWrapper.metadataName)
                                : userStoryForSmartConflict;
                        }
                    }
                }
            }
        } catch (Exception excp) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, excp.getMessage()));
        }
        return userStoryMetadataAPINames;
    }

    public Pagereference redirectToPromotion() {
        return new ApexPages.StandardController(promotion).view();
    }

    /*
        To populate the value in wrapper class to display in the table
    */
    public List<AttachmentWrapper> populateAttachment(List<Attachment> attachments) {
        List<AttachmentWrapper> attachmentWrapperList = new List<AttachmentWrapper>();
        Map<String, AttachmentWrapper> attachmentWrapperDeDupeMap = new Map<String, AttachmentWrapper>(); //To check for duplicate metadata after smart resolved
        try {
            String gitBranch = promotion.Project__r.Deployment_Flow__r.Git_Repository__r.Branch_Base_URL__c;
            String latestCommitId = [
                    SELECT Name
                    FROM Attachment
                    WHERE ParentId = :promotion.Project__r.Deployment_Flow__r.Git_Repository__c AND CreatedDate = LAST_N_DAYS:365
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ]
                ?.Name.substringBefore('.');
            for (Attachment attachment : attachments) {
                AttachmentWrapper attachmentWrap = new AttachmentWrapper();
                attachmentWrap.attachmentId = attachment.Id;
                attachmentWrap.Name = attachment.Name;
                attachmentWrap.userStory = 'US-' + attachment.Name.substringAfter('-').substringBefore(' ');
                attachmentWrap.metadataType = attachmentTypeMap.get(attachment.Name.substringAfter('.'));
                attachmentWrap.metadataName = attachment.Name.substringAfter('/').substringBefore('.');
                if (BIT_BUCKET.equals(promotion.Project__r.Deployment_Flow__r.Git_Repository__r.Git_Provider__c)) {
                    gitBranch = promotion.Project__r.Deployment_Flow__r.Git_Repository__r.Tag_Base_URL__c;
                    attachmentWrap.commitContent =
                        gitBranch +
                        '/' +
                        latestCommitId +
                        '/' +
                        attachment.Name.substringAfterLast(' ') +
                        '?at=' +
                        'feature/' +
                        attachmentWrap.userStory;
                } else if (MICROSOFT_TEAM_SERVICE.equals(promotion.Project__r.Deployment_Flow__r.Git_Repository__r.Git_Provider__c)) {
                    attachmentWrap.commitContent =
                        gitBranch +
                        'feature/' +
                        attachmentWrap.userStory +
                        '&path=/' +
                        attachment.Name.substringAfterLast(' ');
                } else {
                    attachmentWrap.commitContent = gitBranch + 'feature/' + attachmentWrap.userStory + '/' + attachment.Name.substringAfterLast(' ');
                }
                attachmentWrapperList.add(attachmentWrap);
                attachmentWrapperDeDupeMap.put(attachmentWrap.metadataName + attachmentWrap.metadataType, attachmentWrap);
            }

            List<Attachment> gitConflictAttachment = [
                SELECT Id, Name, ParentId, Body
                FROM Attachment
                WHERE ParentId = :promotion.Id AND Name LIKE 'GitConflict%'
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1000
            ];
            if (!gitConflictAttachment.isEmpty()) {
                getUserStoryForSmartConflict();
                for (Attachment attachment : gitConflictAttachment) {
                    String attBody = EncodingUtil.base64Decode(EncodingUtil.base64Encode(attachment.Body)).toString();
                    List<Object> attItems = (List<Object>) JSON.deserializeUntyped(
                        EncodingUtil.base64Decode(EncodingUtil.base64Encode(attachment.Body)).toString()
                    );
                    if (attItems.size() > 0) {
                        for (Object attItem : attItems) {
                            Map<String, Object> attMap = (Map<String, Object>) attItem;
                            if (String.valueOf(attMap.get('strategy')).contains('SMART_ONLINE')) {
                                AttachmentWrapper attachmentWrap = new AttachmentWrapper();
                                attachmentWrap.Name = String.valueOf(attMap.get('strategy')) + ' ' + String.valueOf(attMap.get('conflictedPath'));
                                attachmentWrap.commitContent = String.valueOf(attMap.get('conflictedPath')).contains('null')
                                    ? COMMIT_CONTENT
                                    : String.valueOf(attMap.get('conflictedPath'));
                                attachmentWrap.userStory = '';
                                attachmentWrap.metadataType = attachmentTypeMap.get(String.valueOf(attMap.get('conflictedPath')).substringAfter('.'));
                                attachmentWrap.metadataName = String.valueOf(attMap.get('conflictedPath')).substringAfter('/').substringBefore('.');
                                attachmentWrap.smartOnlineResolutionKey = String.valueOf(attMap.get('smartOnlineResolutionKey'));
                                if (!attachmentWrapperDeDupeMap.containsKey(attachmentWrap.metadataName + attachmentWrap.metadataType)) {
                                    attachmentWrapperList.add(attachmentWrap);
                                    attachmentWrapperDeDupeMap.put(attachmentWrap.metadataName + attachmentWrap.metadataType, attachmentWrap);
                                }
                            } else {
                                AttachmentWrapper attachmentWrap = new AttachmentWrapper();
                                attachmentWrap.metadataType = attachmentTypeMap.get(String.valueOf(attMap.get('conflictedPath')).substringAfter('.'));
                                attachmentWrap.metadataName = String.valueOf(attMap.get('conflictedPath')).substringAfter('/').substringBefore('.');
                                attachmentWrap.smartOnlineResolutionKey = String.valueOf(attMap.get('smartOnlineResolutionKey'));
                                for (AttachmentWrapper attach : attachmentWrapperList) {
                                    if ((attach.metadataName + attach.metadataType) == (attachmentWrap.metadataName + attachmentWrap.metadataType)) {
                                        attach.smartOnlineResolutionKey = attachmentWrap.smartOnlineResolutionKey;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception excp) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, excp.getMessage()));
        }
        return attachmentWrapperList;
    }

    private String getUserStoryForSmartConflict() {
        List<Promoted_User_Story__c> promotedUserStories = [
            SELECT User_Story__c, User_Story__r.Name
            FROM Promoted_User_Story__c
            WHERE Promotion__c = :promotion.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (!promotedUserStories.isEmpty()) {
            userStoryForSmartConflict = promotedUserStories[0].User_Story__r.Name;
        }

        return userStoryForSmartConflict;
    }

    private Map<String, String> populateAttachmentTypeMap() {
        Map<String, String> attachmentMap = new Map<String, String>();
        attachmentMap.put('page', 'ApexPage');
        attachmentMap.put('cls', 'ApexClass');
        attachmentMap.put('trigger', 'ApexTrigger');
        attachmentMap.put('layout', 'Layout');
        attachmentMap.put('component', 'ApexComponent');
        attachmentMap.put('cmp', 'AuraBundle');
        attachmentMap.put('js', 'AuraBundle');
        attachmentMap.put('lwc', 'LightningWebComponent');
        attachmentMap.put('profile', 'Profile');
        attachmentMap.put('permissionset', 'PermissionSet');
        attachmentMap.put('reportType', 'ReportType');
        attachmentMap.put('flowDefinition', 'FlowDefinition');
        attachmentMap.put('report', 'Report');
        attachmentMap.put('md', 'CustomMetadata');
        attachmentMap.put('flow', 'Flow');
        attachmentMap.put('app', 'Application');
        attachmentMap.put('dashboard', 'Dashboard');
        attachmentMap.put('flexipage', 'Flexipage');
        return attachmentMap;
    }

    public class AttachmentWrapper {
        public String attachmentId { get; set; }
        public String userStory { get; set; }
        public String commitContent { get; set; }
        public String metadataType { get; set; }
        public String metadataName { get; set; }
        public String Name { get; set; }
        public String smartOnlineResolutionKey { get; set; }
    }
}