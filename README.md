# hubot-github-pull-request-creator

[![CircleCI](https://circleci.com/gh/osdakira/hubot-github-pull-request-creator.svg?style=svg)](https://circleci.com/gh/osdakira/hubot-github-pull-request-creator)

Create pull-request on github

See [`src/github-pull-request-creator.coffee`](src/github-pull-request-creator.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-github-pull-request-creator --save`

Then add **hubot-github-pull-request-creator** to your `external-scripts.json`:

```json
[
  "hubot-github-pull-request-creator"
]
```

## Sample Interaction

```
user1>> hubot pull-request create <base> from <head> with <title>
hubot>> @user1 Pull Request was created! https://github.com/any_url
```

## Webhook Settings

```
curl -v -XPOST \
-H "Content-Type: application/json" \
"http://localhost/hubot/github-pull-request-creator?room=test_room" \
-d '{"base":"master","head":"feature/branch","title":"[Test] Test Pull Request for labot","assignees":["githubName"]}'
```

## NPM Module

https://www.npmjs.com/package/hubot-github-pull-request-creator
