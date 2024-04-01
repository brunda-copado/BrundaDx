public with sharing class RefreshRecentChanges {
    private static final Set<String> INVALID_TYPES = new Set<String>{ 'AuraDefinition', 'LightningComponentResource', 'ExperienceResource' };
    private static final Set<String> NOT_TO_BE_FORMATTED_TYPES = new Set<String>{ 'Dashboard', 'Report', 'WorkflowRule', 'EmailTemplate' };

    private String orgId;
    private DateTime dateTimeToRetrieveChanges;

    // CTOR

    public RefreshRecentChanges(String orgId) {
        this.orgId = orgId;
    }

    public RefreshRecentChanges(String orgId, DateTime dateTimeToRetrieveChanges) {
        this(orgId);
        this.dateTimeToRetrieveChanges = dateTimeToRetrieveChanges;
    }

    // PUBLIC

    public List<SourceMemberResult> execute() {
        SalesforceAPIProxyRequest payload = new SalesforceAPIProxyRequest(getEndpoint(), orgId).logLabelIdentifier('SourceMember Tooling API Query');
        
        SalesforceAPIProxyResponse response = (SalesforceAPIProxyResponse) new SalesforceAPIProxyCallout()
            .default()
            .body(payload)
            .request()
            .type(SalesforceAPIProxyResponse.class)
            .parseResponse();

        List<SourceMemberResult> sourceMembers = processResponse(response);
        List<SourceMemberResult> validSourceMembers = filterInvalidTypes(sourceMembers);
        List<SourceMemberResult> encodedSourceMembers = encodeNames(validSourceMembers);
        return encodedSourceMembers;
    }

    // PRIVATE

    private String getEndpoint() {
        Attachment att;
        if (dateTimeToRetrieveChanges == null) {
            att = getOrgMetadataAttachment();
        }

        String toolingApiPath = '/services/data/v' + Settings.toolingApiVersion + '/tooling';
        String queryPath = '/query/?q=';

        List<String> fields = new List<String>{
            'CreatedDate',
            'CreatedBy.Name',
            'LastModifiedDate',
            'LastModifiedBy.Name',
            'IsNameObsolete',
            'MemberName',
            'MemberType'
        };

        String validUrlDateTime = dateTimeToRetrieveChanges != null
            ? getValidUrlDatetime(dateTimeToRetrieveChanges)
            : getValidUrlDatetime(att.LastModifiedDate);

        String greaterEqualsEncoded = '%3E%3D';

        String queryParamTemplate = 'SELECT+{0}+FROM+SourceMember+WHERE+LastModifiedDate{1}{2}{3}+LIMIT+1000';

        String queryParam = String.format(
            queryParamTemplate,
            new List<Object>{ String.join(fields, ','), greaterEqualsEncoded, validUrlDateTime, getOrgMetadataTypesFilter() }
        );

        return toolingApiPath + queryPath + queryParam;
    }

    private Attachment getOrgMetadataAttachment() {
        String query = new AttachmentsSelector()
            .newQueryFactory(false)
            .setEnforceFLS(true)
            .selectField('LastModifiedDate')
            .setCondition('ParentId = :orgId AND Name = \'MetaData\'')
            .setLimit(1)
            .toSOQL();

        return Database.query(query);
    }

    private String getValidUrlDatetime(Datetime dt) {
        return dt.formatGMT('yyyy-MM-dd HH:mm:ss').replace(' ', 'T') + 'Z';
    }

    private String getOrgMetadataTypesFilter() {
        String metadataTypes = new OrgsSelector().byId(new List<Id>{ orgId })[0].Metadata_Types__c;
        return String.isBlank(metadataTypes) ? '' : '+AND+MemberType+IN+(\'' + metadataTypes.replace(',', '\',\'') + '\')';
    }

    private List<SourceMemberResult> processResponse(SalesforceAPIProxyResponse response) {
        if (response.statusCode == 200) {
            SourceMemberQueryResult content = (SourceMemberQueryResult) JSON.deserialize(response.content, SourceMemberQueryResult.class);
            return content.records;
        } else {
            String message = String.isNotBlank(response.errorMessage())
                ? response.errorMessage()
                : Label.Refresh_Recent_Changes_Generic_Exception_Message;
            
            message = message.contains(Label.ConnectionException) ? Label.Credential_ReAuth_Needed : message;
            throw new ApplicationException(message);
        }
    }

    private List<SourceMemberResult> filterInvalidTypes(List<SourceMemberResult> sourceMembers) {
        List<SourceMemberResult> result = new List<SourceMemberResult>();
        for (SourceMemberResult sourceMember : sourceMembers) {
            if (!INVALID_TYPES.contains(sourceMember.MemberType)) {
                result.add(sourceMember);
            }
        }
        return result;
    }

    private List<SourceMemberResult> encodeNames(List<SourceMemberResult> sourceMembers) {
        List<SourceMemberResult> result = new List<SourceMemberResult>();
        for (SourceMemberResult sourceMember : sourceMembers) {
            sourceMember.MemberName = getEncoded(sourceMember.MemberName, sourceMember.MemberType);
            result.add(sourceMember);
        }
        return result;
    }

    private String getEncoded(String metadataName, String metadataType) {
        String result = metadataName;
        if (!NOT_TO_BE_FORMATTED_TYPES.contains(metadataType)) {
            String[] stringCharacters = metadataName.split('');
            for(Integer i = 0; i < stringCharacters?.size(); i++){
                if(!stringCharacters[i]?.isAlphanumericSpace()){
                    stringCharacters[i] = EncodingUtil.urlEncode(stringCharacters[i], 'UTF-8');
                }
            }
            result = String.join(stringCharacters,'');
            result = result.contains('.') ? result.substringBefore('.') + '.' + result.substringAfter('.').replace('.', '%2E') : result;
        }
        return result;
    }

    // INNER

    @TestVisible
    private with sharing class SourceMemberQueryResult {
        @TestVisible
        private List<SourceMemberResult> records;
    }
}