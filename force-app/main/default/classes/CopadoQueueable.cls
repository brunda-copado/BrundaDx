public interface CopadoQueueable {
    void execute(String payload);
    void cancel(String payload);
}