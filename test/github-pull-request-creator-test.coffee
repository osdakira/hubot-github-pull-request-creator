Helper = require('hubot-test-helper')
chai = require 'chai'
http = require 'http'
expect = chai.expect

helper = new Helper('../src/github-pull-request-creator.coffee')
process.env.EXPRESS_PORT = 8080

describe 'github-pull-request-creator', ->
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  it 'responds to pull-request create', ->
    @room.robot.github.post = (url, data, callback) ->
      if url.match(/pulls$/)
        expect(data).to.eql {
          title: 'test-123-456'
          body: 'Created By alice on room1 Channel\n#123\n#456'
          head: 'master'
          base: 'feature/test'
        }
        callback({
          number: 100
          html_url: "https://github.com/any_url"
        })
      else if url.match(/assignees$/)
        expect(data).to.eql { assignees: [] }
        callback()

    @room.user.say('alice', '@hubot pull-request create feature/test from master with test-123-456').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot pull-request create feature/test from master with test-123-456']
        ['hubot', '@alice Create pull-request! https://github.com/any_url']
      ]

  it 'POST /hubot/github-pull-request-creator?room=Room', ->
    key = process.env.HUBOT_GITHUB_TO_SLACK_NAME_MAP_KEY
    @room.robot.brain.set(key, { githubName: { slackName: "slackId" } })

    @room.robot.github.post = (url, data, callback) ->
      if url.match(/pulls$/)
        expect(data).to.eql {
          title: 'test-123-456'
          body: '\n#123\n#456'
          head: 'master'
          base: 'feature/test'
        }
        callback({
          number: 100
          html_url: "https://github.com/any_url"
        })
      else if url.match(/assignees$/)
        expect(data).to.eql { assignees: ["githubName"] }
        callback()

    @room.robot.send = (options, message) ->
      expect(options).to.eql { room: "12345" }
      expect(message).to.eql "<@slackId>\nPull Request was created! https://github.com/any_url"

    req = http.request
      host: "localhost"
      port: 8080
      path: "/hubot/github-pull-request-creator?room=12345"
      method: 'POST'
      headers: {
        'Content-Type': 'application/json',
      },
      (res) ->
        console.log (res)
    req.write(
      JSON.stringify
        title: 'test-123-456'
        head: 'master'
        base: 'feature/test'
        assignees: ["githubName"]
    )
    req.on 'error', (err) ->
      throw err unless err.errno == "ECONNRESET"
    req.end()
