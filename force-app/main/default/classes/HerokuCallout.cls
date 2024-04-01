public inherited sharing virtual class HerokuCallout extends HttpCallout {
    // CTOR

    private Boolean useDeprecatedKey = false;

    public HerokuCallout(String url, HttpMethod method) {
        super(url, method);
    }
    
    // PUBLIC

    public HerokuCallout useDeprecatedKey(){
        this.useDeprecatedKey = true;
        return this;
    }

    public HerokuCallout default() {
        header('userId', Settings.USER_ID);
        header('orgId', Settings.ORGANIZATION_ID);
        header('token2', encrypt(authenticationToken()));
        header('Accept', 'application/json');
        header('content-type', 'application/json');
        timeout(30000);
        return this;
    }

    // PRIVATE

    private String authenticationToken() {
        String fakeSessionId = '<sessionId might change>';
        String currentDate = Datetime.now().formatGmt('yyyy-MM-dd');
        String dummyData = 'Copado Deployer by Copado Ltd' + Settings.USER_ID + Settings.ORGANIZATION_ID + fakeSessionId + currentDate;
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(dummyData));
        return EncodingUtil.convertToHex(hash);
    }

    private String encrypt(String token) {
        String result = null;
        if (String.isNotBlank(token)) {
            // Note: after change to token2, some test methods were failing due to invalid crypto keys defined in the setup, as token was not encrypted before
            if (Test.isRunningTest()) {
                try {
                    result = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', cryptoKey(), Blob.valueOf(token)));
                } catch (Exception e) {
                }
            } else {
                result = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', cryptoKey(), Blob.valueOf(token)));
            }
        }
        return result;
    }

    private Blob cryptoKey() {
        String cryptoKey = Settings__c.getOrgDefaults().CryptoKEY__c;
        if (String.isNotBlank(cryptoKey) && !useDeprecatedKey) {
            System.debug('Using customer unique key');
        } else {
            for (Copado_Protected_Settiing__mdt setting : [
                SELECT Text_Field__c
                FROM Copado_Protected_Settiing__mdt
                WHERE DeveloperName = 'Deprecated_Key'
                LIMIT 1
            ]) {
                String deprecatedKey = setting.Text_Field__c;
                if (String.isNotBlank(deprecatedKey)) {
                    System.debug('Using depre key');
                    cryptoKey = deprecatedKey;
                }
            }
        }
        return String.isNotBlank(cryptoKey) ? EncodingUtil.base64Decode(cryptoKey) : null;
    }
}