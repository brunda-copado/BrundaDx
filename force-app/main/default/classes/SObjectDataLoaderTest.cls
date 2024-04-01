/**
 * Copyright (c) 2012, Andrew Fawcett
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the Andrew Fawcett, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
 * Test class for SObjectDataLoader
 *
 *   See https://github.com/afawcett/apex-sobjectdataloader for known issues, restrictions and TODO's
 *
 **/
@IsTest
private class SObjectDataLoaderTest {
    /*
    * Donot save an record subcomponent if error occurs
    */
     @isTest(seeAllData=False)
     private static void unorderedRecordsinJsonWontFailWithConfig() {
    	// Setup
        String jsonString = '{"RecordSetBundles":[{"Records":[{"attributes":{"type":"Contact","url":"/services/data/v29.0/sobjects/Contact/003b000000NStFRAA1"},'+
        '"IsEmailBounced":false,"HasOptedOutOfFax":false,"LastModifiedDate":"2014-03-01T12:32:28.000+0000","HasOptedOutOfEmail":false,'+
        '"LastName":"MyContact","DoNotCall":false,"AccountId":"001b000000P8LZgAAN","SystemModstamp":"2014-03-01T12:32:28.000+0000","CreatedDate":"2014-03-01T12:11:58.000+0000",'+
        '"IsDeleted":false,"Id":"003b000000NStFRAA1"}],"ObjectType":"Contact"},{"Records":[{"attributes":{"type":"Account","url":"/services/data/v29.0/sobjects/Account/001b000000P8LZgAAN"},'+
        '"Name":"ChildAccount","ParentId":"001b000000PBLqsAAH","SystemModstamp":"2014-03-06T06:04:38.000+0000","CreatedDate":"2014-03-01T11:42:34.000+0000",'+
        '"LastModifiedDate":"2014-03-06T06:04:38.000+0000","IsDeleted":false,"Id":"001b000000P8LZgAAN"},{"attributes":{"type":"Account","url":"/services/data/v29.0/sobjects/Account/001b000000PBLqsAAH"},'+
        '"Name":"Parent Account","SystemModstamp":"2014-03-06T06:04:15.000+0000","CreatedDate":"2014-03-06T06:04:15.000+0000","LastModifiedDate":"2014-03-06T06:04:15.000+0000",'+
        '"IsDeleted":false,"Id":"001b000000PBLqsAAH"}],"ObjectType":"Account"}]}';

 		// Execute
 		Exception unexpected = null;
 		try {
        	SObjectDataLoader.deserialize(jsonString, new TestCallback());
 		}
 		catch(DmlException dmlEx) {
 			unexpected = dmlEx;
 		}

        //Verify
        System.assertEquals(null, unexpected);
    }

    @isTest(seeAllData=False)
    private static void reportLimitExceptions() {
    	Account accountObj = new Account(Name ='Account1');
        insert accountObj;
        List<Account> accList =[select Id from Account];
		for(Integer i=0;i<100;i++)
		{
			accList[0].Id.getSObjectType().getDescribe();
		}
    	String error ='';
    	Set<Id> idToSerialize = new Set<ID>();
    	idToSerialize.add(accountObj.Id);
    	try
    	{
    		SObjectDataLoader.serialize(idToSerialize);
    	}
    	catch(Exception e)
    	{
    		error = e.getMessage();
    	}
    	system.assert(String.isBlank(error));
	}

    @isTest(seeAllData=False)
    private static void userFieldBlackListTest() {
    	Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig> strategyBySObjectType = new Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig>();
	 	Map<String,List<String>> fieldBlackListMap = new Map<String,List<String>>();
	 	fieldBlackListMap.put('Account',new List<String>{'Site'});
	 	Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
    	Schema.SObjectType accSObjectType = globalDescribeMap.get('Account');
		SObject acc = accSObjectType.newSObject();
		acc.put('Name', 'testAccount');
		acc.put('Site', 'testSite');
        insert acc;

    	Schema.SObjectType conSObjectType = globalDescribeMap.get('Contact');
		SObject con = conSObjectType.newSObject();
		con.put('LastName','testContact');
        con.put('AccountId',acc.Id);
		insert con;

		Schema.SObjectType sObjectType = acc.Id.getSObjectType();
		if(strategyBySObjectType.get(sObjectType)==null)
		{
			SObjectDataLoader.SerializeConfig config = new SObjectDataLoader.SerializeConfig().addToUserFieldBlackList(fieldBlackListMap);
			strategyBySObjectType.put(sObjectType,config.auto(acc.Id.getSObjectType()));
		}
		String jsonString = SObjectDataLoader.serialize(new Set<Id>{acc.Id}, strategyBySObjectType);
		system.assert(!jsonString.contains('testSite'),jsonString);
		system.assert(jsonString.contains('Contact'),jsonString);
	}

    @isTest(seeAllData=False)
	private static void userChildBlackListTest() {
		Id idToSerialize;
    	Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig> strategyBySObjectType = new Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig>();
	 	Map<String,List<String>> childRelationshipBlackListMap = new Map<String,List<String>>();
	 	childRelationshipBlackListMap.put('Account',new List<String>{'Contacts'});
	 	Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
    	Schema.SObjectType accSObjectType = globalDescribeMap.get('Account');
		SObject acc = accSObjectType.newSObject();
		acc.put('Name', 'testAccount');
		acc.put('Site', 'testSite');
        insert acc;

    	idToSerialize = acc.Id;
    	Schema.SObjectType conSObjectType = globalDescribeMap.get('Contact');
		SObject con = conSObjectType.newSObject();
		con.put('LastName','testContact');
        con.put('AccountId',acc.Id);
		insert con;

		Schema.SObjectType sObjectType = acc.Id.getSObjectType();
		if(strategyBySObjectType.get(sObjectType)==null)
		{
			SObjectDataLoader.SerializeConfig config = new SObjectDataLoader.SerializeConfig().addToUserChildRelationShipBlackList(childRelationshipBlackListMap);
			strategyBySObjectType.put(sObjectType,config.auto(idToSerialize.getSObjectType()));
		}
		String jsonString = SObjectDataLoader.serialize(new Set<Id>{idToSerialize}, strategyBySObjectType);
		system.assert(jsonString.contains('testSite'),jsonString);
		system.assert(!jsonString.contains('Contact'),jsonString);
    }

    @isTest(seeAllData=False)
	private static void userFieldBlackListTestWithPackageBlaclist() {
		Id idToSerialize;
    	Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig> strategyBySObjectType = new Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig>();
	 	Map<String,List<String>> fieldBlackListMap = new Map<String,List<String>>();
	 	fieldBlackListMap.put('Account',new List<String>{'Site'});
	 	Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
    	Schema.SObjectType accSObjectType = globalDescribeMap.get('Account');
		SObject acc = accSObjectType.newSObject();
		acc.put('Name', 'testAccount');
		acc.put('Site', 'testSite');
        insert acc;

    	idToSerialize = acc.Id;
    	Schema.SObjectType conSObjectType = globalDescribeMap.get('Contact');
		SObject con = conSObjectType.newSObject();
		con.put('LastName','testContact');
        con.put('AccountId',acc.Id);
		insert con;

		Set<String> packageNamespaceSet = new Set<String>{'abcd','pqrs'};
		Schema.SObjectType sObjectType = acc.Id.getSObjectType();
		if(strategyBySObjectType.get(sObjectType)==null)
		{
			SObjectDataLoader.SerializeConfig config = new SObjectDataLoader.SerializeConfig().addToBlacklistedNamespace(packageNamespaceSet).addToUserFieldBlackList(fieldBlackListMap);
			strategyBySObjectType.put(sObjectType,config.auto(idToSerialize.getSObjectType()));
		}
		String jsonString = SObjectDataLoader.serialize(new Set<Id>{idToSerialize}, strategyBySObjectType);
		system.assert(!jsonString.contains('testSite'),jsonString);
		system.assert(jsonString.contains('Contact'),jsonString);
	}
    
	@isTest(seeAllData=False)
    private static void userChildBlackListTestWithPackageBlaclist() {
		Id idToSerialize;
    	Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig> strategyBySObjectType = new Map <Schema.SObjectType,SObjectDataLoader.SerializeConfig>();
	 	Map<String,List<String>> childRelationshipBlackListMap = new Map<String,List<String>>();
	 	childRelationshipBlackListMap.put('Account',new List<String>{'Contacts'});
	 	Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
    	Schema.SObjectType accSObjectType = globalDescribeMap.get('Account');
		SObject acc = accSObjectType.newSObject();
		acc.put('Name', 'testAccount');
		acc.put('Site', 'testSite');
        insert acc;

    	idToSerialize = acc.Id;
    	Schema.SObjectType conSObjectType = globalDescribeMap.get('Contact');
		SObject con = conSObjectType.newSObject();
		con.put('LastName','testContact');
		con.put('AccountId',acc.Id);
		insert con;

		Set<String> packageNamespaceSet = new Set<String>{'abcd','pqrs'};
		Schema.SObjectType sObjectType = acc.Id.getSObjectType();
		if(strategyBySObjectType.get(sObjectType)==null)
		{
			SObjectDataLoader.SerializeConfig config = new SObjectDataLoader.SerializeConfig().addToBlacklistedNamespace(packageNamespaceSet).addToUserChildRelationShipBlackList(childRelationshipBlackListMap);
			strategyBySObjectType.put(sObjectType,config.auto(idToSerialize.getSObjectType()));
		}
		String jsonString = SObjectDataLoader.serialize(new Set<Id>{idToSerialize}, strategyBySObjectType);
		system.assert(jsonString.contains('testSite'),jsonString);
		system.assert(!jsonString.contains('Contact'),jsonString);
	}

    /*
	* Test  creating a map from json file
	*/
	@isTest(seeAllData=False)
	private static void testdeserializedRecords() {
		String accountRecordJsonFile ='{"RecordSetBundles":[{"Records":[{"attributes":{"type":"Account","url":"/services/data/v31.0/sobjects/Account/001b000000dPPN3AAO"},"Name":"TestAccount","SystemModstamp":"2014-09-29T05:06:08.000+0000","CreatedDate":"2014-09-29T05:06:08.000+0000","LastModifiedDate":"2014-09-29T05:06:08.000+0000","IsDeleted":false,"Id":"001b000000dPPN3AAO"}],"ObjectType":"Account"}]}';
		Map<String,List<Sobject>> recordBundleMap = new Map<String,List<Sobject>>();
		recordBundleMap = SObjectDataLoader.deserializedRecords(accountRecordJsonFile);
		System.assert(recordBundleMap.keyset().contains('Account'));
		List<Account> accList = (List<Account>)recordBundleMap.get('Account');
		System.assertEquals(accList[0].Name,'TestAccount');
    }


    // INNER CLASSES

    public class TestCallback implements SObjectDataLoader.IDeserializeCallback {
		@SuppressWarnings('PMD.EmptyStatementBlock')
		public void unresolvedReferences(SObjectType soType, List<SObjectDataLoader.UnresolvedReferences> unresolved) {
			//doAnything
		}
	}
}