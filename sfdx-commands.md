## Table of Contents

-   [Deployment Commands](#deployment-commands)
    -   [Specify Tests](#specify-tests)
    -   [Package XML](#package-xml)
    -   [Quick Deploy Validated Deployment](#quick-deploy-validated-deployment)
    -   [Deployment Optional Flags](#deployment-optional-flags)
-   [Community Commands](#community-commands)
    -   [Publish](#publish)
-   [Alias Commands](#alias-commands)
    -   [Log Into Org](#log-into-org)
    -   [Log Out of Org](#log-out-of-org)
    -   [View Logged In Orgs](#view-logged-in-orgs)
    -   [Change Alias](#change-alias)
    -   [Open Org](#open-org)
-   [Dev Hub Commands](#dev-hub-commands)
    -   [Set Default Hub](#set-default-hub)
    -   [Create Scratch](#create-scratch)
    -   [Set Default Scratch](#set-default-scratch)
-   [Packages](#packages)
    -   [Create](#create)
    -   [Create Version](#create-version)
    -   [Install](#install)
    -   [View](#view)
    -   [View Installed](#view-installed)
    -   [Uninstall](#uninstalled)
    -   [Delete](#delete)
    -   [Delete Version](#delete-version)
-   [Jest](#set-default-scratch)
    -   [Testing](#testing)
    -   [Testing Watch](#testing-watch)
    -   [Testing Coverage](#testing-coverage)
-   [Misc. Commands](#misc-commands)

---

&nbsp;

## Deployment Commands

### Specify tests

---

```
sfdx force:source:deploy -c -x manifest/<package name>.xml -u <orgAlias> -l RunSpecifiedTests -r <TestClass1,TestClass2...>

Beta
----
sf deploy metadata validate -x manifest/<package name>.xml -o <orgAlias> -l RunSpecifiedTests -t <TestClass1,TestClass2...>
```

---

&nbsp;

### Package XML

---

```
sfdx force:source:deploy -c -x manifest/<package name>.xml -u <orgAlias>

Beta
----
sf deploy metadata validate -x manifest/<package name>.xml -o <orgAlias>
```

---

&nbsp;

### Quick Deploy Validated Deployment

---

```
sfdx force:source:deploy -q <validatedDeploymentId>

Beta
----
sf deploy metadata validate -x manifest/<package name>.xml
```

---

&nbsp;

### Deployment Optional Flags

&nbsp;

**SFDX Commands**

| <div style="width:230px">Flag</div> | Description                                                                                                                                                                                                   |
| :---------------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|               --json                | Format output as JSON                                                                                                                                                                                         |
|             --loglevel              | The logging level for this command invocation. Logs are stored in $HOME/.sf/sf.log. Accepted values are: trace \| debug \| info \| warn \| error \| fatal \| TRACE \| DEBUG \| INFO \| WARN \| ERROR \| FATAL |
|       -u \| --targetusername        | A username or alias for the target org. Overrides the default target org                                                                                                                                      |
|            --apiversion             | Override the API version used for API requests made by this command                                                                                                                                           |
|          -c \| --checkonly          | Validates the deployed metadata and runs all Apex tests, but prevents the deployment from being saved to the org                                                                                              |
|            --soapdeploy             | Deploy metadata with SOAP API instead of REST API                                                                                                                                                             |
|            -w \| --wait             | Number of minutes to wait for the command to complete and display results to the terminal window                                                                                                              |
|         -l \| --test-level          | deployment Apex testing level. Accepted values: NoTestRun \| RunSpecifiedTests \| RunLocalTests \| RunAllTestsInOrg. NoTestRun is default                                                                     |
|          -r \| --runtests           | apex tests to run when --test-level is RunSpecifiedTests                                                                                                                                                      |
|        -o \| --ignoreerrors         | Ignores the deploy errors, and continues with the deploy operation                                                                                                                                            |
|       -g \| --ignorewarnings        | If a warning occurs and ignoreWarnings is set to true, the success field in DeployMessage is true. When ignoreWarnings is set to false, success is set to false, and the warning is treated like an error     |
|           --purgeondelete           | Specify that deleted components in the destructive changes manifest file are immediately eligible for deletion rather than being stored in the Recycle Bin                                                    |
|  -q \| --validateddeployrequestid   | Specifies the ID of a package with recently validated components to run a Quick Deploy                                                                                                                        |
|              --verbose              | Emit additional command output to stdout                                                                                                                                                                      |
|          -m \| --metadata           | metadata to deploy. Examples, LightningComponentBundle, AuraDefinitionBundle, ApexClass, CustomObject                                                                                                         |
|         -p \| --sourcepath          | A comma-separated list of paths to the local source files to deploy                                                                                                                                           |
|          -x \| --manifest           | path to manifest file to deploy                                                                                                                                                                               |
|       --predestructivechanges       | File path for a manifest of components to delete before the deploy                                                                                                                                            |
|      --postdestructivechanges       | File path for a manifest of components to delete after the deploy                                                                                                                                             |
|       -f \| --forceoverwrite        | Ignore conflict warnings and overwrite changes to the org                                                                                                                                                     |
|            --resultsdir             | Output directory for code coverage and JUnit results; defaults to the deploy ID                                                                                                                               |
|        --coverageformatters         | Format of the code coverage results                                                                                                                                                                           |
|               --junit               | Output JUnit test results                                                                                                                                                                                     |

&nbsp;

**SF Commands**

| <div style="width:230px">Flag</div> | Description                                                                                                                               |
| :---------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------- |
|         -a \| --apiversion          | Override the API version used for API requests made by this command                                                                       |
|               --async               | returns deployment id and then allows you to use terminal while deployment is in progress                                                 |
|          -c \| --checkonly          | Validates the deployed metadata and runs all Apex tests, but prevents the deployment from being saved to the org                          |
|              --dry-run              | runs deployment and tests against org but doesn't save to the org                                                                         |
|          -x \| --manifest           | path to manifest file to deploy                                                                                                           |
|          -m \| --metadata           | metadata to deploy. Examples, LightningComponentBundle, AuraDefinitionBundle, ApexClass, CustomObject                                     |
|         -d \| --source-dir          | A comma-separated list of paths to the local source files to deploy                                                                       |
|         -o \| --target-org          | A username or alias for the target org. Overrides the default target org                                                                  |
|            -t \| --tests            | apex tests to run when --test-level is RunSpecifiedTests                                                                                  |
|         -l \| --test-level          | deployment Apex testing level. Accepted values: NoTestRun \| RunSpecifiedTests \| RunLocalTests \| RunAllTestsInOrg. NoTestRun is default |
|              --verbose              | Emit additional command output to stdout                                                                                                  |

---

&nbsp;

## Community Commands

### Publish

---

```
sfdx force:community:publish -u <alias> -n <communityName>
```

---

&nbsp;

## Alias Commands

### Log Into Org

```
sf login org -a <alias> -l <instanceUrl>
```

---

&nbsp;

### Log Out of Org

```
sfdx force:auth:logout -u <alias>

sf logout org -o <alias> [--no-prompt]
```

---

&nbsp;

### View Logged In Orgs

```
sfdx force:org:list
sfdx force:org:list --all
sfdx force:org:list --clean

sf env list
sf env list -a --sort "Aliases"
```

---

&nbsp;

### Change Alias

```
sfdx force:alias:set <newAliasName>=<username>
```

---

&nbsp;

### Open Org

```
sfdx force:org:open -u <alias>

sf env open -e <alias> [-r | --url-only - display url do not open] [-p | --path - append to end of url]
```

---

&nbsp;

### Check Limits

```
sfdx force:limits:api:display -u <orgAlias>
```

---

&nbsp;

## Dev Hub Commands

### Set Default Hub

---

```
sfdx config:set defaultdevhubusername=<devHubAlias>
```

---

&nbsp;

### Create Scratch

---

```
sfdx force:org:create --definitionfile config/project-scratch-def.json --durationdays 30 --setalias <scratchOrgAlias> -v <devHubAlias>
```

---

&nbsp;

### Set Default Scratch

---

```
sfdx config:set defaultusername=<scratchOrgAlias>
```

---

&nbsp;

## Packages

### Create

---

```
sfdx force:package:create --name <packageName> --description <packageDescription> --packagetype Unlocked --path <packagePath> --nonamespace --targetdevhubusername <packageHub>
```

---

&nbsp;

### Create Version

---

```
sfdx force:package:version:create -p <packageName> -d <packagePath> -k <packagePassword> --wait 10 -v <packageHub>
```

---

&nbsp;

### Install

---

```
sfdx force:package:install --wait 10 --publishwait 10 -p <packageName>@<versionNumber> -k <password> -r -u <orgAlias>
```

---

&nbsp;

### View

---

```
sfdx force:package:list
```

---

&nbsp;

### View Installed

---

```
sfdx force:package:installed:list
```

---

&nbsp;

### Unistall

---

```
sfdx force:package:uninstall -p <package>
```

---

&nbsp;

### Delete

---

```
sfdx force:package:delete -p <package>
```

---

&nbsp;

### Delete Version

---

```
sfdx force:package:version:delete -p <packageVersion>
```

---

&nbsp;

## Jest

### Testing

---

```
npm run test:unit
```

---

&nbsp;

### Testing Watch

---

```
npm run test:unit:watch
```

---

&nbsp;

### Testing Coverage

---

```
npm run test:unit:coverage
```

---

&nbsp;

## Misc. Commands

```
sfdx scanner:run --target "**/main/default/**" --pmdconfig "apex_ruleset.xml" --eslintconfig ".eslintrc.json" --verbose
```
