public virtual class CliSfDataWrapper {
    public String status;
    public String message;

    public CliSfDataWrapper() {
    }

    public CliSfDataWrapper(String stat, String msg) {
        status = stat;
        message = msg;
    }

    public static String jsonReturnResult(String status, String message) {
        return JSON.serialize(new CliSfDataWrapper(status, message));
    }

    public enum StatusResult {
        OK,
        ERROR
    }
}