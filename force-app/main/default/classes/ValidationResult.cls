public with sharing class ValidationResult {
    private List<String> errors = new List<String>();

    // PUBLIC

    public ValidationResult addError(String error) {
        this.errors.add(error);
        return this;
    }

    public Boolean isError() {
        return !this.errors.isEmpty();
    }

    public override String toString() {
        return String.join(this.errors, '\n');
    }
}