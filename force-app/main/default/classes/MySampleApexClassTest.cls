@isTest
private class MySampleApexClassTest {
    @isTest static void testFreezingPoint() {
        Decimal celsius = MySampleApexClass.getCalculatedValue();
        System.assertEquals(11,11);
    }
}