public inherited sharing class PredicateBooleanExpression {
    public static Boolean eval(String expression) { 
        return Boolean.valueOf(execute(expression.toUpperCase()));
    }
    
    private static String execute(String expression) {
        // If expression contains only TRUE or FALSE values
        Boolean isMonovalent = checkMonovalent(expression);
        if(isMonovalent != null) {
            return String.valueOf(isMonovalent);
        }

        for(String logicType : logicTypes.keySet()) {
            if(expression.contains(logicType)) {
                expression = simplify(expression, logicTypes.get(logicType));
            }
        }

        Boolean recursiveLogic = expression.contains('AND') || expression.contains('OR') || expression.contains('(');        
        if(recursiveLogic) {
            expression = execute(expression);
        }        
        return expression;
    }

    private static Boolean checkMonovalent(String expression) {
        if(expression.containsNone('FALSE')) { 
            return TRUE; 
        }
        if(expression.containsNone('TRUE')) { 
            return FALSE; 
        }
        return null;
    }
    
    private static string simplify(String expression, String logicType){
        Map<String, String> logic = expressionLogic.get(logicType);
        
        for(String key : logic.keySet()) {
            expression = expression.replace(key, logic.get(key));
        }
        
        return expression;
    }

    private final static Map<String, String> logicTypes = new Map<String, String>{
        'AND' => 'AND',
        'OR' => 'OR',
        '(' => 'BRACES'
    };
    private final static Map<String, Map<String, String>> expressionLogic = new Map<String, Map<String, String>>{    
        // AND Logic
        'AND' => new Map<String, String>{
            'TRUE AND TRUE' => 'TRUE',
            'TRUE AND FALSE' => 'FALSE',
            'FALSE AND TRUE' => 'FALSE',
            'FALSE AND FALSE' => 'FALSE'
        },
        // OR Logic
        'OR' => new Map<String, String>{
            'TRUE OR TRUE' => 'TRUE',
            'TRUE OR FALSE' => 'TRUE',
            'FALSE OR TRUE' => 'TRUE',
            'FALSE OR FALSE' => 'FALSE'
        },
        // BRACES Logic
        'BRACES' => new Map<String, String>{
            '(TRUE)' => 'TRUE',
            '(FALSE)'=> 'FALSE'
        }
    };
    
}