---
name: "\U0001F527 Patch Release Checklist"
about: "\U0001F512 Maintainers only: create a checklist for a patch release process"
title: 'Release checklist for v2.x.x'
labels: 'i: scope:distribution'
assignees: 'schlessera'

---
# Patch Release Checklist - v2.x.x

### Preparation

- [ ] Write release post on the [Make.org CLI blog](https://make.finpress.org/cli/fin-admin/post-new.php)
- [ ] Regenerate command and internal API docs

    Command and internal API docs need to be regenerated before every major release, because they're meant to correlate with the release.

    ```
    git clone git@github.com:fin-cli/handbook.git
    cd handbook
    fin handbook gen-all
    ```

- [ ] Verify results of [automated test suite](https://github.com/fin-cli/automated-tests)

### Updating FIN-CLI

- [ ] Create a new release branch from the last tagged patch release

    ```
    $ git checkout v1.4.0
    Note: checking out 'v1.4.0'
    You are in 'detached HEAD' state. You can look around, make experimental
    changes and commit them, and you can discard any commits you make in this
    state without impacting any branches by performing another checkout.
    $ git checkout -b release-1-4-1
    Switched to a new branch 'release-1-4-1'
    ```

- [ ] Cherry-pick existing commits and package versions to the new release branch.

    Because patch releases should just be used for bug fixes, you should first fix the bug on master, and then cherry-pick the fix to the release branch. It's up to your discretion as to whether you cherry-pick the commits directly to the release branch *or* create a feature branch and pull request against the release branch.

    If the bug existed in a package, you'll need to create a point release above the last bundled version for the package and update `composer.lock` to load that point release.

- [ ] Ensure that the contents of [VERSION](https://github.com/fin-cli/fin-cli/blob/master/VERSION) in `fin-cli/fin-cli` are changed to latest.

- [ ] Update the FIN-CLI version mention in `fin-cli/fin-cli`'s `README.md` ([ref](https://github.com/fin-cli/fin-cli/issues/3647)).

- [ ] Lock `php-cli-tools` version (if needed)

    `php-cli-tools` is sometimes set to `dev-master` during the development cycle. During the FIN-CLI release process, `composer.json` should be locked to a specific version. `php-cli-tools` may need a new version tagged as well.

- [ ] Lock the framework version in the ([bundle repository](https://github.com/fin-cli/fin-cli-bundle/))

    The version constraint of the `fin-cli/fin-cli` framework requirement is usually set to `"dev-master"`. Set it to the stable tagged release that represents the version to be published.

    As an example, if releasing version 2.1.0 of FIN-CLI, the `fin-cli/fin-cli-bundle` should require `"fin-cli/fin-cli": "^2.1.0"`.

### Updating the contributor list

- [ ] Fetch the list of contributors (from within the [`fin-cli/fin-cli-dev`](https://githubcom/fin-cli/fin-cli-dev/) project repo)

    From within the `fin-cli/fin-cli-dev` project repo, use `fin maintenance contrib-list` to generate a list of release contributors:

    ```
    GITHUB_TOKEN=<token> fin maintenance contrib-list --format=markdown
    ```

    This script identifies pull request creators from `fin-cli/fin-cli-bundle`, `fin-cli/fin-cli`, `fin-cli/handbook`, and all bundled FIN-CLI commands (e.g. `fin-cli/*-command`).

    For `fin-cli/fin-cli-bundle`, `fin-cli/fin-cli` and `fin-cli/handbook`, the script uses the currently open release milestone.

    For all bundled FIN-CLI commands, the script uses all closed milestones since the last FIN-CLI release (as identified by the version present in the `composer.lock` file). If a command was newly bundled since last release, contributors to that command will need to be manually added to the list.

    The script will also produce a total contributor and pull request count you can use in the release post.

### Updating the Phar build

- [ ] Create a PR from the `release-x-x-x` branch in `fin-cli/fin-cli-bundle` and merge it. This will trigger the `fin-cli-release.*` builds.

- [ ] Create a git tag and push it.

- [ ] Create a stable [Phar build](https://github.com/fin-cli/builds/tree/gh-pages/phar):

    ```
    cd fin-cli/builds/phar
    cp fin-cli-release.phar fin-cli.phar
    cp fin-cli-release.manifest.json fin-cli.manifest.json
    md5 -q fin-cli.phar > fin-cli.phar.md5
    shasum -a 512 fin-cli.phar | cut -d ' ' -f 1 > fin-cli.phar.sha512
    ```

- [ ] Sign the release with GPG (see <https://github.com/fin-cli/fin-cli/issues/2121>):

    ```
    gpg --output fin-cli.phar.gpg --default-key releases@fin-cli.org --sign fin-cli.phar
    gpg --output fin-cli.phar.asc --default-key releases@fin-cli.org --detach-sig --armor fin-cli.phar
    ```

    Note: The GPG key for `releases@fin-cli.org` has to be shared amongst maintainers.

- [ ] Perform one last sanity check on the Phar by ensuring it displays its information

    ```
    php fin-cli.phar --info
    ```

- [ ] Commit the Phar and its hashes to the builds repo

    ```
    git status
    git add .
    git commit -m "Update stable to v2.x.x"
    ```

- [ ] Create a release on GitHub: <https://github.com/fin-cli/fin-cli/releases>. Make sure to upload the Phar from the builds directory.

    ```
    cp fin-cli.phar fin-cli-2.x.x.phar
    cp fin-cli.phar.gpg fin-cli-2.x.x.phar.gpg
    cp fin-cli.phar.asc fin-cli-2.x.x.phar.asc
    cp fin-cli.phar.md5 fin-cli-2.x.x.phar.md5
    cp fin-cli.phar.sha512 fin-cli-2.x.x.phar.sha512
    cp fin-cli.manifest.json fin-cli-2.x.x.manifest.json
    ```

- [ ] Verify Phar release artifact

    ```
    $ fin cli update
    You are currently using FIN-CLI version 2.12.0-alpha-d2bfea9. Would you like to update to 2.12.1? [y/n] y
    Downloading from https://github.com/fin-cli/fin-cli/releases/download/v2.12.1/fin-cli-2.12.1.phar...
    sha512 hash verified: fe19025cc113142492a3ca68dd93d20ba4164e5ecb3c0a0d86a9db7e06b917201120763fa2b8256addeaa9cb745b2b8bef8e8d74a697230e30ef681f13e09186
    New version works. Proceeding to replace.
    Success: Updated FIN-CLI to 2.12.1.
    $ fin cli version
    FIN-CLI 2.12.1
    $fin eval 'echo \FIN_CLI\Utils\http_request( "GET", "https://api.finpress.org/core/version-check/1.6/" )->body;' --skip-finpress
    <PHP serialized string with version numbers>
    ```

### Updating the Debian and RPM builds

- [ ] Trigger Travis CI build on [fin-cli/deb-build](https://github.com/fin-cli/deb-build)
- [ ] Trigger Travis CI build on [fin-cli/rpm-build](https://github.com/fin-cli/rpm-build)

    The two builds shouldn't be triggered at the same time, as one of them will then fail to push its build artifact due to the remote not being in the same state anymore.

    Due to aggressive caching by the GitHub servers, the scripts might pull in cached version of the previous release instead of the new one. This seems to resolve automatically in a period of 24 hours.

### Updating the Homebrew formula (should happen automatically)

- [ ] Update the url and sha256 here: https://github.com/Homebrew/homebrew-core/blob/master/Formula/fin-cli.rb#L4-L5

    The easiest way to do so is by using the following command:

    ```
    brew bump-formula-pr --strict fin-cli --url=https://github.com/fin-cli/fin-cli/releases/download/v2.x.x/fin-cli-2.x.x.phar --sha256=$(wget -qO- https://github.com/fin-cli/fin-cli/releases/download/v2.x.x/fin-cli-2.x.x.phar - | sha256sum | cut -d " " -f 1)
    ```

### Updating the website

- [ ] Verify <https://github.com/fin-cli/fin-cli.github.com#readme> is up-to-date

- [ ] Update the [roadmap](https://make.finpress.org/cli/handbook/roadmap/)

- [ ] Update all version references on the homepage (and localized homepages).

- [ ] Tag a release of the website

### Announcing

- [ ] Announce release on the [FIN-CLI Twitter account](https://twitter.com/fincli)
- [ ] Announce using the `/announce` slash command in the [`#cli`](https://finpress.slack.com/messages/C02RP4T41) Slack room.

### Bumping FIN-CLI version again

- [ ] Bump [VERSION](https://github.com/fin-cli/fin-cli/blob/master/VERSION) in [`fin-cli/fin-cli`](https://github.com/fin-cli/fin-cli) again.

    For instance, if the release version was `2.8.0`, the version should be bumped to `2.9.0-alpha`.

    Doing so ensures `fin cli update --nightly` works as expected.

- [ ] Change the version constraint on `"fin-cli/fin-cli"` in `fin-cli/fin-cli-bundle`'s [`composer.json`](https://github.com/fin-cli/fin-cli-bundle/blob/main/composer.json) file back to `"dev-main"`.

    ```
    composer require fin-cli/fin-cli:dev-main
    ```
