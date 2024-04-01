/**
 * Copyright (c), FinancialForce.com, inc
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
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
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

@IsTest
private with sharing class fflib_SObjectDomainTest {
    @IsTest
    private static void itShouldReturnTheChangedRecordsBySObjectFields() {
        // GIVEN a domain with old and changed records

        Id idLuke = fflib_IDGenerator.generate(Account.SObjectType);
        Id idHan = fflib_IDGenerator.generate(Account.SObjectType);
        Id idLeia = fflib_IDGenerator.generate(Account.SObjectType);
        List<Account> oldRecords = new List<Account>{
            new Account(Id = idLuke, Name = 'Luke', Description = 'Jedi'),
            new Account(Id = idHan, Name = 'Han', Description = 'Pilot'),
            new Account(Id = idLeia, Name = 'Leia')
        };

        List<Account> newRecords = oldRecords.deepClone(true, true, true);
        newRecords.get(0).Name = 'Luke SkyWalker';
        newRecords.get(0).Description = 'Jedi Master';
        newRecords.get(1).Name = 'Han Solo';
        Accounts accounts = new Accounts(newRecords);
        accounts.ExistingRecords = new Map<Id, SObject>(oldRecords);

        // WHEN we create a domain with ExistingRecords and request the changed records
        List<SObject> result = accounts.getChangedRecords(new Set<Schema.SObjectField>{ Account.Name, Account.Description });

        // THEN it should only return the changed records
        Map<Id, SObject> resultMap = new Map<Id, SObject>(result);
        System.assertEquals(2, result.size());
        System.assert(resultMap.containsKey(idLuke));
        System.assert(resultMap.containsKey(idHan));
    }

    @IsTest
    private static void itShouldReturnTheChangedRecordsByStringFields() {
        // GIVEN a domain with old and changed records

        Id idLuke = fflib_IDGenerator.generate(Account.SObjectType);
        Id idHan = fflib_IDGenerator.generate(Account.SObjectType);
        Id idLeia = fflib_IDGenerator.generate(Account.SObjectType);
        List<Account> oldRecords = new List<Account>{
            new Account(Id = idLuke, Name = 'Luke', Description = 'Jedi'),
            new Account(Id = idHan, Name = 'Han', Description = 'Pilot'),
            new Account(Id = idLeia, Name = 'Leia')
        };

        List<Account> newRecords = oldRecords.deepClone(true, true, true);
        newRecords.get(0).Name = 'Luke SkyWalker';
        newRecords.get(0).Description = 'Jedi Master';
        newRecords.get(1).Name = 'Han Solo';
        Accounts accounts = new Accounts(newRecords);
        fflib_SObjectDomain.Test.Database.onUpdate(newRecords, new Map<Id, SObject>(oldRecords));

        // WHEN we create a domain with ExistingRecords and request the changed records
        List<SObject> result = accounts.getChangedRecords(new Set<String>{ 'Name', 'Description' });

        // THEN it should only return the changed records
        Map<Id, SObject> resultMap = new Map<Id, SObject>(result);
        System.assertEquals(2, result.size());
        System.assert(resultMap.containsKey(idLuke));
        System.assert(resultMap.containsKey(idHan));
    }
    
    @IsTest
	private static void testErrorLogging()
	{	
		// Test static helpers for raise none domain object instance errors
		Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );		
		fflib_SObjectDomain.Errors.error('Error', opp);
		fflib_SObjectDomain.Errors.error('Error', opp, Opportunity.Type);
		System.assertEquals(2, fflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('Error', fflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals('Error', fflib_SObjectDomain.Errors.getAll()[1].message);
		System.assertEquals(Opportunity.Type, ((fflib_SObjectDomain.FieldError)fflib_SObjectDomain.Errors.getAll()[1]).field);
		fflib_SObjectDomain.Errors.clearAll();		
		System.assertEquals(0, fflib_SObjectDomain.Errors.getAll().size());		
	}

    /**
     * Create test user
     **/
    private static User createChatterExternalUser() {
        // Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
        List<Profile> testProfiles = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Chatter External' LIMIT 1];
        if (testProfiles.size() != 1)
            return null;

        // Can only proceed with test if we can successfully insert a test user
        String testUsername = System.now().format('yyyyMMddhhmmss') + '@testorg.com';
        User testUser = new User(
            Alias = 'test1',
            Email = 'testuser1@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfiles[0].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = testUsername
        );
        try {
            insert testUser;
        } catch (Exception e) {
            return null;
        }
        return testUser;
    }

    private class Accounts extends fflib_SObjectDomain {
        public Accounts(List<SObject> records) {
            super(records);
        }
    }
}