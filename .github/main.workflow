workflow "Release" {
  on = "push"
  resolves = [
    "Trigger GitHub release",
  ]

  # GitHub actions are too slow for this, it takes more than 15 mins.
  # Publishing to npm from GH actions is a cool idea, but it's a lot faster to
  # publish locally.
  # "Publish to npm",
}

action "Trigger GitHub release" {
  uses = "./.github/actions/trigger-github-release/"
  secrets = ["GITHUB_TOKEN"]
  env = {
    COMMIT_AUTHOR_NAME = "Babel Bot"
    COMMIT_AUTHOR_EMAIL = "babel-bot@users.noreply.github.com"
  }
  needs = ["Create release tag"]
}

action "Publish to npm" {
  uses = "docker://node:10"
  secrets = ["NPM_TOKEN"]
  runs = "make"
  args = "publish-ci"
  env = {
    CI = "true"
  }
  needs = ["Create release tag"]
}

# When GitHub Actions will support the "release" event for public
# repositories, we won't need this checks anymore.
action "Create release tag" {
  uses = "./.github/actions/create-release-tag"
  needs = [
    "Is version commit",
    "On master branch",
  ]
}

action "Is version commit" {
  uses = "./.github/actions/filter-commit-message"
  # This regex is run using "grep -P".
  # The (-\\S+) part is for 7.0.0-beta.1 releases.
  args = "^v(\\d+\\.){2}\\d+(-\\S+)?$"
}

action "On master branch" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}

workflow "Welcome comment" {
  on = "issues"
  resolves = ["Create Comment"]
}

action "Is action 'opened'" {
  uses = "actions/bin/filter@0dbb077f64d0ec1068a644d25c71b1db66148a24"
  args = "action opened"
}

action "Create Comment" {
  uses = "babel/actions/create-welcome-comment@master"
  secrets = ["GITHUB_TOKEN", "BOT_TOKEN"]
  needs = ["Is action 'opened'"]
}
