public with sharing class RollbackStepJson {
  public String gitBranch;
  public String testLevel;
  public List<String> replacements;
  public List<Step> steps;

  public class Step {
    public String indexFileId;
    public Boolean promotion;
    public String metadataFileId;
    public String vlocityFileId;
  }
}