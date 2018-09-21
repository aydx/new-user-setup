# new-user-setup

This repository contains a script which manages the new user setup process at dataxu.

Current features:

* Prompts for a Samanage ticket ID and pulls the necessary data from the ticket as a JSON object.
* Checks user FTE/Contractor/Intern status and assigns the appropriate AD security groups
* Enters a remote Powershell session on the utility server to create the new AD user.

Planned features:

* Okta, GSuite, Atlassian user setup