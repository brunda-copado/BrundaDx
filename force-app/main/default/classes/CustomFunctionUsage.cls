/**
 * Class: CustomFunctionUsage
 * 
 * Purpose:
 * This class is designed to manage and report on the consumption of function credits within our Salesforce application securely. 
 * It leverages protected custom settings to safeguard credit data, preventing direct modification by end-users while 
 * allowing them to monitor their monthly credit usage. This balance ensures data integrity and security without 
 * sacrificing transparency and accessibility for customers and extensions.
 * 
 * Implementation Note:
 * The class is declared with 'without sharing' to ensure it accesses the necessary data regardless of the 
 * executing user's permissions. This approach is essential for providing consistent access to credit usage data 
 * across various user profiles and permission sets, thereby maintaining uniform functionality throughout the application.
 */
public without sharing class CustomFunctionUsage {

    /**
     * Method: getUsage
     * 
     * Purpose:
     * Retrieves the number of function credits consumed by the customer for a specified month. This method 
     * queries the protected CustomFunctionUsage__c custom setting to fetch the latest credit usage data. 
     * The approach ensures data accuracy and security by directly accessing the protected custom setting.
     * 
     * Parameters:
     * - year (Integer): The year for which credit usage information is requested.
     * - month (Integer): The month within the specified year for which credit usage information is requested.
     * 
     * Returns:
     * Integer - The number of credits consumed in the specified month. Returns 0 if no records are found for the 
     * specified month and year, indicating no usage or that the data is not available.
     * 
     * Implementation Note:
     * The method dynamically filters records for the specified year and month using the input parameters, 
     * ensuring the returned data is specific to the request. The query is executed with the 'WITH SYSTEM_MODE' 
     * clause, which overrides the default sharing rules and permissions, allowing the query to run with the full
     * privileges of the system. This ensures that the query can access all relevant records regardless of the current
     * user's permission level or the record's sharing settings, providing a consistent and comprehensive data 
     * retrieval process essential for system-level operations and administrative tasks.
     */
    public static Integer getUsage(Integer year, Integer month){

        List<CustomFunctionUsage__c> cfU = [
            SELECT Credits__c
            FROM CustomFunctionUsage__c
            WHERE CALENDAR_YEAR(Year_Month__c) = :year AND CALENDAR_MONTH(Year_Month__c) = :month
            WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return cfU != null && !cfU.isEmpty() ? (Integer)cfU[0].Credits__c : 0;
    }
}