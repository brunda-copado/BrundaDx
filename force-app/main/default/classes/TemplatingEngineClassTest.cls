@SuppressWarnings('PMD')
@IsTest
private class TemplatingEngineClassTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createDeploymentJob();
        }
    }

    @IsTest
    private static void parseWithoutContextId() {
        // Setup
        Exception expectedException = null;
        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', 'value') };

        // Exercise
        try {
            new TemplatingEngine(null, parameters).parse();
            new TemplatingEngine('', parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areEqual(null, expectedException);
    }

    @IsTest
    private static void parseWithInvalidParameterName() {
        // Setup
        Exception expectedException = null;
        List<Parameter> parameters = new List<Parameter>{ new Parameter('Invalid Name', 'value') };

        // Exercise
        try {
            new TemplatingEngine('', parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
    }

    @IsTest
    private static void parseWithInvalidDynamicExpression() {
        // Setup
        Exception expectedException = null;
        List<Parameter> parameters = new List<Parameter>{ new Parameter('InvalidExpression', '{$Invalid.Expression}').required(true) };

        // Exercise
        try {
            new TemplatingEngine('', parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
    }

    @IsTest
    private static void parseInvalidExpressionFalsePositive() {
        // Setup
        Exception expectedException = null;

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('json', '{}'),
            new Parameter('json', '{"x": ""}'),
            new Parameter('json', '{".": ""}')
        };

        // Exercise
        try {
            new TemplatingEngine(null, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areEqual(null, expectedException);
    }

    @IsTest
    private static void parseHardCodedValues() {
        // Setup
        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', 'value') };

        // Exercise
        List<Parameter> result = new TemplatingEngine(null, parameters).parse();

        // Verify
        Assert.areEqual(1, result.size());
        Assert.areEqual('value', result[0].value);
    }

    @IsTest
    private static void parseUserTemplate() {
        // Setup
        String firstNamePattern = UserInfo.getFirstName() + '*';

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$User.Name}'),
            new Parameter('key', '{$User.Name.matches("' + firstNamePattern + '")}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(null, parameters).parse();

        // Verify
        Assert.areEqual(2, result.size());

        Assert.areEqual(UserInfo.getName(), result[0].value);
        Assert.areEqual(false, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(false, result[1].sensitive);
    }

    @IsTest
    private static void parseUserTemplateCaseInsensitive() {
        // Setup
        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', '{$uSeR.naMe}') };

        // Exercise
        List<Parameter> result = new TemplatingEngine(null, parameters).parse();

        // Verify
        Assert.areEqual(1, result.size());
        Assert.areEqual(UserInfo.getName(), result[0].value);
    }

    @IsTest
    private static void parseSourceTemplateWithInValidField() {
        // Setup
        Exception expectedException = null;
        Deployment_Job__c job = [SELECT Id FROM Deployment_Job__c LIMIT 1];

        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', '{$Source.InvalidField}') };

        // Exercise
        try {
            new TemplatingEngine(job.Id, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
    }

    @IsTest
    private static void parseSourceTemplateWithInValidProperty() {
        // Setup
        Exception expectedException = null;
        Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', '{$Source.Property.Invalid}') };

        // Exercise
        try {
            new TemplatingEngine(job.Id, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areEqual(null, expectedException);
    }

    @IsTest
    private static void parseSystemExpressioneWithWrongName() {
        // Setup
        Exception expectedException;

        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', '{$Source.DB}') };

        // Exercise
        try {
            new TemplatingEngine(project.Id, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        String message = String.format('{0}Source_Id__c can not be found on Project', new List<String>{ Settings.ns });
        Assert.areNotEqual(null, expectedException, 'An exception should be thrown');
        Assert.areEqual(message, expectedException.getMessage(), 'There is an error in parsing the expression');
    }

    @IsTest
    private static void parseSourceTemplateWithInSensitiveValue() {
        // Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

        new SystemProperty().value('sql server').apiName('DB').sensitive(false).parent(job.Source_Id__c).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$Source.Property.DB}'),
            new Parameter('key', '{$Source.Property.DB.matches(sql*)}'),
            new Parameter('key', '{$Source.Property.DB.matches(nosql*)}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();

        // Verify
        Assert.areEqual(3, result.size());

        Assert.areEqual('sql server', result[0].value);
        Assert.areEqual(false, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(false, result[1].sensitive);

        Assert.areEqual('false', result[2].value);
        Assert.areEqual(false, result[2].sensitive);
    }

    @IsTest
    private static void parseSourceEnvPropertyWithEnvAsContext() {
        // Setup
        Environment__c env = [SELECT Id, Name FROM Environment__c WHERE Name = 'Environment 1' LIMIT 1];

        new SystemProperty().value('sql server').apiName('DB').sensitive(false).parent(env.Id).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$Context.Property.DB}'),
            new Parameter('key', '{$Context.Property.DB.matches(sql*)}'),
            new Parameter('key', '{$Context.Property.DB.matches(nosql*)}'),
            new Parameter('key', '{$Context.Name}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(env.Id, parameters).parse();

        // Verify
        Assert.areEqual(4, result.size());

        Assert.areEqual('sql server', result[0].value);
        Assert.areEqual(false, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(false, result[1].sensitive);

        Assert.areEqual('false', result[2].value);
        Assert.areEqual(false, result[2].sensitive);

        Assert.areEqual('Environment 1', result[3].value);
    }

    @IsTest
    private static void parsePipelinePropertyWithSobjectAsContext() {
        // Setup
        Deployment_Flow__c pipeline = [SELECT Id, Main_Branch__c FROM Deployment_Flow__c LIMIT 1];

        new SystemProperty().value('sql server').apiName('DB').sensitive(false).parent(pipeline.Id).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$Context.Property.DB}'),
            new Parameter('key', '{$Context.Property.DB.matches(sql*)}'),
            new Parameter('key', '{$Context.Property.DB.matches(nosql*)}'),
            new Parameter('key', '{$Context.Main_Branch__c}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(pipeline.Id, parameters).parse();

        // Verify
        Assert.areEqual(4, result.size());

        Assert.areEqual('sql server', result[0].value);
        Assert.areEqual(false, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(false, result[1].sensitive);

        Assert.areEqual('false', result[2].value);
        Assert.areEqual(false, result[2].sensitive);

        Assert.areEqual('main', result[3].value);
    }

    @IsTest
    private static void parseSystemPropertyWithSobjectAsContext() {
        // Setup
        User_Story__c userStory = [SELECT Id, Exclude_From_CBM__c FROM User_Story__c LIMIT 1];

        new SystemProperty().value('user story property').apiName('USP').sensitive(false).parent(userStory.Id).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$Context.Property.USP}'),
            new Parameter('key', '{$CONTEXT.Property.USP.matches(user*)}'),
            new Parameter('key', '{$context.Property.USP.matches(nosql*)}'),
            new Parameter('key', '{$Context.Exclude_From_CBM__c}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(userStory.Id, parameters).parse();

        // Verify
        Assert.areEqual(4, result.size());

        Assert.areEqual('user story property', result[0].value);
        Assert.areEqual(false, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(false, result[1].sensitive);

        Assert.areEqual('false', result[2].value);
        Assert.areEqual(false, result[2].sensitive);

        Assert.areEqual('false', result[3].value);
    }

    @IsTest
    private static void parseGlobalTemplateWithInSensitiveValue() {
        // Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

        new SystemProperty().value('sql server').apiName('DB').sensitive(false).globalProperty(true).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$Global.Property.DB}'),
            new Parameter('key', '{$Global.Property.DB.matches(sql*)}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(null, parameters).parse();

        // Verify
        Assert.areEqual(2, result.size());

        Assert.areEqual('sql server', result[0].value);
        Assert.areEqual(false, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(false, result[1].sensitive);
    }

    @isTest
    private static void parseUserExpressionWithoutContextId() {
        //Setup
        new SystemProperty().value('user/sql').apiName('UserDB').sensitive(false).parent(UserInfo.getUserId()).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('usersql', '{$User.Property.UserDB}'),
            new Parameter('usersql', '{$User.Property.UserDB.matches("user*")}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(null, parameters).parse();

        // Verify
        Assert.areEqual(2, result.size());
        Assert.areEqual('user/sql', result[0].value);
        Assert.areEqual('true', result[1].value);
    }

    private static void parseSystemExpressionWithoutContextId() {
        //Setup
        Exception expectedException = null;
        Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];
        Test.setMock(WebServiceMock.class, new MdApiMock());

        new SystemProperty().value('sql global').apiName('GlobalDB').sensitive(false).globalProperty(true).persist();

        new SystemProperty().value('sql source').apiName('SourceDB').sensitive(true).parent(job.Source_Id__c).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('GlobalDB', '{$Global.Property.DB}'),
            new Parameter('GlobalDB', '{$Global.Property.DB.matches(sql*)}'),
            new Parameter('SourceDB', '{$Source.Property.DB}'),
            new Parameter('SourceDB', '{$Source.Property.DB.matches(sql*)}')
        };

        // Exercise
        try {
            new TemplatingEngine(null, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException, 'An exception should be thrown');
        Assert.areEqual(
            String.format(Label.invalidContextId, new List<String>{ '{$Source.Property.DB}', Label.Record }),
            expectedException.getMessage(),
            'Exception does not match'
        );
    }

    @isTest
    private static void parseMixedExpressionWithoutContextId() {
        //Setup
        Exception expectedException = null;
        Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];
        Test.setMock(WebServiceMock.class, new MdApiMock());

        new SystemProperty().value('user/sql').apiName('UserDB').sensitive(false).parent(UserInfo.getUserId()).persist();

        new SystemProperty().value('sql source').apiName('SourceDB').sensitive(true).parent(job.Source_Id__c).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('usersql', '{$User.Property.UserDB}'),
            new Parameter('usersql', '{$User.Property.UserDB.matches("user*")}'),
            new Parameter('SourceDB', '{$Source.Property.DB}'),
            new Parameter('SourceDB', '{$Source.Property.DB.matches(sql*)}')
        };

        // Exercise
        try {
            new TemplatingEngine(null, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException, 'An exception should be thrown');
        Assert.areEqual(
            String.format(Label.invalidContextId, new List<String>{ '{$Source.Property.DB}', Label.Record }),
            expectedException.getMessage(),
            'Exception does not match'
        );
    }

    @IsTest
    private static void parseSourceTemplateWithSensitiveValue() {
        // Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];
        Test.setMock(WebServiceMock.class, new MdApiMock());

        new SystemProperty().value('sql server').apiName('DB').sensitive(true).parent(job.Source_Id__c).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$Source.Property.DB}'),
            new Parameter('key', '{$Source.Property.DB.matches(sql*)}'),
            new Parameter('key', '{$Source.Property.DB.matches(nosql*)}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();

        // Verify
        Assert.areEqual(3, result.size());

        Assert.areEqual('sql server', result[0].value);
        Assert.areEqual(true, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(true, result[1].sensitive);

        Assert.areEqual('false', result[2].value);
        Assert.areEqual(true, result[2].sensitive);
    }

    @IsTest
    private static void parseMixedTemplateWithInSensitiveValue() {
        // Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM Deployment_Job__c LIMIT 1];

        new SystemProperty().value('source/sql').apiName('SourceDB').sensitive(false).parent(job.Source_Id__c);
        new SystemProperty().value('destination/sql').apiName('DestinationDB').sensitive(false).parent(job.Destination_Id__c);
        new SystemProperty().value('pipeline/sql').apiName('PipelineDB').sensitive(false).parent(job.Pipeline_Id__c);
        new SystemProperty().value('user/sql').apiName('UserDB').sensitive(false).parent(UserInfo.getUserId()).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('SourceDB', '{$Source.Property.SourceDB}'),
            new Parameter('SourceDB', '{$Source.Property.SourceDB.matches("source*")}'),
            new Parameter('DestinationDB', '{$Destination.Property.DestinationDB}'),
            new Parameter('DestinationDB', '{$Destination.Property.DestinationDB.matches("destination*")}'),
            new Parameter('PipelineDB', '{$Pipeline.Property.PipelineDB}'),
            new Parameter('PipelineDB', '{$Pipeline.Property.PipelineDB.matches("pipeline*")}'),
            new Parameter('usersql', '{$User.Property.UserDB}'),
            new Parameter('usersql', '{$User.Property.UserDB.matches("user*")}'),
            new Parameter('HardcodedKey', 'hardcodedValue')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();

        // Verify
        Assert.areEqual(9, result.size());
        Assert.areEqual('source/sql', result[0].value);
        Assert.areEqual('true', result[1].value);
        Assert.areEqual('destination/sql', result[2].value);
        Assert.areEqual('true', result[3].value);
        Assert.areEqual('pipeline/sql', result[4].value);
        Assert.areEqual('true', result[5].value);
        Assert.areEqual('user/sql', result[6].value);
        Assert.areEqual('true', result[7].value);
        Assert.areEqual('hardcodedValue', result[8].value);
    }

    @IsTest
    private static void parseMixedTemplateWithSensitiveValue() {
        // Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM Deployment_Job__c LIMIT 1];
        Test.setMock(WebServiceMock.class, new MdApiMock());

        new SystemProperty().value('source/sql').apiName('SourceDB').sensitive(true).parent(job.Source_Id__c);
        new SystemProperty().value('destination/sql').apiName('DestinationDB').sensitive(true).parent(job.Destination_Id__c);
        new SystemProperty().value('pipeline/sql').apiName('PipelineDB').sensitive(true).parent(job.Pipeline_Id__c);
        new SystemProperty().value('user/sql').apiName('UserDB').sensitive(true).parent(UserInfo.getUserId()).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('SourceDB', '{$Source.Property.SourceDB}'),
            new Parameter('DestinationDB', '{$Destination.Property.DestinationDB}'),
            new Parameter('PipelineDB', '{$Pipeline.Property.PipelineDB}'),
            new Parameter('UserDB', '{$User.Property.UserDB}'),
            new Parameter('HardcodedKey', 'hardcodedValue')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();

        // Verify
        Assert.areEqual(5, result.size());
        Assert.areEqual('source/sql', result[0].value);
        Assert.areEqual(true, result[0].sensitive);

        Assert.areEqual('destination/sql', result[1].value);
        Assert.areEqual(true, result[1].sensitive);

        Assert.areEqual('pipeline/sql', result[2].value);
        Assert.areEqual(true, result[2].sensitive);

        Assert.areEqual('user/sql', result[3].value);
        Assert.areEqual(true, result[3].sensitive);

        Assert.areEqual('hardcodedValue', result[4].value);
        Assert.areEqual(false, result[4].sensitive);
    }

    @IsTest
    private static void parseDynamicEnvironmentFromJobStepContext_UserStoryCommit() {
        // Setup
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            Test.startTest();
            Org__c credential = [SELECT Id FROM Org__c LIMIT 1];

            User_Story_Commit__c commitRecord = (User_Story_Commit__c) new UserStoryCommit(new SnapshotCommit().credentialId(credential.Id))
                .userStoryId([SELECT Id FROM User_Story__c LIMIT 1].Id)
                .persist();

            new JobExecution()
                .status('In Progress')
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .parentRecord(commitRecord.Id)
                .add(new JobStep().name('step1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM JobStep__c LIMIT 1];

            Test.setMock(WebServiceMock.class, new MdApiMock());
            new SystemProperty().value('source/sql').apiName('SourceDB').sensitive(true).parent(step.Source_Id__c).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Context.Credential.Endpoint}'),
                new Parameter('EnvironmentField', '{$Context.Environment.Name}'),
                new Parameter('sourceDB', '{$Context.Property.SourceDB}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(3, result.size());
            Assert.areEqual('Environment 1', result[1].value);
            Assert.areEqual('source/sql', result[2].value);
        }
    }

    @IsTest
    private static void parseDynamicEnvironmentFromJobStepContext_Promotion() {
        // Setup
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            Promotion__c promotion = [SELECT Id FROM Promotion__c LIMIT 1];

            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .parentRecord(promotion.Id)
                .add(new JobStep().name('step1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM JobStep__c LIMIT 1];

            Test.setMock(WebServiceMock.class, new MdApiMock());
            new SystemProperty().value('source/sql').apiName('SourceDB').sensitive(true).parent(step.Source_Id__c).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Context.Credential.Endpoint}'),
                new Parameter('EnvironmentField', '{$Context.Environment.Name}'),
                new Parameter('sourceDB', '{$Context.Property.SourceDB}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(3, result.size());
            Assert.areEqual('Environment 1', result[1].value);
            Assert.areEqual('source/sql', result[2].value);
        }
    }

    @IsTest
    private static void parseDynamicEnvironmentFromJobStepContext_Deployment() {
        // Setup
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];

            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .parentRecord(deployment.Id)
                .add(new JobStep().name('step1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM JobStep__c LIMIT 1];

            Test.setMock(WebServiceMock.class, new MdApiMock());
            new SystemProperty().value('source/sql').apiName('SourceDB').sensitive(true).parent(step.Destination_Id__c).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Context.Credential.Endpoint}'),
                new Parameter('EnvironmentField', '{$Context.Environment.Name}'),
                new Parameter('sourceDB', '{$Context.Property.SourceDB}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(3, result.size());
            Assert.areEqual('Environment 2', result[1].value);
            Assert.areEqual('source/sql', result[2].value);
        }
    }

    @IsTest
    private static void parseMixedTemplateWithSensitiveValueWithJobStepAsContext() {
        // Setup
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .add(new JobStep().name('step1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM JobStep__c LIMIT 1];

            Test.setMock(WebServiceMock.class, new MdApiMock());

            new SystemProperty().value('source/sql').apiName('SourceDB').sensitive(true).parent(step.Source_Id__c);
            new SystemProperty().value('destination/sql').apiName('DestinationDB').sensitive(true).parent(step.Destination_Id__c);
            new SystemProperty().value('pipeline/sql').apiName('PipelineDB').sensitive(true).parent(step.Pipeline_Id__c);
            new SystemProperty().value('user/sql').apiName('UserDB').sensitive(true).parent(copadoUser.Id).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('SourceDB', '{$Source.Property.SourceDB}'),
                new Parameter('DestinationDB', '{$Destination.Property.DestinationDB}'),
                new Parameter('PipelineDB', '{$Pipeline.Property.PipelineDB}'),
                new Parameter('UserDB', '{$User.Property.UserDB}'),
                new Parameter('HardcodedKey', 'hardcodedValue')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(5, result.size());
            Assert.areEqual('source/sql', result[0].value);
            Assert.areEqual(true, result[0].sensitive);

            Assert.areEqual('destination/sql', result[1].value);
            Assert.areEqual(true, result[1].sensitive);

            Assert.areEqual('pipeline/sql', result[2].value);
            Assert.areEqual(true, result[2].sensitive);

            Assert.areEqual('user/sql', result[3].value);
            Assert.areEqual(true, result[3].sensitive);

            Assert.areEqual('hardcodedValue', result[4].value);
            Assert.areEqual(false, result[4].sensitive);
        }
    }

    @IsTest
    private static void parseSSHRepositoryWithoutRepositoryId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();
            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            Test.startTest();
            List<Parameter> result = new TemplatingEngine(repository.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseHTTPSRepositoryWithoutRepositoryId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = httpsRepository();
            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            Test.startTest();
            List<Parameter> result = new TemplatingEngine(repository.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('https://github.com/user/repository.git', gitCredential.url);
            Assert.areEqual('https', gitCredential.type);
            Assert.areEqual('username', gitCredential.username);
            Assert.areEqual('password', gitCredential.password);
            Assert.areEqual('Extra Headers', gitCredential.extraheaders);
        }
    }

    @IsTest
    private static void parseHTTPSRepositoryWithoutGitJson() {
        Exception expectedException = null;
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = httpsRepository();
            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '').required(true) };

            // Exercise
            try {
                List<Parameter> result = new TemplatingEngine(repository.Id, parameters).parse();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            Assert.areNotEqual(null, expectedException);
            Assert.areEqual(expectedException.getMessage(), Label.MissingGitParameterValue);
        }
    }

    @IsTest
    private static void parseSSHRepositoryWithoutGitJson() {
        Exception expectedException = null;
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();
            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '').required(true) };

            // Exercise
            try {
                List<Parameter> result = new TemplatingEngine(repository.Id, parameters).parse();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            Assert.areNotEqual(null, expectedException);
            Assert.areEqual(expectedException.getMessage(), Label.MissingGitParameterValue);
        }
    }

    @IsTest
    private static void parseRepositoryWithSnapshotIdAsContextId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();

            Test.startTest();
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];

            Git_Backup__c snapshot = new Git_Backup__c();
            snapshot.Git_Repository__c = repository.Id;
            snapshot.Org__c = org.Id;
            insert snapshot;

            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            List<Parameter> result = new TemplatingEngine(snapshot.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @isTest
    private static void parseRepositoryWithSnapshotIdAsParentId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();

            Test.startTest();
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];

            Git_Backup__c snapshot = new Git_Backup__c();
            snapshot.Git_Repository__c = repository.Id;
            snapshot.Org__c = org.Id;
            insert snapshot;

            new JobExecution().snapshot(snapshot.Id).add(new JobStep().result(new Result())).persist();

            JobStep__c step = [SELECT Id FROM JobStep__c LIMIT 1];
            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseRepositoryWithInvalidRepositoryId2() {
        //Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM Deployment_Job__c LIMIT 1];

        List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

        // Exercise
        List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();

        // Verify
        Assert.areEqual(1, result.size());
        Assert.areEqual(null, result[0].value);
    }

    @IsTest
    private static void parseRepositoryWithRepositoryId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();

            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            Test.startTest();
            List<Parameter> result = new TemplatingEngine(repository.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseRepositoryWithSnapshotId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();
            Test.startTest();
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];

            Git_Backup__c snapshot = new Git_Backup__c();
            snapshot.Git_Repository__c = repository.Id;
            snapshot.Org__c = org.Id;
            insert snapshot;

            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            List<Parameter> result = new TemplatingEngine(snapshot.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseRepositoryWithPipelineId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();

            Deployment_Flow__c pipeline = [SELECT Id, Git_Repository__c FROM Deployment_Flow__c LIMIT 1];
            pipeline.Git_Repository__c = repository.Id;

            Test.startTest();
            update pipeline;

            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            List<Parameter> result = new TemplatingEngine(pipeline.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseRepositoryWithDeploymentId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();

            Deployment_Flow__c pipeline = [SELECT Id, Git_Repository__c FROM Deployment_Flow__c LIMIT 1];
            pipeline.Git_Repository__c = repository.Id;

            Test.startTest();
            update pipeline;

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
                .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'Environment 1' LIMIT 1].Id)
                .persist();

            Deployment__c deployment = [SELECT Id, Promotion__c FROM Deployment__c LIMIT 1];
            deployment.Promotion__c = promotion.Id;
            update deployment;

            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            List<Parameter> result = new TemplatingEngine(deployment.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseRepositoryWithUserStoryId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();

            Deployment_Flow__c pipeline = [SELECT Id, Git_Repository__c FROM Deployment_Flow__c LIMIT 1];
            pipeline.Git_Repository__c = repository.Id;

            Test.startTest();
            update pipeline;

            Id userStoryId = [SELECT Id FROM User_Story__c LIMIT 1].Id;

            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            List<Parameter> result = new TemplatingEngine(userStoryId, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseRepositoryWithEncryptedPrivateKey() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Git_Repository__c repository = sshRepository();

            List<Parameter> parameters = new List<Parameter>{ new Parameter('Git_Json', '{$Context.Repository.Credential}') };

            // Exercise
            Test.startTest();
            List<Parameter> result = new TemplatingEngine(repository.Id, parameters).parse();
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url);
            Assert.areEqual('ssh', gitCredential.type);
            Assert.areEqual('publicKey', gitCredential.publicKey);
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey);
        }
    }

    @IsTest
    private static void parseSObjectExpression() {
        //Setup
        Account parentAccount = new Account();
        parentAccount.Name = 'Parent Account';
        insert parentAccount;

        Account account = new Account();
        account.ParentId = parentAccount.Id;
        account.Name = 'Child Account';
        insert account;

        Contact c = new Contact();
        c.LastName = 'Contact';
        c.AccountId = account.Id;
        insert c;

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('ContactName', '{$Context.LastName}'),
            new Parameter('ContactNameMatches', '{$Context.LastName.matches(Cont*)}'),
            new Parameter('AccountName', '{$Context.Account.Name}'),
            new Parameter('AccountName', '{$Context.Account.Name.matches(Child*)}'),
            new Parameter('ParentAccountName', '{$Context.Account.Parent.Name}'),
            new Parameter('ParentAccountName', '{$Context.Account.Parent.Name.matches(Parent*)}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(c.Id, parameters).parse();

        // Verify
        Assert.areEqual(6, result.size());
        Assert.areEqual('Contact', result[0].value);
        Assert.areEqual('true', result[1].value);
        Assert.areEqual('Child Account', result[2].value);
        Assert.areEqual('true', result[3].value);
        Assert.areEqual('Parent Account', result[4].value);
        Assert.areEqual('true', result[5].value);
    }

    @IsTest
    private static void parseSObjectExpressionWithInvalidFields() {
        //Setup
        Exception expectedException = null;
        User copadoUser = getUser();
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('AccountName', '{$Context.InvaildField}'),
            new Parameter('UserName', '{$' + copadoUser.Id + '.Name}')
        };

        // Exercise
        try {
            new TemplatingEngine(account.Id, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
    }

    @IsTest
    private static void parseSObjectExpressionWithExecutionParent() {
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            // Setup
            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .deployment(deployment.Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .persist();

            Test.startTest();
            JobStep__c step = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('branch', '{$Job.ExecutionParent.Name}'),
                new Parameter('branch', '{$Job.ExecutionParent.Name.matches(Test Dev*)}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size());
            Assert.areEqual('Test Dev 1', result[0].value);
            Assert.areEqual('true', result[1].value);
        }
    }

    @IsTest
    private static void parseStepExpressionWithInvalidField() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            //Setup
            Exception expectedException = null;
            Step__c step = [SELECT Id FROM Step__c WHERE Order__c = 2 LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{ new Parameter('PrevStepBranch', '{$Context.PrevStep.InValidFied}') };

            // Exercise
            try {
                new TemplatingEngine(step.Id, parameters).parse();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            Assert.areNotEqual(null, expectedException);
        }
    }

    @IsTest
    private static void parseFirstStepExpression() {
        User copadoUser = getUser();
        Test.startTest();
        System.runAs(copadoUser) {
            // Setup
            List<Step__c> steps = [SELECT Id, Branch__c, JsonResult__c FROM Step__c ORDER BY Order__c DESC];
            steps[1].Branch__c = 'main';
            steps[1]
                .JsonResult__c = '{ "user_stories": ["US-0001","US-0003"], "count": 2, "target_brach": "main", "promotion_brach":"release/v1.0", "user": {"name": "logedInUser"} }';
            update steps[1];

            Destination_Org__c destinationOrg = [SELECT Id FROM Destination_Org__c LIMIT 1];

            Deployment_Job__c firstJob = new Deployment_Job__c(Step__c = steps[1].Id, Destination_Org__c = destinationOrg.Id);
            insert firstJob;

            Deployment_Job__c secondJob = new Deployment_Job__c(Step__c = steps[0].Id, Destination_Org__c = destinationOrg.Id);
            insert secondJob;

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('branch', '{$Job.FirstStep.Branch__c}'),
                new Parameter('branch', '{$Job.FirstStep.Branch__c.matches("main")}'),
                new Parameter('description', '{$Job.FirstStep.Deployment__r.Description__c}'),
                new Parameter('description', '{$Job.FirstStep.Deployment__r.Description__c.matches("Sample*")}'),
                new Parameter('user_stories', '{$Job.FirstStep.JSONResult.user_stories}'),
                new Parameter('user_stories', '{$Job.FirstStep.JSONResult.promotion_brach.matches(release*)}'),
                new Parameter('count', '{$Job.FirstStep.JSONResult.count}'),
                new Parameter('count', '{$Job.FirstStep.JSONResult.count.matches(2)}'),
                new Parameter('userName', '{$Job.FirstStep.JSONResult.user.name}'),
                new Parameter('userName', '{$Job.FirstStep.JSONResult.user.name.matches("logedIn*")}'),
                new Parameter('target_brach', '{$Job.FirstStep.JSONResult.user.target_brach}'),
                new Parameter('target_brach', '{$Job.FirstStep.JSONResult.user.target_brach.matches("something")}'),
                new Parameter('invalidProperty', '{$Job.FirstStep.JSONResult.user.invalidProperty}'),
                new Parameter('invalidProperty', '{$Job.FirstStep.JSONResult.user.invalidProperty.matches("nothing")}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(secondJob.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(14, result.size());
            Assert.areEqual('main', result[0].value);
            Assert.areEqual('true', result[1].value);

            Assert.areEqual('Sample Deployment', result[2].value);
            Assert.areEqual('true', result[3].value);

            Assert.areEqual('["US-0001","US-0003"]', result[4].value);
            Assert.areEqual('true', result[5].value);

            Assert.areEqual('2', result[6].value);
            Assert.areEqual('true', result[7].value);

            Assert.areEqual('logedInUser', result[8].value);
            Assert.areEqual('true', result[9].value);

            Assert.areEqual(null, result[10].value);
            Assert.areEqual('false', result[11].value);

            Assert.areEqual(null, result[12].value);
            Assert.areEqual('false', result[13].value);
        }
    }

    @IsTest
    private static void parsePrevStepExpression() {
        User copadoUser = getUser();
        Test.startTest();
        System.runAs(copadoUser) {
            // Setup
            List<Step__c> steps = [SELECT Id, Branch__c, JsonResult__c FROM Step__c ORDER BY Order__c DESC];
            steps[1].Branch__c = 'main';
            steps[1]
                .JsonResult__c = '{ "user_stories": ["US-0001","US-0003"], "count": 2, "target_brach": "main", "promotion_brach":"release/v1.0", "user": {"name": "logedInUser"} }';
            update steps[1];

            Destination_Org__c destinationOrg = [SELECT Id FROM Destination_Org__c LIMIT 1];

            Deployment_Job__c firstJob = new Deployment_Job__c(Step__c = steps[1].Id, Destination_Org__c = destinationOrg.Id);
            insert firstJob;

            Deployment_Job__c secondJob = new Deployment_Job__c(Step__c = steps[0].Id, Destination_Org__c = destinationOrg.Id);
            insert secondJob;

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('branch', '{$Job.PrevStep.Branch__c}'),
                new Parameter('branch', '{$Job.PrevStep.Branch__c.matches(mai*)}'),
                new Parameter('description', '{$Job.PrevStep.Deployment__r.Description__c}'),
                new Parameter('description', '{$Job.PrevStep.Deployment__r.Description__c.matches(Sample*)}'),
                new Parameter('user_stories', '{$Job.PrevStep.JSONResult.user_stories}'),
                new Parameter('user_stories', '{$Job.PrevStep.JSONResult.promotion_brach.matches(release*)}'),
                new Parameter('count', '{$Job.PrevStep.JSONResult.count}'),
                new Parameter('count', '{$Job.PrevStep.JSONResult.count.matches(2)}'),
                new Parameter('userName', '{$Job.PrevStep.JSONResult.user.name}'),
                new Parameter('userName', '{$Job.PrevStep.JSONResult.user.name.matches("notAUser)}'),
                new Parameter('invalidProperty', '{$Job.PrevStep.JSONResult.user.invalidProperty}'),
                new Parameter('invalidProperty', '{$Job.PrevStep.JSONResult.user.invalidProperty.matches("Nothing")}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(secondJob.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(12, result.size());
            Assert.areEqual('main', result[0].value);
            Assert.areEqual('true', result[1].value);

            Assert.areEqual('Sample Deployment', result[2].value);
            Assert.areEqual('true', result[3].value);

            Assert.areEqual('["US-0001","US-0003"]', result[4].value);
            Assert.areEqual('true', result[5].value);

            Assert.areEqual('2', result[6].value);
            Assert.areEqual('true', result[7].value);

            Assert.areEqual('logedInUser', result[8].value);
            Assert.areEqual('false', result[9].value);

            Assert.areEqual(null, result[10].value);
            Assert.areEqual('false', result[11].value);
        }
    }

    @IsTest
    private static void parseNextStepExpression() {
        User copadoUser = getUser();
        Test.startTest();

        System.runAs(copadoUser) {
            // Setup
            List<Step__c> steps = [SELECT Id, Branch__c, JsonResult__c FROM Step__c ORDER BY Order__c DESC];
            steps[0].Branch__c = 'main';
            steps[0]
                .JsonResult__c = '{ "user_stories": ["US-0001","US-0003"], "count": 2, "target_brach": "main", "promotion_brach":"release/v1.0", "user": {"name": "logedInUser"} }';
            update steps[0];

            Destination_Org__c destinationOrg = [SELECT Id FROM Destination_Org__c LIMIT 1];

            Deployment_Job__c firstJob = new Deployment_Job__c(Step__c = steps[1].Id, Destination_Org__c = destinationOrg.Id);
            insert firstJob;

            Deployment_Job__c secondJob = new Deployment_Job__c(Step__c = steps[0].Id, Destination_Org__c = destinationOrg.Id);
            insert secondJob;

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('branch', '{$Job.NextStep.Branch__c}'),
                new Parameter('branch', '{$Job.NextStep.Branch__c.matches(main)}'),
                new Parameter('description', '{$Job.NextStep.Deployment__r.Description__c}'),
                new Parameter('description', '{$Job.NextStep.Deployment__r.Description__c.matches(Sample*)}'),
                new Parameter('user_stories', '{$Job.NextStep.JSONResult.user_stories}'),
                new Parameter('user_stories', '{$Job.NextStep.JSONResult.promotion_brach.matches(release*)}'),
                new Parameter('count', '{$Job.NextStep.JSONResult.count}'),
                new Parameter('count', '{$Job.NextStep.JSONResult.count.matches(2)}'),
                new Parameter('userName', '{$Job.NextStep.JSONResult.user.name}'),
                new Parameter('userName', '{$Job.NextStep.JSONResult.user.name.matches(logedInUser)}'),
                new Parameter('invalidProperty', '{$Job.NextStep.JSONResult.user.invalidProperty}'),
                new Parameter('invalidProperty', '{$Job.NextStep.JSONResult.user.invalidProperty.matches("Nothing")}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(firstJob.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(12, result.size());
            Assert.areEqual('main', result[0].value);
            Assert.areEqual('true', result[1].value);

            Assert.areEqual('Sample Deployment', result[2].value);
            Assert.areEqual('true', result[3].value);

            Assert.areEqual('["US-0001","US-0003"]', result[4].value);
            Assert.areEqual('true', result[5].value);

            Assert.areEqual('2', result[6].value);
            Assert.areEqual('true', result[7].value);

            Assert.areEqual('logedInUser', result[8].value);
            Assert.areEqual('true', result[9].value);

            Assert.areEqual(null, result[10].value);
            Assert.areEqual('false', result[11].value);
        }
    }

    @IsTest
    private static void parseLastStepExpression() {
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            // Setup
            Step__c step = [SELECT Id, Branch__c, JsonResult__c FROM Step__c WHERE Order__c = 2 LIMIT 1];
            step.Branch__c = 'main';
            step.JsonResult__c = '{ "user_stories": ["US-0001","US-0003"], "count": 2, "target_brach": "main", "promotion_brach":"release/v1.0", "user": {"name": "logedInUser"} }';

            Test.startTest();
            update step;

            Deployment_Job__c job = [SELECT Id FROM Deployment_Job__c LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('branch', '{$Job.LastStep.Branch__c}'),
                new Parameter('branch', '{$Job.LastStep.Branch__c.matches("main")}'),
                new Parameter('description', '{$Job.LastStep.Deployment__r.Description__c}'),
                new Parameter('description', '{$Job.LastStep.Deployment__r.Description__c.matches("Sample*")}'),
                new Parameter('user_stories', '{$Job.LastStep.JSONResult.user_stories}'),
                new Parameter('user_stories', '{$Job.LastStep.JSONResult.promotion_brach.matches(release*)}'),
                new Parameter('count', '{$Job.LastStep.JSONResult.count}'),
                new Parameter('count', '{$Job.LastStep.JSONResult.count.matches(2)}'),
                new Parameter('userName', '{$Job.LastStep.JSONResult.user.name}'),
                new Parameter('userName', '{$Job.LastStep.JSONResult.user.name.matches("NotAUser")}'),
                new Parameter('invalidProperty', '{$Job.LastStep.JSONResult.user.invalidProperty}'),
                new Parameter('invalidProperty', '{$Job.LastStep.JSONResult.user.invalidProperty.matches(Nothing)}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(12, result.size());
            Assert.areEqual('main', result[0].value);
            Assert.areEqual('true', result[1].value);

            Assert.areEqual('Sample Deployment', result[2].value);
            Assert.areEqual('true', result[3].value);

            Assert.areEqual('["US-0001","US-0003"]', result[4].value);
            Assert.areEqual('true', result[5].value);

            Assert.areEqual('2', result[6].value);
            Assert.areEqual('true', result[7].value);

            Assert.areEqual('logedInUser', result[8].value);
            Assert.areEqual('false', result[9].value);

            Assert.areEqual(null, result[10].value);
            Assert.areEqual('false', result[11].value);
        }
    }

    @IsTest
    private static void parseNamedStepExpression() {
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            // Setup
            Step__c step = [SELECT Id, Branch__c, JsonResult__c FROM Step__c WHERE Order__c = 2 LIMIT 1];
            step.Branch__c = 'main';
            step.JsonResult__c = '{ "user_stories": ["US-0001","US-0003"], "count": 2, "target_brach": "main", "promotion_brach":"release/v1.0", "user": {"name": "logedInUser"} }';

            Test.startTest();

            update step;

            Deployment_Job__c job = [SELECT Id FROM Deployment_Job__c LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('branch', '{$Job.Step.Step 2.Branch__c}'),
                new Parameter('description', '{$Job.Step.Step 2.Deployment__r.Description__c}'),
                new Parameter('user_stories', '{$Job.Step.Step 2.JSONResult.user_stories}'),
                new Parameter('count', '{$Job.Step.Step 2.JSONResult.count}'),
                new Parameter('userName', '{$Job.Step.Step 2.JSONResult.user.name}'),
                new Parameter('invalidProperty', '{$Job.Step.Step 2.JSONResult.user.invalidProperty}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(6, result.size());
            Assert.areEqual('main', result[0].value);
            Assert.areEqual(false, result[0].sensitive);
            Assert.areEqual('Sample Deployment', result[1].value);
            Assert.areEqual(false, result[1].sensitive);
            Assert.areEqual('["US-0001","US-0003"]', result[2].value);
            Assert.areEqual('2', result[3].value);
            Assert.areEqual('logedInUser', result[4].value);
            Assert.areEqual(null, result[5].value);
        }
    }

    @IsTest
    private static void parseNamedStepExpressionWithJobStepAsContext() {
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            // Setup
            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .deployment(deployment.Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .add(
                    new JobStep()
                        .name('Step 2')
                        .type('Manual')
                        .order(2)
                        .resultDataJson(
                            '{ "user_stories": ["US-0001","US-0003"], "count": 2, "target_brach": "main", "promotion_brach":"release/v1.0", "user": {"name": "logedInUser"} }'
                        )
                        .configJson('')
                )
                .persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('branch', '{$Job.Step.Step 2.Type__c}'),
                new Parameter('description', '{$Job.Step.Step 2.JobExecution__r.Deployment__r.Name}'),
                new Parameter('user_stories', '{$Job.Step.Step 2.JSONResult.user_stories}'),
                new Parameter('count', '{$Job.Step.Step 2.JSONResult.count}'),
                new Parameter('userName', '{$Job.Step.Step 2.JSONResult.user.name}'),
                new Parameter('invalidProperty', '{$Job.Step.Step 2.JSONResult.user.invalidProperty}')
            };

            Test.startTest();

            Id stepId = [SELECT Id FROM JobStep__c WHERE Order__c = 1].Id;

            // Exercise
            List<Parameter> result = new TemplatingEngine(stepId, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(6, result.size());
            Assert.areEqual('Manual', result[0].value);
            Assert.areEqual(false, result[0].sensitive);
            Assert.areEqual('Test Dev 1', result[1].value);
            Assert.areEqual(false, result[1].sensitive);
            Assert.areEqual('["US-0001","US-0003"]', result[2].value);
            Assert.areEqual('2', result[3].value);
            Assert.areEqual('logedInUser', result[4].value);
            Assert.areEqual(null, result[5].value);
        }
    }

    @IsTest
    private static void parseOrgCredentialWithInvalidRecordId() {
        // Setup
        Exception expectedException = null;

        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', '{$Context.Credential.Endpoint}') };

        // Exercise
        try {
            new TemplatingEngine(UserInfo.getUserId(), parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
    }

    @IsTest
    private static void parseOrgCredentialWithRecordId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            Environment__c environment = [SELECT Id FROM Environment__c LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Context.Credential.SessionId}'),
                new Parameter('key', '{$Context.Credential.Endpoint}'),
                new Parameter('key', '{$Context.Credential.EndpointURL}')
            };

            // Exercise
            Test.startTest();
            List<Parameter> result = new TemplatingEngine(environment.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(3, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual(true, result[1].sensitive);
            Assert.areEqual(true, result[2].sensitive);
            Assert.areEqual('sessionId', result[0].value);
            Assert.areEqual('https://copadodev.salesforce.com/services/Soap/u/49.0/00D09000007GB3WEAW', result[1].value);
            Assert.areEqual('https://copadodev.salesforce.com', result[2].value);
        }
    }

    @IsTest
    private static void parseOrgCredentialWithJobContextId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('source', '{$Source.Credential.SessionId}'),
                new Parameter('destination', '{$Destination.Credential.Endpoint}'),
                new Parameter('endpoint', '{$Destination.Credential.EndpointURL}')
            };
            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            // Exercise
            Test.startTest();
            List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(3, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual(true, result[1].sensitive);
            Assert.areEqual(true, result[2].sensitive);
            Assert.areEqual('sessionId', result[0].value);
            Assert.areEqual('https://copadodev.salesforce.com/services/Soap/u/49.0/00D09000007GB3WEAW', result[1].value);
            Assert.areEqual('https://copadodev.salesforce.com', result[2].value);
        }
    }

    @IsTest
    private static void parseOrgCredentialWithStepContextId() {
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            // Setup
            fflib_SObjectUnitOfWork.disableRollback = true;
            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            List<Environment__c> environments = [SELECT Id FROM Environment__c];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .persist();

            Test.startTest();

            JobStep__c step = [SELECT Id, Source_Id__c FROM JobStep__c WHERE Name = 'Step 1'];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('source', '{$Source.Credential.SessionId}'),
                new Parameter('destination', '{$Destination.Credential.Endpoint}'),
                new Parameter('endpoint', '{$Source.Credential.EndpointURL}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(3, result.size());
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual(true, result[1].sensitive);
            Assert.areEqual(true, result[2].sensitive);
            Assert.areEqual('sessionId', result[0].value);
            Assert.areEqual('https://copadodev.salesforce.com/services/Soap/u/49.0/00D09000007GB3WEAW', result[1].value);
            Assert.areEqual('https://copadodev.salesforce.com', result[2].value);
        }
    }

    @IsTest
    private static void parseOrgCredentialWithCalloutErrorAndParameterRequired() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Exception expectedException = null;

            Test.setMock(HttpCalloutMock.class, new WebHookMock(404));
            Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('source', '{$Source.Credential.SessionId}').required(true),
                new Parameter('destination', '{$Destination.Credential.Endpoint}').required(true)
            };

            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            // Exercise
            Test.startTest();
            try {
                new TemplatingEngine(job.Id, parameters).parse();
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Assert.areNotEqual(null, expectedException);
            Assert.areEqual(String.format(Label.InvalidRequest, new List<String>{ 'Source' }), expectedException.getMessage());
        }
    }

    @IsTest
    private static void parseOrgCredentialWhenAPIKeyExpired() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            Exception expectedException = null;

            Test.setMock(HttpCalloutMock.class, new WebHookMock(401));
            Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('source', '{$Source.Credential.SessionId}').required(true),
                new Parameter('destination', '{$Destination.Credential.Endpoint}').required(true)
            };

            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            // Exercise
            Test.startTest();
            try {
                new TemplatingEngine(job.Id, parameters).parse();
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Assert.areNotEqual(null, expectedException);
            Assert.areEqual(Label.ApiKeyExpired, expectedException.getMessage());
        }
    }

    @IsTest
    private static void parseOrgCredentialWithCalloutErrorAndParameterNotRequired() {
        User copadoUser = getUser();

        System.runAs(copadoUser) {
            // Setup
            Exception expectedException = null;

            Test.setMock(HttpCalloutMock.class, new WebHookMock(401));
            Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('source', '{$Source.Credential.SessionId}'),
                new Parameter('destination', '{$Destination.Credential.Endpoint}')
            };

            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            // Exercise
            Test.startTest();
            try {
                new TemplatingEngine(job.Id, parameters).parse();
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Assert.areEqual(null, expectedException);
        }
    }

    @IsTest
    private static void parseSObjectExpressionWithJsonFields() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            //Setup
            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];
            String dataJSON = '{ "key1": "value1", "nested": { "key2": "value2.1" }, "key3": ["US-0001","US-0003"], "key4": null }';
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .deployment(deployment.Id)
                .dataJson(dataJSON)
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .persist();

            Test.startTest();
            JobStep__c step = [SELECT Id, Source_Id__c FROM JobStep__c WHERE Name = 'Step 1'];

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key1', '{$Context.JobExecution__r.DataJson.key1}'),
                new Parameter('key2', '{$Context.JobExecution__r.DataJson.nested.key2}'),
                new Parameter('key3', '{$Context.JobExecution__r.DataJson.key3}'),
                new Parameter('key4', '{$Context.JobExecution__r.DataJson.key4}'),
                new Parameter('key5', '{$Context.JobExecution__r.DataJson__c}')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(5, result.size());
            Assert.areEqual('value1', result[0].value);
            Assert.areEqual('value2.1', result[1].value);
            Assert.areEqual('["US-0001","US-0003"]', result[2].value);
            Assert.areEqual(null, result[3].value);
            Assert.areEqual(dataJSON, result[4].value);
        }
    }

    @IsTest
    private static void parseApexExpressionWithInvalidClass() {
        //Setup
        Exception expectedException = null;

        List<Parameter> parameters = new List<Parameter>{ new Parameter('key1', '{$Context.Apex.InValidClass}').required(true) };

        // Exercise
        try {
            new TemplatingEngine(UserInfo.getUserId(), parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.InvalidExpressionClass + 'InValidClass'));
    }

    @IsTest
    private static void parseApexExpressionWithInvalidInterface() {
        //Setup
        Exception expectedException = null;

        List<Parameter> parameters = new List<Parameter>{ new Parameter('key1', '{$Context.Apex.ApexExpression}').required(true) };

        // Exercise
        try {
            new TemplatingEngine(UserInfo.getUserId(), parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.InvalidExpressionClass + 'ApexExpression'));
    }

    @IsTest
    private static void parseApexExpressionWithValidImplementation() {
        //Setup
        ApexExpression.mockValue = 'ParameterValue';

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key1', '{$Context.Apex.ApexExpression}'),
            new Parameter('key2', '{$Context.Apex.ApexExpression.matches(Parameter*)}'),
            new Parameter('key3', '{$Context.Apex.ApexExpression.matches("NoParameter")}')
        };

        // Exercise
        parameters = new TemplatingEngine(UserInfo.getUserId(), parameters).parse();

        // Verify
        Assert.areEqual(3, parameters.size());
        Assert.areEqual('ParameterValue', parameters[0].value);
        Assert.areEqual('true', parameters[1].value);
        Assert.areEqual('false', parameters[2].value);
    }

    @isTest
    private static void parseUserAndSourcePropertiesWithJobStepAsContext() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Source_Id__c FROM JobStep__c WHERE Name = 'Step 1'];

            Test.setMock(WebServiceMock.class, new MdApiMock());

            new SystemProperty().value('source/sql').apiName('DB').sensitive(true).parent(step.Source_Id__c);
            new SystemProperty().value('user/sql').apiName('DB').sensitive(true).parent(copadoUser.Id).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Property.DB}'),
                new Parameter('HardcodedKey', 'hardcodedValue')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size());
            Assert.areEqual('user/sql', result[0].value);
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('hardcodedValue', result[1].value);
            Assert.areEqual(false, result[1].sensitive);
        }
    }

    @isTest
    private static void parseDestinationAndSourcePropertiesWithJobStepAsContext() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Source_Id__c, Destination_Id__c FROM JobStep__c WHERE Name = 'Step 1'];

            Test.setMock(WebServiceMock.class, new MdApiMock());

            new SystemProperty().value('source/sql').apiName('DB').sensitive(true).parent(step.Source_Id__c);
            new SystemProperty().value('destination/sql').apiName('DB').sensitive(true).parent(step.Destination_Id__c).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Property.DB}'),
                new Parameter('HardcodedKey', 'hardcodedValue')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size());
            Assert.areEqual('destination/sql', result[0].value);
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('hardcodedValue', result[1].value);
            Assert.areEqual(false, result[1].sensitive);
        }
    }

    @isTest
    private static void parseSourcePipelineAndGlobalPropertiesWithJobStepAsContext() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Source_Id__c, Pipeline_Id__c FROM JobStep__c WHERE Name = 'Step 1'];

            Test.setMock(WebServiceMock.class, new MdApiMock());

            new SystemProperty().value('source/sql').apiName('DB').sensitive(true).parent(step.Source_Id__c);
            new SystemProperty().value('pipeline/sql').apiName('DB').sensitive(true).parent(step.Pipeline_Id__c);
            new SystemProperty().value('sql server').apiName('DB').sensitive(true).globalProperty(true).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Property.DB}'),
                new Parameter('HardcodedKey', 'hardcodedValue')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size());
            Assert.areEqual('source/sql', result[0].value);
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('hardcodedValue', result[1].value);
            Assert.areEqual(false, result[1].sensitive);
        }
    }

    @isTest
    private static void parsePipelineAndGlobalPropertiesWithJobStepAsContext() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {
            // Setup
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            JobStep__c step = [SELECT Id, Pipeline_Id__c FROM JobStep__c WHERE Name = 'Step 1'];

            Test.setMock(WebServiceMock.class, new MdApiMock());

            new SystemProperty().value('pipeline/sql').apiName('DB').sensitive(true).parent(step.Pipeline_Id__c);
            new SystemProperty().value('sql server').apiName('DB').sensitive(true).globalProperty(true).persist();

            List<Parameter> parameters = new List<Parameter>{
                new Parameter('key', '{$Property.DB}'),
                new Parameter('HardcodedKey', 'hardcodedValue')
            };

            // Exercise
            List<Parameter> result = new TemplatingEngine(step.Id, parameters).parse();
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size());
            Assert.areEqual('pipeline/sql', result[0].value);
            Assert.areEqual(true, result[0].sensitive);
            Assert.areEqual('hardcodedValue', result[1].value);
            Assert.areEqual(false, result[1].sensitive);
        }
    }

    @IsTest
    private static void parseGlobalTemplateWithDeploymentJob() {
        // Setup
        Deployment_Job__c job = [SELECT Id FROM Deployment_Job__c LIMIT 1];

        new SystemProperty().value('sql server').apiName('DB').sensitive(false).globalProperty(true).persist();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('key', '{$Property.DB}'),
            new Parameter('key', '{$Property.DB.matches(sql*)}')
        };

        // Exercise
        List<Parameter> result = new TemplatingEngine(job.Id, parameters).parse();

        // Verify
        Assert.areEqual(2, result.size());

        Assert.areEqual('sql server', result[0].value);
        Assert.areEqual(false, result[0].sensitive);

        Assert.areEqual('true', result[1].value);
        Assert.areEqual(false, result[1].sensitive);
    }

    @IsTest
    private static void parseWithInvalidContextId() {
        // Setup
        Exception expectedException = null;
        List<Parameter> parameters = new List<Parameter>{ new Parameter('key', '{$Source.Property.Invalid}') };
        String contextId = 'abc';

        // Exercise
        try {
            new TemplatingEngine(contextId, parameters).parse();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.areNotEqual(null, expectedException);
        Assert.areEqual(Label.InvalidContextIdValue, expectedException.getMessage());
    }

    @IsTest
    private static void parseContextBranchForCommitAction() {
        //Setup
        User copadoUser = getUser();
        JobStep__c step1;

        Test.startTest();
        System.runAs(copadoUser) {
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];

            new UserStoryCommit(new SnapshotCommit().credentialId(org.Id)).userStoryId([SELECT Id FROM User_Story__c LIMIT 1].Id);
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .userStoryCommit([SELECT Id FROM User_Story_Commit__c LIMIT 1].Id)
                .dataJson('{"featureBranchName" : "feature/US-0040928"}')
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .persist();

            step1 = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];
        }

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('featureBranch', '{$Context.Branch}'),
            new Parameter('featureBranch', '{$Context.Branch.matches(feature/*)}')
        };

        // Exercise
        List<Parameter> result;
        System.runAs(copadoUser) {
            result = new TemplatingEngine(step1.Id, parameters).parse();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(2, result.size());
        Assert.areEqual('feature/US-0040928', result[0].value);
        Assert.areEqual('true', result[1].value);
    }

    @IsTest
    private static void parseContextBranchForPromoteAction() {
        //Setup
        User copadoUser = getUser();
        JobStep__c step1;

        Test.startTest();
        System.runAs(copadoUser) {
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Promotion__c promotion = [SELECT Id FROM Promotion__c];

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .promotion(promotion.Id)
                .dataJson('{"promotionBranchName" : "promotion/P02854"}')
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .persist();

            step1 = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];
        }

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('promotionBranch', '{$Context.Branch}'),
            new Parameter('promotionBranch', '{$Context.Branch.matches(promotion/*)}')
        };

        // Exercise
        List<Parameter> result;
        System.runAs(copadoUser) {
            result = new TemplatingEngine(step1.Id, parameters).parse();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(2, result.size());
        Assert.areEqual('promotion/P02854', result[0].value);
        Assert.areEqual('true', result[1].value);
    }

    @IsTest
    private static void parseContextBranchForDeploymenAction() {
        //Setup
        User copadoUser = getUser();
        JobStep__c step1;

        Test.startTest();
        System.runAs(copadoUser) {
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .deployment(deployment.Id)
                .dataJson('{"destinationBranchName" : "main"}')
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .persist();

            step1 = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];
        }

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('destinationBranch', '{$Context.Branch}'),
            new Parameter('destinationBranch', '{$Context.Branch.matches("ma*")}')
        };

        // Exercise
        List<Parameter> result;
        System.runAs(copadoUser) {
            result = new TemplatingEngine(step1.Id, parameters).parse();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(2, result.size());
        Assert.areEqual('main', result[0].value);
        Assert.areEqual('true', result[1].value);
    }

    @IsTest
    private static void parseContextBranchForInValidContext() {
        //Setup
        User copadoUser = getUser();
        JobStep__c step1;
        Exception expectedException = null;
        Test.startTest();
        System.runAs(copadoUser) {
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .parentRecord(UserInfo.getUserId())
                .add(new JobStep().name('Step 1').type('Manual').order(1).configJson(''))
                .persist();

            step1 = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];
        }

        List<Parameter> parameters = new List<Parameter>{ new Parameter('destinationBranch', '{$Context.Branch}').required(true) };

        // Exercise
        try {
            System.runAs(copadoUser) {
                new TemplatingEngine(step1.Id, parameters).parse();
            }
        } catch (Exception ex) {
            expectedException = ex;
        }
        Test.stopTest();

        // Verify
        Assert.areNotEqual(null, expectedException);
        Assert.areEqual(Label.InvalidContextForBranchExpression, expectedException.getMessage());
    }

    @IsTest
    private static void parseSourceAndDestinationBranch() {
        //Setup
        User copadoUser = getUser();
        JobStep__c step1;
        Test.startTest();
        System.runAs(copadoUser) {
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .source(environments[0].Id)
                .destination(environments[1].Id)
                .pipeline(pipeline.Id)
                .add(new JobStep().name('Step 1').type('Manual').order(1).pipeline(pipeline.Id).configJson(''))
                .persist();

            step1 = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];
        }

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('sourceBranch', '{$Source.Branch}'),
            new Parameter('destinationBranch', '{$Destination.Branch}'),
            new Parameter('destinationBranch', '{$Destination.Branch.matches(Des*)}')
        };

        // Exercise
        System.runAs(copadoUser) {
            parameters = new TemplatingEngine(step1.Id, parameters).parse();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, parameters.size());
        Assert.areEqual('Source', parameters[0].value);
        Assert.areEqual('Destination', parameters[1].value);
        Assert.areEqual('true', parameters[2].value);
    }

    @IsTest
    private static void parseSourceAndDestinationBranchWithInvalidContextId() {
        // Setup
        Exception expectedException = null;

        User copadoUser = getUser();

        List<Parameter> parameters = new List<Parameter>{
            new Parameter('sourceBranch', '{$Source.Branch}'),
            new Parameter('destinationBranch', '{$Destination.Branch}')
        };

        // Exercise
        System.runAs(copadoUser) {
            try {
                parameters = new TemplatingEngine(UserInfo.getUserId(), parameters).parse();
            } catch (Exception ex) {
                expectedException = ex;
            }
        }

        // Verify
        String expectedExceptionMessage = String.format(
            Label.invalidContextId,
            new List<String>{ '{$Source.Branch}, {$Destination.Branch}', Label.JobStep }
        );

        Assert.areNotEqual(null, expectedException);
        Assert.areEqual(expectedExceptionMessage, expectedException.getMessage());
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email, Name, LastName, Username FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createDeploymentJob() {
        Credential env1Credential = new Credential();
        Credential env2Credential = new Credential();
        Environment env1 = new Environment().name('Environment 1').type('Production/Developer').platform('Salesforce').add(env1Credential);
        Environment env2 = new Environment().name('Environment 2').type('Production/Developer').platform('Salesforce').add(env2Credential);
        Environment env3 = new Environment().name('Environment 3').type('Production/Developer').platform('Salesforce').add(new Credential());

        Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Salesforce')
            .add(new Connection(env1, env2).branch('Source'))
            .add(new Connection(env2, env3).branch('Destination'))
            .add(new Project().add(new UserStory().credential(env1Credential)))
            .persist();

        Promotion promotion = new Promotion(new Release(), new Credential(), new Credential());
        promotion.persist();

        fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).disableAll();
        Deployment__c deployment = (Deployment__c) new Deployment(promotion)
            .name('Test Dev 1')
            .description('Sample Deployment')
            .add(new Step().name('Step 1').order(1))
            .add(new Step().name('Step 2').order(2))
            .persist();
        fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).enableAll();

        fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).disableAll();
        Destination_Org__c destination = new Destination_Org__c(Deployment__c = deployment.Id, To_Org__c = [SELECT Id FROM Org__c LIMIT 1].Id);
        insert destination;
        fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).enableAll();

        List<Step__c> steps = [SELECT Id FROM Step__c];
        insert new Deployment_Job__c(Step__c = steps[0].Id, Destination_Org__c = destination.Id);
    }

    private static Git_Repository__c sshRepository() {
        Git_Repository__c result = (Git_Repository__c) new Repository().name('gitRepository').uri('git@github.com:user/repository.git').persist();

        Attachment attachment1 = new Attachment(Name = 'id_rsa.pub', Body = Blob.valueOf('publicKey'), ParentId = result.Id);
        Attachment attachment2 = new Attachment(Name = 'id_rsa', Body = Blob.valueOf('-----BEGIN PRIVATE KEY-----privateKey'), ParentId = result.Id);
        insert new List<Attachment>{ attachment1, attachment2 };

        return result;
    }

    private static Git_Repository__c httpsRepository() {
        Git_Repository__c result = (Git_Repository__c) new Repository().name('gitRepository').uri('https://github.com/user/repository.git').persist();

        Sensitive_Information__c sensitiveInformation = new Sensitive_Information__c();
        sensitiveInformation.Name = result.Id;
        sensitiveInformation.Username__c = 'username';
        sensitiveInformation.Password__c = DeployAPI.encryptApiKey('password');
        sensitiveInformation.Extra_Header__c = DeployAPI.encryptApiKey('Extra Headers');
        insert sensitiveInformation;

        return result;
    }

    // INNER

    private class MdApiMock implements WebServiceMock {
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType
        ) {
            response.put('response_x', createResponse());
        }

        private MetadataService.createMetadataResponse_element createResponse() {
            MetadataService.createMetadataResponse_element responseElement = new MetadataService.createMetadataResponse_element();
            MetadataService.SaveResult sr = new MetadataService.SaveResult();
            sr.success = true;

            responseElement.result = new List<MetadataService.SaveResult>{ sr };

            return responseElement;
        }
    }

    public class WebHookMock implements HttpCalloutMock {
        private Integer statusCode = 200;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public WebHookMock() {
        }

        public WebHookMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{ "isSuccess": true, "sessionId": "sessionId", "endPoint": "https://copadodev.salesforce.com/services/Soap/u/49.0/00D09000007GB3WEAW" }'
            );
            res.setStatusCode(statusCode);

            return res;
        }
    }
}