---
name: "\U0001F680 Regular Release Checklist"
about: "\U0001F512 Maintainers only: create a checklist for a regular release process"
title: 'Release checklist for v2.x.x'
labels: 'i: scope:distribution'
assignees: ''

---
# Regular Release Checklist - v2.x.x

### Preparation

- [ ] Mention on Slack that a release is being prepared

    People should wait with updating until the announcement. Before that, things are still in motion.

- [ ] Verify all tests pass in the [automated test suite](https://github.com/fin-cli/automated-tests)

- [ ] Regenerate command and internal API docs

    Command and internal API docs need to be regenerated before every major release, because they're meant to correlate with the release.

    ```
    git clone git@github.com:fin-cli/handbook.git
    cd handbook
    FIN_CLI_PACKAGES_DIR=bin/packages ../fin-cli-bundle/vendor/bin/fin handbook gen-all
    ```

- [ ] Fetch the list of contributors (from within the [`fin-cli/fin-cli-dev`](https://githubcom/fin-cli/fin-cli-dev/) project repo)

    From within the `fin-cli/fin-cli-dev` project repo, use `fin maintenance contrib-list` to generate a list of release contributors:

    ```
    GITHUB_TOKEN=<token> fin maintenance contrib-list --format=markdown
    ```

    This script identifies pull request creators from `fin-cli/fin-cli-bundle`, `fin-cli/fin-cli`, `fin-cli/handbook`, and all bundled FIN-CLI commands (e.g. `fin-cli/*-command`).

    For `fin-cli/fin-cli-bundle`, `fin-cli/fin-cli` and `fin-cli/handbook`, the script uses the currently open release milestone.

    For all bundled FIN-CLI commands, the script uses all closed milestones since the last FIN-CLI release (as identified by the version present in the `composer.lock` file). If a command was newly bundled since last release, contributors to that command will need to be manually added to the list.

    The script will also produce a total contributor and pull request count you can use in the release post.

- [ ] Generate release notes for all packages (from within the [`fin-cli/fin-cli-dev`](https://githubcom/fin-cli/fin-cli-dev/) project repo)

    From within the `fin-cli/fin-cli-dev` project repo, use `fin maintenance release-notes` to generate the release notes:

    ```
    GITHUB_TOKEN=<token> fin maintenance release-notes
    ```

- [ ] Draft release post on the [make.finpress.org CLI blog](https://make.finpress.org/cli/fin-admin/post-new.php)

    Use previous release blog posts as inspiration.
    
    Use the contributor list and changelog from the previous steps in the blog post.

    Note down the permalink already now, as it will be needed in later steps.

### Updating FIN-CLI

#### In [`fin-cli/fin-cli`](https://github.com/fin-cli/fin-cli/)

- [ ] Create a branch called `prepare-x-x-x` to prepare the version bump.

- [ ] Update the FIN-CLI version mention in `fin-cli/fin-cli`'s `README.md` ([ref](https://github.com/fin-cli/fin-cli/issues/3647)).

- [ ] Lock `php-cli-tools` version (if needed)
    `php-cli-tools` is sometimes set to `dev-main` during the development cycle. During the FIN-CLI release process, `composer.json` should be locked to a specific version. `php-cli-tools` may need a new version tagged as well.

- [ ] Ensure that the contents of [VERSION](https://github.com/fin-cli/fin-cli/blob/master/VERSION) in `fin-cli/fin-cli` are changed to latest.

- [ ] Submit the PR and merge it once all checks are green.

- [ ] Create a Git tag for the new version. **Do not create a GitHub _release_ just yet**. 

#### In [`fin-cli/fin-cli-bundle`](https://github.com/fin-cli/fin-cli-bundle/)

- [ ] Create a branch called `release-x-x-x` to prepare the release PR. **Branch name is very important here!**

- [ ] Lock the framework version in `composer.json`

    The version constraint of the `fin-cli/fin-cli` framework requirement is usually set to `"dev-main"`. Set it to the stable tagged release that represents the version to be published.

    As an example, if releasing version 2.1.0 of FIN-CLI, the `fin-cli/fin-cli-bundle` should require `"fin-cli/fin-cli": "^2.1.0"`.

    ```
    composer require fin-cli/fin-cli:^2.1.0
    ```

### Updating the Phar build

- [ ] Create a PR from the `release-x-x-x` branch in `fin-cli/fin-cli-bundle` and merge it. This will trigger the `fin-cli-release.*` builds.

- [ ] Create a Git tag and push it. **Do not create a GitHub _release_ just yet**.

- [ ] Create a stable [Phar build](https://github.com/fin-cli/builds/tree/gh-pages/phar):

    ```
    cd fin-cli/builds/phar
    cp fin-cli-release.phar fin-cli.phar
    cp fin-cli-release.manifest.json fin-cli.manifest.json
    md5 -q fin-cli.phar > fin-cli.phar.md5
    shasum -a 256 fin-cli.phar | cut -d ' ' -f 1 > fin-cli.phar.sha256
    shasum -a 512 fin-cli.phar | cut -d ' ' -f 1 > fin-cli.phar.sha512
    ```

- [ ] Sign the release with GPG (see <https://github.com/fin-cli/fin-cli/issues/2121>):

    ```
    gpg --output fin-cli.phar.gpg --default-key releases@fin-cli.org --sign fin-cli.phar
    gpg --output fin-cli.phar.asc --default-key releases@fin-cli.org --detach-sig --armor fin-cli.phar
    ```

    Note: The GPG key for `releases@fin-cli.org` has to be shared amongst maintainers.

- [ ] Verify the signature with `gpg --verify fin-cli.phar.asc fin-cli.phar`

- [ ] Perform one last sanity check on the Phar by ensuring it displays its information

    ```
    php fin-cli.phar --info
    ```

- [ ] Commit the Phar and its hashes to the `builds` repo

    ```
    git status
    git add .
    git commit -m "Update stable to v2.x.0"
    ```

- [ ] Create actual releases on GitHub: Make sure to upload the previously generated Phar from the `builds` repo.

    ```
    cp fin-cli.phar fin-cli-2.x.0.phar
    cp fin-cli.phar.gpg fin-cli-2.x.0.phar.gpg
    cp fin-cli.phar.asc fin-cli-2.x.0.phar.asc
    cp fin-cli.phar.md5 fin-cli-2.x.0.phar.md5
    cp fin-cli.phar.sha512 fin-cli-2.x.0.phar.sha256
    cp fin-cli.phar.sha512 fin-cli-2.x.0.phar.sha512
    cp fin-cli.manifest.json fin-cli-2.x.0.manifest.json
    ```

    Do this for both [`fin-cli/fin-cli`](https://github.com/fin-cli/fin-cli/) and [`fin-cli/fin-cli-bundle`](https://github.com/fin-cli/fin-cli-bundle/)

- [ ] Verify Phar release artifact

    ```
    $ fin cli update
    You are currently using FIN-CLI version 2.12.0-alpha-d2bfea9. Would you like to update to 2.12.0? [y/n] y
    Downloading from https://github.com/fin-cli/fin-cli/releases/download/v2.12.0/fin-cli-2.12.0.phar...
    sha512 hash verified: fe19025cc113142492a3ca68dd93d20ba4164e5ecb3c0a0d86a9db7e06b917201120763fa2b8256addeaa9cb745b2b8bef8e8d74a697230e30ef681f13e09186
    New version works. Proceeding to replace.
    Success: Updated FIN-CLI to 2.12.0.
    $ fin cli version
    FIN-CLI 2.12.0
    $fin eval 'echo \FIN_CLI\Utils\http_request( "GET", "https://api.finpress.org/core/version-check/1.6/" )->body;' --skip-finpress
    <PHP serialized string with version numbers>
    ```

### Verify the Debian and RPM builds

- [ ] In the [`fin-cli/builds`](https://github.com/fin-cli/builds) repository, verify that the Debian and RPM builds exist

    **Note:** Right now, they are actually already generated automatically before all the tagging happened.

- [ ] Change symlink of `deb/php-fincli_latest_all.deb` to point to the new stable version.

### Updating the Homebrew formula (should happen automatically)

- [ ] Follow this [example PR](https://github.com/Homebrew/homebrew-core/pull/152339) to update version numbers and sha256 for both `fin-cli` and `fin-cli-completion`

### Updating the website

- [ ] Verify <https://github.com/fin-cli/fin-cli.github.com#readme> is up-to-date

- [ ] Update all version references on the homepage (and localized homepages).

    Can be mostly done by using search and replace for the version number and the blog post URL.

- [ ] Update the [roadmap](https://make.finpress.org/cli/handbook/roadmap/) to mention the current stable version

- [ ] Tag a release of the website

### Announcing

- [ ] Publish the blog post

- [ ] Announce release on the [FIN-CLI Twitter account](https://twitter.com/fincli)

- [ ] Optional: Announce using the `/announce` slash command in the [`#cli`](https://finpress.slack.com/messages/C02RP4T41) Slack room.

    This pings a lot of people, so it's not always desired. Plus, the blog post will pop up on Slack anyway.

### Bumping FIN-CLI version again

- [ ] Bump [VERSION](https://github.com/fin-cli/fin-cli/blob/master/VERSION) in [`fin-cli/fin-cli`](https://github.com/fin-cli/fin-cli) again.

    For instance, if the release version was `2.8.0`, the version should be bumped to `2.9.0-alpha`. 

    Doing so ensures `fin cli update --nightly` works as expected.

- [ ] Change the version constraint on `"fin-cli/fin-cli"` in `fin-cli/fin-cli-bundle`'s [`composer.json`](https://github.com/fin-cli/fin-cli-bundle/blob/master/composer.json) file back to `"dev-main"`.

    ```
    composer require fin-cli/fin-cli:dev-main
    ```

- [ ] Adapt the branch alias in `fin-cli/fin-cli`'s [`composer.json`](https://github.com/fin-cli/fin-cli/blob/master/composer.json) file to match the new alpha version.
