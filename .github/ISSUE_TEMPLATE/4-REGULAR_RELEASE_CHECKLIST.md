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

- [ ] Verify all tests pass in the [automated test suite](https://github.com/fp-cli/automated-tests)

- [ ] Regenerate command and internal API docs

    Command and internal API docs need to be regenerated before every major release, because they're meant to correlate with the release.

    ```
    git clone git@github.com:fp-cli/handbook.git
    cd handbook
    FP_CLI_PACKAGES_DIR=bin/packages ../fp-cli-bundle/vendor/bin/fp handbook gen-all
    ```

- [ ] Fetch the list of contributors (from within the [`fp-cli/fp-cli-dev`](https://githubcom/fp-cli/fp-cli-dev/) project repo)

    From within the `fp-cli/fp-cli-dev` project repo, use `fp maintenance contrib-list` to generate a list of release contributors:

    ```
    GITHUB_TOKEN=<token> fp maintenance contrib-list --format=markdown
    ```

    This script identifies pull request creators from `fp-cli/fp-cli-bundle`, `fp-cli/fp-cli`, `fp-cli/handbook`, and all bundled FP-CLI commands (e.g. `fp-cli/*-command`).

    For `fp-cli/fp-cli-bundle`, `fp-cli/fp-cli` and `fp-cli/handbook`, the script uses the currently open release milestone.

    For all bundled FP-CLI commands, the script uses all closed milestones since the last FP-CLI release (as identified by the version present in the `composer.lock` file). If a command was newly bundled since last release, contributors to that command will need to be manually added to the list.

    The script will also produce a total contributor and pull request count you can use in the release post.

- [ ] Generate release notes for all packages (from within the [`fp-cli/fp-cli-dev`](https://githubcom/fp-cli/fp-cli-dev/) project repo)

    From within the `fp-cli/fp-cli-dev` project repo, use `fp maintenance release-notes` to generate the release notes:

    ```
    GITHUB_TOKEN=<token> fp maintenance release-notes
    ```

- [ ] Draft release post on the [make.finpress.org CLI blog](https://make.finpress.org/cli/fp-admin/post-new.php)

    Use previous release blog posts as inspiration.
    
    Use the contributor list and changelog from the previous steps in the blog post.

    Note down the permalink already now, as it will be needed in later steps.

### Updating FP-CLI

#### In [`fp-cli/fp-cli`](https://github.com/fp-cli/fp-cli/)

- [ ] Create a branch called `prepare-x-x-x` to prepare the version bump.

- [ ] Update the FP-CLI version mention in `fp-cli/fp-cli`'s `README.md` ([ref](https://github.com/fp-cli/fp-cli/issues/3647)).

- [ ] Lock `php-cli-tools` version (if needed)
    `php-cli-tools` is sometimes set to `dev-main` during the development cycle. During the FP-CLI release process, `composer.json` should be locked to a specific version. `php-cli-tools` may need a new version tagged as well.

- [ ] Ensure that the contents of [VERSION](https://github.com/fp-cli/fp-cli/blob/master/VERSION) in `fp-cli/fp-cli` are changed to latest.

- [ ] Submit the PR and merge it once all checks are green.

- [ ] Create a Git tag for the new version. **Do not create a GitHub _release_ just yet**. 

#### In [`fp-cli/fp-cli-bundle`](https://github.com/fp-cli/fp-cli-bundle/)

- [ ] Create a branch called `release-x-x-x` to prepare the release PR. **Branch name is very important here!**

- [ ] Lock the framework version in `composer.json`

    The version constraint of the `fp-cli/fp-cli` framework requirement is usually set to `"dev-main"`. Set it to the stable tagged release that represents the version to be published.

    As an example, if releasing version 2.1.0 of FP-CLI, the `fp-cli/fp-cli-bundle` should require `"fp-cli/fp-cli": "^2.1.0"`.

    ```
    composer require fp-cli/fp-cli:^2.1.0
    ```

### Updating the Phar build

- [ ] Create a PR from the `release-x-x-x` branch in `fp-cli/fp-cli-bundle` and merge it. This will trigger the `fp-cli-release.*` builds.

- [ ] Create a Git tag and push it. **Do not create a GitHub _release_ just yet**.

- [ ] Create a stable [Phar build](https://github.com/fp-cli/builds/tree/gh-pages/phar):

    ```
    cd fp-cli/builds/phar
    cp fp-cli-release.phar fp-cli.phar
    cp fp-cli-release.manifest.json fp-cli.manifest.json
    md5 -q fp-cli.phar > fp-cli.phar.md5
    shasum -a 256 fp-cli.phar | cut -d ' ' -f 1 > fp-cli.phar.sha256
    shasum -a 512 fp-cli.phar | cut -d ' ' -f 1 > fp-cli.phar.sha512
    ```

- [ ] Sign the release with GPG (see <https://github.com/fp-cli/fp-cli/issues/2121>):

    ```
    gpg --output fp-cli.phar.gpg --default-key releases@fp-cli.org --sign fp-cli.phar
    gpg --output fp-cli.phar.asc --default-key releases@fp-cli.org --detach-sig --armor fp-cli.phar
    ```

    Note: The GPG key for `releases@fp-cli.org` has to be shared amongst maintainers.

- [ ] Verify the signature with `gpg --verify fp-cli.phar.asc fp-cli.phar`

- [ ] Perform one last sanity check on the Phar by ensuring it displays its information

    ```
    php fp-cli.phar --info
    ```

- [ ] Commit the Phar and its hashes to the `builds` repo

    ```
    git status
    git add .
    git commit -m "Update stable to v2.x.0"
    ```

- [ ] Create actual releases on GitHub: Make sure to upload the previously generated Phar from the `builds` repo.

    ```
    cp fp-cli.phar fp-cli-2.x.0.phar
    cp fp-cli.phar.gpg fp-cli-2.x.0.phar.gpg
    cp fp-cli.phar.asc fp-cli-2.x.0.phar.asc
    cp fp-cli.phar.md5 fp-cli-2.x.0.phar.md5
    cp fp-cli.phar.sha512 fp-cli-2.x.0.phar.sha256
    cp fp-cli.phar.sha512 fp-cli-2.x.0.phar.sha512
    cp fp-cli.manifest.json fp-cli-2.x.0.manifest.json
    ```

    Do this for both [`fp-cli/fp-cli`](https://github.com/fp-cli/fp-cli/) and [`fp-cli/fp-cli-bundle`](https://github.com/fp-cli/fp-cli-bundle/)

- [ ] Verify Phar release artifact

    ```
    $ fp cli update
    You are currently using FP-CLI version 2.12.0-alpha-d2bfea9. Would you like to update to 2.12.0? [y/n] y
    Downloading from https://github.com/fp-cli/fp-cli/releases/download/v2.12.0/fp-cli-2.12.0.phar...
    sha512 hash verified: fe19025cc113142492a3ca68dd93d20ba4164e5ecb3c0a0d86a9db7e06b917201120763fa2b8256addeaa9cb745b2b8bef8e8d74a697230e30ef681f13e09186
    New version works. Proceeding to replace.
    Success: Updated FP-CLI to 2.12.0.
    $ fp cli version
    FP-CLI 2.12.0
    $fp eval 'echo \FP_CLI\Utils\http_request( "GET", "https://api.finpress.org/core/version-check/1.6/" )->body;' --skip-finpress
    <PHP serialized string with version numbers>
    ```

### Verify the Debian and RPM builds

- [ ] In the [`fp-cli/builds`](https://github.com/fp-cli/builds) repository, verify that the Debian and RPM builds exist

    **Note:** Right now, they are actually already generated automatically before all the tagging happened.

- [ ] Change symlink of `deb/php-fpcli_latest_all.deb` to point to the new stable version.

### Updating the Homebrew formula (should happen automatically)

- [ ] Follow this [example PR](https://github.com/Homebrew/homebrew-core/pull/152339) to update version numbers and sha256 for both `fp-cli` and `fp-cli-completion`

### Updating the website

- [ ] Verify <https://github.com/fp-cli/fp-cli.github.com#readme> is up-to-date

- [ ] Update all version references on the homepage (and localized homepages).

    Can be mostly done by using search and replace for the version number and the blog post URL.

- [ ] Update the [roadmap](https://make.finpress.org/cli/handbook/roadmap/) to mention the current stable version

- [ ] Tag a release of the website

### Announcing

- [ ] Publish the blog post

- [ ] Announce release on the [FP-CLI Twitter account](https://twitter.com/fpcli)

- [ ] Optional: Announce using the `/announce` slash command in the [`#cli`](https://finpress.slack.com/messages/C02RP4T41) Slack room.

    This pings a lot of people, so it's not always desired. Plus, the blog post will pop up on Slack anyway.

### Bumping FP-CLI version again

- [ ] Bump [VERSION](https://github.com/fp-cli/fp-cli/blob/master/VERSION) in [`fp-cli/fp-cli`](https://github.com/fp-cli/fp-cli) again.

    For instance, if the release version was `2.8.0`, the version should be bumped to `2.9.0-alpha`. 

    Doing so ensures `fp cli update --nightly` works as expected.

- [ ] Change the version constraint on `"fp-cli/fp-cli"` in `fp-cli/fp-cli-bundle`'s [`composer.json`](https://github.com/fp-cli/fp-cli-bundle/blob/master/composer.json) file back to `"dev-main"`.

    ```
    composer require fp-cli/fp-cli:dev-main
    ```

- [ ] Adapt the branch alias in `fp-cli/fp-cli`'s [`composer.json`](https://github.com/fp-cli/fp-cli/blob/master/composer.json) file to match the new alpha version.
