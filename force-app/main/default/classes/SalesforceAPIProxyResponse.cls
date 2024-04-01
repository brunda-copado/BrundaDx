public inherited sharing class SalesforceAPIProxyResponse {

    // Exptected response
    public String content;

    // Salesforce error
    public Integer statusCode;
    public String errorCode;
    public String errorMessage;

    // Spring framework error
    public Decimal timestamp;
    public Integer status;
    // public String error; duplicated, but expected here too
    // public String exception; reserved keyworkd, backend should change it if possible
    public String message;
    public String path;

    // Copado api error
    public String error;

    // PUBLIC

    public String errorMessage() {
        String result;
        if (String.isNotBlank(errorMessage)) {
            result = errorMessage;
        } else if (String.isNotBlank(message)) {
            result = message;
        } else if (String.isNotBlank(error)) {
            result = error;
        }
        return result;
    }
}