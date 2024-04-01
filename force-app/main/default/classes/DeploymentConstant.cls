/**
 *  Copyright (C) 2023 Copado - All Rights Reserved
 *
 *  Getter Constant class saves impactful heap consumption when large number of constants are present in a class
 *  Update this class for future upcoming new constants
 *
 *  NOTE: Underscored all caps naming convention shows up as unsupported in PMD.
 *
 *  @Author - Pranjal [18th Sep 2023]
 */
@SuppressWarnings('PMD')
public virtual with sharing class DeploymentConstant {
    public final String COMPLETED_WITH_ERRORS {
        get {
            return 'Completed with Errors';
        }
        private set;
    }
    public final String COMPLETED_SUCCESSFULLY {
        get {
            return 'Completed Successfully';
        }
        private set;
    }
    public final String SUCCESS {
        get {
            return 'Success';
        }
        private set;
    }
    public final String FAILED {
        get {
            return 'Failed';
        }
        private set;
    }
    public final String CANCELLED {
        get {
            return 'Cancelled';
        }
        private set;
    }
    public final String PENDING {
        get {
            return 'Pending';
        }
        private set;
    }
    public final String NOT_STARTED {
        get {
            return 'Not started';
        }
        private set;
    }
    public final String IN_PROGRESS {
        get {
            return 'In progress';
        }
        private set;
    }
    public final String QUEUED {
        get {
            return 'QUEUED';
        }
        private set;
    }
    public final String SCHEDULED {
        get {
            return 'Scheduled';
        }
        private set;
    }
    public final String DEPLOY_NOW {
        get {
            return 'Deploy now';
        }
        private set;
    }
    public final String DEPLOY_LATER {
        get {
            return 'Deploy later';
        }
        private set;
    }
    public final String OK_STRING {
        get {
            return 'OK';
        }
        private set;
    }
    public final String ERROR {
        get {
            return 'error';
        }
        private set;
    }
    public final String WARNING {
        get {
            return 'warning';
        }
        private set;
    }
    public final String ERROR_PARSING_JSON {
        get {
            return 'Error during parsing of JSON: ';
        }
        private set;
    }
    public final String NO_DEPLOYMENT_JOB_FOUND {
        get {
            return 'No deployment jobs could be found.';
        }
        private set;
    }
    public final String BUILD_TASK_RECORD_NOT_FOUND {
        get {
            return 'Build task record not found.';
        }
        private set;
    }
}