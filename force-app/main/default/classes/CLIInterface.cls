/**
 * Interface to handle requests from CLI
 */

public interface CLIInterface {

    /**
     * Runs requested operation under root service
     *
     * @return
     */
    String run(CliProxy.CLIWrapper record);

}