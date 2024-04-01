public with sharing class CalculateQGCCriteriaWeight { 
    private String filterCriteria;

    private static final Pattern CRITERIA_ITEM_PATTERN = Pattern.compile('.*(\\{\\s*\\$[A-Za-z0-9_"\'\\.\\(\\)\\*]+\\})+.*');

    private Map<String, Integer> weightByNode = new Map<String, Integer>{ 'file' => 1 };

    private Map<String, Integer> weightByProperty = new Map<String, Integer>{ 'name' => 30, 'directory' => 20, 'type' => 10 };

    private Map<String, Integer> weightByOperator = new Map<String, Integer>{
        'equals' => 10,
        'contains' => 6,
        'startswith' => 5,
        'endswith' => 5,
        'notcontains' => 4,
        'notequals' => 2
    };

    // CONSTRUCTOR

    public CalculateQGCCriteriaWeight(String filterCriteria) {
        this.filterCriteria = filterCriteria;
    }

    // PUBLIC

    public Integer execute() {
        Integer result = 0;
        if (filterCriteria != null) {
            String expression = calculateWeight(filterCriteria); 
            result = evaluate(replaceOperatorSymbol(expression));
        }
        return result;
    }

    // PRIVATE

    // @param filter criteria e.g. {$Changes.Directory.equals("Custom")} || {$Changes.Name.notEquals("Test")}
    // return expression e.g. '200 || 60' 
    private String calculateWeight(String filterCriteria) {
        String result = filterCriteria;

        for (String expression : filterCriteria.split('\\s[&|]{2}\\s')) {
            Matcher matcher = CRITERIA_ITEM_PATTERN.matcher(expression);
            
            if (matcher.matches()) {
                String innerCriteriaItem = matcher.group(1);
                Integer innerCriteriaWeight = calculateCriteriaItemWeight(innerCriteriaItem);
                result = result.replace(innerCriteriaItem, String.valueOf(innerCriteriaWeight));
            }
        }

        return result;
    }

    private Integer calculateCriteriaItemWeight(String criteriaItem) {
        String[] splitExp = criteriaItem.split('\\.');

        Integer nodeWeight = weightByNode.get('file');
        Integer propertyWeight = weightByProperty.get(splitExp[1].toLowerCase());
        Integer operatorWeight = weightByOperator.get(splitExp[2].substringBefore('(').toLowerCase());

        Integer criteriaItemWeight = nodeWeight * propertyWeight * operatorWeight;
        return criteriaItemWeight;
    }

    private String replaceOperatorSymbol(String expression) {
        return expression.replaceAll('\\&&', '+').replaceAll('\\|\\|', '-');
    }

    // Note: This logic uses stack structure to calculate the final weight from a criteria expression. Ref: https://ict.iitk.ac.in/wp-content/uploads/CS210-Data-Structures-Module-11-Expression-Evaluation-completed.pdf
    // @param string expression e.g. '200 - (60 + 50)'
    // @return weight as integer after performing arithmetic operation (considers precedence of '+' over '-' if expression is without parentheses)
    private Integer evaluate(String expression) {
        Stack integerStack = new Stack();
        Stack operatorStack = new Stack();
       
        for (Integer index = 0; index < expression.length(); index++) {
            String currentChar = expression.substring(index, index + 1);

            if (currentchar.isNumeric()) {
                String numericString = getCompleteNumber(currentChar, expression, index);
                index = index + (numericString.length() - 1);
                integerStack.push(Integer.valueOf(numericString));
            } else if (currentChar.equals('(')) {
                operatorStack.push(currentChar);
            } else if (currentChar.equals(')')) {
                handleParenthesis(integerStack, operatorStack, currentChar);
            } else if (currentChar.equals('+') || currentChar.equals('-')) {
                handleOperator(integerStack, operatorStack, currentChar);
            } else if (currentChar == ' ') {
                continue;
            }
        }

        while (operatorStack.size() > 0) {
            performRemainingOperation(integerStack, operatorStack);
        }
        return Integer.valueOf(integerStack.pop());
    }

    private String getCompleteNumber(String value, String expression, Integer index) {
        String result = '';

        while (value.isNumeric()) {
            result += value;
            if (index == expression.length() - 1) {
                index++;
                break;
            }
            index = index + 1;
            value = expression.substring(index, index + 1);
        }

        return result;
    }

    private void handleParenthesis(Stack integerStack, Stack operatorStack, String currentChar) {
        // @Note: We give precedence to nested parenthesis operation no matter the inside operator
        String operatorRemoved = String.valueOf(operatorStack.pop());
        while (operatorStack.size() > 0 && !operatorRemoved.equals('(')) {
            // @Note: Doing the operation inside of the parenthesis
            performArithmeticOperation(operatorRemoved, integerStack);
            operatorRemoved = String.valueOf(operatorStack.pop());
        } 
        
    }

    private void handleOperator(Stack integerStack, Stack operatorStack, String currentChar) {
        // @Note: Check precedence of top operator with current operator
        String operator = operatorStack.top() != null ? String.valueOf(operatorStack.top()) : '';
        while (operator != '' && precedence(operator) > precedence(currentChar)) {
             // @Note: Doing the operation with top most two operands
            performArithmeticOperation(operator, integerStack);
            operator = String.valueOf(operatorStack.pop());
        }
        operatorStack.push(currentChar);
    }

    private void performArithmeticOperation(String operator, Stack integerStack) {
        Integer topElement = integerStack.top() != null ? Integer.valueOf(integerStack.pop()) : 0;
        Integer priorElement = integerStack.top() != null ? Integer.valueof(integerStack.pop()) : 0;
        integerStack.push(applyOperator(priorElement, topElement, operator));
    }

    private void performRemainingOperation(Stack integerStack, Stack operatorStack) {
        String operator = String.valueOf(operatorStack.pop());
        performArithmeticOperation(operator, integerStack);
    }

    private Integer precedence(String operator) {
        switch on operator {
            when '+' {
                return 2;
            }
            when '-' {
                return 1;
            }
            when else {
                return 0;
            }
        }
    }

    private Integer applyOperator(Integer operand1, Integer operand2, String operator) {
        switch on operator {
            when '+' {
                return operand1 + operand2;
            }
            when '-' {
                return operand1 <= operand2 ? operand1 : operand2;
            }
            when else {
                return 0;
            }
        }
    }

    private class Stack {
        private List<Object> items;

        private Stack() {
            items = new List<Object>();
        }

        private void push(Object value) {
            items.add(value);
        }
        private Object pop() {
            return !items.isEmpty() ? items.remove(items.size() - 1) : null;
        }

        private Object top() {
            return !items.isEmpty() ? items[items.size() - 1] : null;
        }

        private Integer size() {
            return items.size();
        }
    }
}