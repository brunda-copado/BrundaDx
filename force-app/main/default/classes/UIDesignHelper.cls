/**
 * This will be used as a single class with generic methods for new UI messages and changes
 */
// Note: This is Helper class to be used in various scenarios so these method needs to be public to be accessed
@SuppressWarnings('PMD.ExcessivePublicCount')

public with sharing class UIDesignHelper {

    // CONSTANTS

    private static final String ALERT_VARIANT_WARNING = 'warning';
    private static final String ALERT_VARIANT_SUCCESS = 'success';
    private static final String ALERT_VARIANT_ERROR = 'error';

    /**
     * This is used to show user friendly warning message if a user do not have access to the object (access, query, create, update, delete, ...)
     *
     * @param objectLabelName name of the object, for instance; Schema.SObjectType.Git_Org_Commit__c.getLabel()
     */
    public static void warningMessageOLSFLS(String objectLabelName) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Related_Object + ' ' + objectLabelName));
    }

    /**
     * This is used to show user friendly warning message if a user do not have access to the object (access, query, create, update, delete, ...)
     *
     * @param objectLabelName name of the object, for instance; Schema.SObjectType.Git_Org_Commit__c.getLabel()
     * @return List of AlertWrapper which has required properties for copado-alert LWC component
     */
    public static List<AlertWrapper> warningAlertsOLSFLS(String objectLabelName) {
        if (ApexPages.currentPage() == null || String.isBlank(ApexPages.currentPage().getUrl())) {
            List<AlertWrapper> responseAlerts = new List<AlertWrapper> ();
            responseAlerts.add(new AlertWrapper(ALERT_VARIANT_WARNING, Label.Insufficient_Access_Rights + '<br/>' + Label.Related_Object + ' ' + objectLabelName));            return responseAlerts;
        } else {
            warningMessageOLSFLS(objectLabelName);
            return null;
        }
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: ApexPages.Severity.Warning
     * available options for severityLevel parameter : Confirm, info, fatal, warning, error
     * @param message2Show the message that will appear on the page
     */
    public static void genericWarningMessage(ApexPages.Severity severityLevel, Object message2Show) {
        ApexPages.addMessage(new ApexPages.Message(severityLevel, message2Show.toString()));
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: ApexPages.Severity.Warning
     * available options for severityLevel parameter : Confirm, info, fatal, warning, error
     * @param message2Show the message that will appear on the page
     * @return AlertWrapper which has required properties for copado-alert LWC component
     */
    public static AlertWrapper genericWarningAlert(ApexPages.Severity severityLevel, Object message2Show) {
        if (ApexPages.currentPage() == null || String.isBlank(ApexPages.currentPage().getUrl())) {
            return new AlertWrapper(getVariant(severityLevel), message2Show.toString());
        } else {
            genericWarningMessage(severityLevel, message2Show);
            return null;
        }
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: ApexPages.Severity.Warning
     * available options for severityLevel parameter : Confirm, info, fatal, warning, error
     * @param message2Show the message that will appear on the page
     * @param isBlocker the property to define is Alert is need to be blocker for further processing
     */
    public static AlertWrapper genericWarningAlert(ApexPages.Severity severityLevel, Object message2Show, Boolean isBlocker) {
        return new AlertWrapper(getVariant(severityLevel), message2Show.toString(), isBlocker);
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: ApexPages.Severity.Warning
     * available options for severityLevel parameter : Confirm, info, fatal, warning, error
     * @param message2ShowList messages that will appear on the page
     */
    public static void genericWarningMessage(ApexPages.Severity severityLevel, List<Object> message2ShowList) {
        for(Object msg : message2ShowList) {
            ApexPages.addMessage(new ApexPages.Message(severityLevel, msg.toString()));
        }
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: ApexPages.Severity.Warning
     * available options for severityLevel parameter : Confirm, info, fatal, warning, error
     * @param message2ShowList messages that will appear on the page
     * @return List of AlertWrapper which has required properties for copado-alert LWC component
     */
    public static List<AlertWrapper> genericWarningAlerts(ApexPages.Severity severityLevel, List<Object> message2ShowList) {
        if (ApexPages.currentPage() == null || String.isBlank(ApexPages.currentPage().getUrl())) {
            List<AlertWrapper> responseAlerts = new List<AlertWrapper> ();
            for(Object msg : message2ShowList) {
                responseAlerts.add(new AlertWrapper(getVariant(severityLevel), msg.toString()));
            }
            return responseAlerts;
        } else {
            for(Object msg : message2ShowList) {
                ApexPages.addMessage(new ApexPages.Message(severityLevel, msg.toString()));
            }
            return null;
        }
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: 'success' 'warning' 'error'
     * @param message2ShowList messages that will appear on the page
     */
    public static Map<String, List<Object>> genericWarningMessage(String severityLevel, List<Object> message2ShowList) {
        Map<String, List<Object>> pageMessagesMap = new Map<String, List<Object>>();
        pageMessagesMap.put(severityLevel, message2ShowList);
        return pageMessagesMap;
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: 'success' 'warning' 'error'
     * @param message2ShowList messages that will appear on the page
     * @param existingMessageMap messages map that will be checked and returned back after new messages added
     */
    public static Map<String, Set<Object>> accumulativeGenericWarningMessage(String severityLevel, List<Object> message2ShowList, Map<String, Set<Object>> existingMessageMap) {
        if(existingMessageMap.containsKey(severityLevel)) {
            existingMessageMap.get(severityLevel).addAll(message2ShowList);
        } else {
            Set<Object> messagesSet = new Set<Object>();
            messagesSet.addAll(message2ShowList);
            existingMessageMap.put(severityLevel, messagesSet);
        }
        return existingMessageMap;
    }

    /**
     * This is used to show user friendly error message if job fail in try{} code block
     *
     * @param ex Catch exception
     *
     * @return String value of the stacktrace
     */
    public static String catchExceptionMessage(Exception ex) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        return ex.getStackTraceString();
    }

    /**
     * This method is used to clear page messages
     */
    public static void clearPageMessages() {
        ApexPages.getMessages().clear();
    }

    // PRIVATE

    private static String getVariant(ApexPages.Severity severityLevel) {
        if(ApexPages.Severity.CONFIRM == severityLevel) {
            return ALERT_VARIANT_SUCCESS;
        } else if(ApexPages.Severity.FATAL == severityLevel) {
            return ALERT_VARIANT_ERROR;
        } else {
            return String.valueOf(severityLevel).toLowerCase();
        }
    }


    /**
     * Wrapper class for custom exception data
     */
    public class CustomExceptionData {
        public ApexPages.Severity severityLevel;
        public String generalMessage;
        public List<String> stepsToFix;
        public Integer codeLine;
        public String stackTrace;
        public String actionName;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public CustomExceptionData() {}

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public CustomExceptionData(ApexPages.Severity sLevel, String msg, List<String> stepsList, Integer cLine, String sTrace, String actName) {
            this.severityLevel = sLevel;
            this.generalMessage = msg;
            this.stepsToFix = stepsList;
            this.codeLine = cLine;
            this.stackTrace = sTrace;
            this.actionName = actName;
        }
    }

    /**
     * Wrapper class for Lightning Page Alerts
     */
    public class AlertWrapper {
        @AuraEnabled
        public String variant { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public Boolean dismissible { get; set; }
        @AuraEnabled
        public Boolean isBlocker { get; set; }

        // CTOR

        public AlertWrapper(String variant, String message) {
            this.variant = variant;
            this.message = message;
            this.dismissible = false;
            this.isBlocker = false;
        }

        public AlertWrapper(String variant, String message, Boolean isBlocker) {
            this.variant = variant;
            this.message = message;
            this.dismissible = !isBlocker;
            this.isBlocker = isBlocker;
        }
    }
}