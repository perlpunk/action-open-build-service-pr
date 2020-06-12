<!--- START AUTOGENERATE -->
# OBS Build PR

Branch and Build OBS project on Pull Request

This action will branch a given OBS package and edit the url and revision
in the `_service` file.

Then it will monitor the build status and post this status via the
[Status API](https://developer.github.com/v3/repos/statuses/).

It will monitor as long there are pending builds.

If there is a failed build, it will abort and report failure.

If the timeout exceeds, it will abort and report pending.

Builds that are marked as `finished` but where the build details say
`succeeded` will be counted as success.

The duration of the builds will be displayed at the end.


## Inputs

### `apiurl`

**Required** obs api url.

### `project`

**Required** obs project.

### `package`

**Required** obs package.

### `branchprefix`

**Required** OBS project path prefix for the branched package.

### `timeout`

Timeout (seconds) after which the job stops (with a failure). Default `600`.

### `sleep`

Time to sleep (seconds) between checking the build status. Default `30`.

### `ignore-repos`

Repositories (comma separated) which should not result in a failure
.


## Outputs

### `branch`

The path of the branched package


<!--- END AUTOGENERATE -->


## Example Usage

    - name: Branch OBS Project
      uses: perlpunk/action-open-build-service-pr@v0.0.1
      id: obs
      with:
        apiurl:       https://api.opensuse.org
        project:      devel:openQA
        package:      os-autoinst
        branchprefix: home:$USER:branches:TestGitHub
        ignore-repos: SLE_12_SP4,SLE_12_SP3
        timeout:      600 # default
        sleep:        30 # default
      env:
        OSCLOGIN:     ${{ secrets.OSCLOGIN }}
        OSCPASS:      ${{ secrets.OSCPASS }}
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

This will create a package

    home:$USER:branches:TestGitHub:devel:openQA-branch-branchname:os-autoinst
    home:$USER:branches:TestGitHub:devel:openQA-pr-123:os-autoinst

Where `$USER` will be replaced with your `$OSCLOGIN`.

If you are using this action from a fork, you need to add the secrets
`OSCLOGIN` and `OSCPASS` into the forked project's settings.

## Screenshots

![Status Pending](/img/obs-action-pending.png)

![Status Unresolvable](/img/obs-action-unresolvable.png)

![Status Success](/img/obs-action-success.png)

