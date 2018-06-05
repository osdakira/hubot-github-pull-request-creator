# Description
#   Create pull-request on github
#
# Dependencies:
#   "githubot": "1.0.1"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_SLACK_TOKEN
#   HUBOT_GITHUB_REPO
#   HUBOT_GITHUB_TO_SLACK_NAME_MAP_KEY
#
# Commands:
#   hubot pull-request create <base> from <head> with <title>
#
#   add `HUBOT_URL/hubot/github-pull-request?room=ROOM` to your repository's webhooks.
#
# Author:
#   Akira Osada <osd.akira@gmail.com>

module.exports = (robot) ->
  url = require 'url'
  querystring = require 'querystring'
  github = require("githubot")(robot)
  robot.github = github if robot.constructor.name is "MockRobot" # For Test

  urlApiBase = process.env.HUBOT_GITHUB_API || "https://api.github.com"
  repo = process.env.HUBOT_GITHUB_REPO
  urlApiRepo = "#{urlApiBase}/repos/#{repo}"

  # Call by Webhook
  robot.router.post "/hubot/github-pull-request-creator", (req, res) ->
    query = querystring.parse url.parse(req.url).query
    room = query.room || "anonymous"
    assignees = req.body.assignees || []
    params =
      base: req.body.base
      head: req.body.head
      title: req.body.title
      assignees: assignees
      body: ""

    _makePullRequest params,
      (pull) ->
        slackIds = _getSlackIdByGithubName(params.assignees)

        message = ""
        message += slackIds.join(" ") + "\n" if slackIds.length
        message += "Pull Request was created! #{pull.html_url}"
        robot.send { room: room }, message
      (response) ->
        # robot.send { room: query.room }, "Failed #{response.body}!"

    res.end ""

  # Call by Slack
  robot.respond /pull-request create (\S+) from (\S+)(?: with (.+))*$/i, (res)->
    slackName = res.envelope.user.name || "anonymous"
    room = res.envelope.room || "anonymous"

    title = res.match[3] || "The PR created by #{slackName} with bot"
    params =
      base: res.match[1]
      head: res.match[2]
      title: title
      assignees: []
      body: "Created By #{slackName} on #{room} Channel"

    _makePullRequest params,
      (pull) ->
        res.reply "Create pull-request! #{pull.html_url}",
      (response) ->
        res.reply "Failed #{response.body}!"

  # Functions

  _makePullRequest = (params, done, fail) ->
    { head, base, title, assignees, body } = params
    assignees ||= []

    if title
      issueNumbers = title.match(/\d+/g)
      if issueNumbers
        body += "\n" + issueNumbers.map((x) -> "##{x}").join("\n")

    data =
      title: title
      body: body
      head: head
      base: base

    github.handleErrors (response) -> fail(response)

    pullUrl = "#{urlApiRepo}/pulls"
    github.post pullUrl, data, (pull) ->
      done(pull)
      _assign(pull.number, assignees)

  _assign = (pullNumber, assignees) ->
    assigneesUrl = "#{urlApiRepo}/issues/#{pullNumber}/assignees"
    assigneesParams = { "assignees": assignees }
    github.post assigneesUrl, assigneesParams, (res) ->
      # ignore any response
      # console.log res.body

  _getSlackIdByGithubName = (assignees) ->
    return [] unless assignees

    githubSlackMap = _fetchGithubSlackMap()
    assignees.map (githubName) -> _convertMention(githubName, githubSlackMap)

  _fetchGithubSlackMap = ->
    key = process.env.HUBOT_GITHUB_TO_SLACK_NAME_MAP_KEY
    robot.brain.get(key) ? {}

  _convertMention = (githubName, githubSlackMap) ->
    slackIdByName = githubSlackMap[githubName]
    return githubName unless slackIdByName

    slackName = Object.keys(slackIdByName)[0]
    slackId = slackIdByName[slackName]
    "<@#{slackId}>"
