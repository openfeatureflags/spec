Feature: Flag evaluation

# This test suite contains scenarios to test the flag evaluation API.

  Background:
    Given a provider is registered with cache disabled

  # basic evaluation
  Scenario: Resolves boolean value
    When a boolean flag with key "boolean-flag" is evaluated with default value "false"
    Then the resolved boolean value should be "true"

  Scenario: Resolves string value
    When a string flag with key "string-flag" is evaluated with default value "bye"
    Then the resolved string value should be "hi"

  Scenario: Resolves integer value
    When an integer flag with key "integer-flag" is evaluated with default value 1
    Then the resolved integer value should be 10

  Scenario: Resolves float value
    When a float flag with key "float-flag" is evaluated with default value 0.1
    Then the resolved float value should be 0.5

  Scenario: Resolves object value
    When an object flag with key "object-flag" is evaluated with a null default value
    Then the resolved object value should be contain fields "showImages", "title", and "imagesPerPage", with values "true", "Check out these pics!" and 100, respectively

  # detailed evaluation
  Scenario: Resolves boolean details
    When a boolean flag with key "boolean-flag" is evaluated with details and default value "false"
    Then the resolved boolean details value should be "true", the variant should be "on", and the reason should be "STATIC"

  Scenario: Resolves string details
    When a string flag with key "string-flag" is evaluated with details and default value "bye"
    Then the resolved string details value should be "hi", the variant should be "greeting", and the reason should be "STATIC"

  Scenario: Resolves integer details
    When an integer flag with key "integer-flag" is evaluated with details and default value 1
    Then the resolved integer details value should be 10, the variant should be "ten", and the reason should be "STATIC"

  Scenario: Resolves float details
    When a float flag with key "float-flag" is evaluated with details and default value 0.1
    Then the resolved float details value should be 0.5, the variant should be "half", and the reason should be "STATIC"

  Scenario: Resolves object details
    When an object flag with key "object-flag" is evaluated with details and a null default value
    Then the resolved object details value should be contain fields "showImages", "title", and "imagesPerPage", with values "true", "Check out these pics!" and 100, respectively
    And the variant should be "template", and the reason should be "STATIC"

  Scenario: Passes evaluation details to finally hooks
    When a hook is added to the client
    And a boolean flag with key "boolean-flag" is evaluated with details and default value "false"
    Then non-error hooks should be called
    And "after, finally after" hook should have evaluation details
      | flag_type | key           | value        |
      | string    | flag_key      | boolean-flag |
      | boolean   | value         | true         |
      | string    | variant       | on           |
      | string    | reason        | STATIC       |
      | string    | error_code    | None         |
      | string    | error_message | None         |

  # context-aware evaluation
  Scenario: Resolves based on context
    When context contains keys "fn", "ln", "age", "customer" with values "Sulisław", "Świętopełk", 29, "false"
    And a flag with key "context-aware" is evaluated with default value "EXTERNAL"
    Then the resolved string response should be "INTERNAL"
    And the resolved flag value is "EXTERNAL" when the context is empty

  # errors
  Scenario: Flag not found
    When a hook is added to the client
    And a non-existent string flag with key "missing-flag" is evaluated with details and a default value "uh-oh"
    Then the default string value should be returned
    And the reason should indicate an error and the error code should indicate a missing flag with "FLAG_NOT_FOUND"
    And error hooks should be called
    And "finally after" hook should have evaluation details
      | type   | key           | value                         |
      | string | flag_key      | missing-flag                  |
      | string | value         | uh-oh                         |
      | string | variant       | None                          |
      | string | reason        | ERROR                         |
      | string | error_code    | ErrorCode.FLAG_NOT_FOUND      |
      | string | error_message | Flag 'missing-flag' not found |

  Scenario: Type error
    When a hook is added to the client
    And a string flag with key "wrong-flag" is evaluated as an integer, with details and a default value 13
    Then the default integer value should be returned
    And the reason should indicate an error and the error code should indicate a type mismatch with "TYPE_MISMATCH"
    And error hooks should be called
    And "finally after" hook should have evaluation details
      | type    | key           | value                                             |
      | string  | flag_key      | wrong-flag                                        |
      | integer | value         | 13                                                |
      | string  | variant       | None                                              |
      | string  | reason        | ERROR                                             |
      | string  | error_code    | ErrorCode.TYPE_MISMATCH                           |
      | string  | error_message | Expected type <class 'int'> but got <class 'str'> |