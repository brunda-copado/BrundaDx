public with sharing class SalesforceAPIProxySoapCallout extends HerokuCallout {
    // CTOR

    public SalesforceAPIProxySoapCallout() {
        super(Settings.server_url + '/json/v1/proxyOrgRequest/soap', HttpMethod.POST);
    }
}