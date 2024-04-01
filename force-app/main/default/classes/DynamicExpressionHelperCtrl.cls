public with sharing class DynamicExpressionHelperCtrl {
    // PUBLIC
    @AuraEnabled(cacheable=true)
    public static List<String> getApexExpressionOptions() {
        List<String> result = new List<String>();
        try {
            for (ApexTypeImplementor impl : [
                SELECT ClassNamespacePrefix, ClassName
                FROM ApexTypeImplementor
                WHERE InterfaceName = 'ParameterExpressionCallable'
                WITH USER_MODE
            ]) {
                String className = String.isNotBlank(impl.ClassNamespacePrefix) ? impl.ClassNamespacePrefix + '.' + impl.ClassName : impl.ClassName;
                result.add(className);
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }

        return result;
    }
}