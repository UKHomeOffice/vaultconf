Feature: vaultconf can add users with policies to a vault server

  Scenario: vaultconf can add policies to vault
    Given I have a vault server running
    When I do "vaultconf policies -c test/resources/policies -u user -p password -a http://localhost:8200 --nokube"
    Then I should be able to see these policies in vault

  Scenario: vaultconf can add users to vault
    Given I have a vault server running
    And vault already contains policies
    When I do "vaultconf users -c test/resources/users/users.yaml -u user -p password -a http://localhost:8200 --nokube"
#    TODO: Figure out best way to mock kubernetes service so we can confirm secrets are being written
#    Then the usernames and passwords should be added to kubernetes secrets
    And I should be able to see the users and their associated policies in vault
