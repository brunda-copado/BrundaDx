public class Calculator {

    public static Integer add(Integer num1, Integer num2) {
        return num1 + num2;
    }

    public static Integer subtract(Integer num1, Integer num2) {
        return num1 - num2;
    }

    public static Integer multiply(Integer num1, Integer num2) {
        return num1 * num2;
    }

    public static Decimal divide(Integer num1, Integer num2) {
        // Check for division by zero
        if (num2 == 0) {
            throw new DivisionByZeroException('Cannot divide by zero');
        }
        
        // Perform division with decimal result
        return (Decimal)num1 / num2;
    }

    public class DivisionByZeroException extends Exception {}
}