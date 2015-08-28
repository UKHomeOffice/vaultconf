Feature: vaultconf can add users with policies to a vault server

  Scenario: vaultconf can add policies to vault
    Given I have a vault server running
    And a root user exists on my server
    And I have a folder at /tmp/policies containing vault policies
    When I run "vaultconf policies /tmp/policies -u user -p password --server http://localhost:8200"
    Then I should be able to see these policies in vault

  Scenario: vaultconf can add users to vault
    Given I have a vault server running
    And a root user exists on my server
    And vault already contains policies
    And I have a yaml file at /tmp/users.yaml containing details of my users
    When I run "vaultconf users /tmp/users.yaml -u user -p password --server http://localhost:8200"
    Then I should get a json output of the users and their generated passwords
    And I should be able to see the users and their associated policies in vault
