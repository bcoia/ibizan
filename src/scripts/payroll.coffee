# Description:
#   Your dog friend is running tasks on a schedule
#
# Commands:
#
# Notes:
#
# Author:
#   aaronsky

moment = require 'moment'
schedule = require 'node-schedule'

{ HEADERS, STRINGS, TIMEZONE } = require('../helpers/constants')
Organization = require('../models/organization').get()
strings = STRINGS.payroll

module.exports = (robot) ->
  Logger = require('../helpers/logger')(robot)

  isAdminUser = (user) ->
    return user? and user in process.env.ADMINS.split(" ")
  
  # Weeks ‘start’ on Sunday morning.
  
  dailyReport = (reports, today, yesterday) ->
    PAYROLL = HEADERS.payrollreports
    response = "DAILY WORK LOG: #{yesterday.format('dddd MMMM D YYYY').toUpperCase()}\n"
    logBuffer = ''
    offBuffer = ''

    for report in reports
      recorded = false
      if report[PAYROLL.logged] > 0
        status = "#{report.extra.slack}:\t#{report[PAYROLL.logged]} hours"
        notes = report.extra.notes?.replace('\n', '; ')
        if notes
          status += " \"#{notes}\""
        projectStr = ''
        if report.extra.projects? and report.extra.projects?.length > 0
          for project in report.extra.projects
            projectStr += "##{project.name} "
        if projectStr
          projectStr = projectStr.trim()
          status += " #{projectStr}"
        status += "\n"
        logBuffer += "#{status}"
        recorded = true
      if report[PAYROLL.vacation] > 0
        offBuffer += "#{report.extra.slack}:\t#{report[PAYROLL.vacation]} hours vacation\n"
        recorded = true
      if report[PAYROLL.sick] > 0
        offBuffer += "#{report.extra.slack}:\t#{report[PAYROLL.sick]} hours sick\n"
        recorded = true
      if report[PAYROLL.unpaid] > 0
        offBuffer += "#{report.extra.slack}:\t#{report[PAYROLL.unpaid]} hours unpaid\n"
        recorded = true
      if not recorded
        offBuffer += "#{report.extra.slack}:\t0 hours\n"
    response += logBuffer
    if offBuffer.length > 0
      response += "DAILY OFF-TIME LOG: #{yesterday.format('dddd MMMM D YYYY').toUpperCase()}\n"
      response += offBuffer
    return response

  # */1 * * * *
  generateDailyReportJob = schedule.scheduleJob '0 9 * * *', ->
    if not Organization.ready()
      Logger.warn "Don\'t make scheduled daily report,
                  Organization isn\'t ready yet"
      return
    yesterday = moment.tz({hour: 0, minute: 0, second: 0}, TIMEZONE).subtract(1, 'days')
    today = moment.tz({hour: 0, minute: 0, second: 0}, TIMEZONE)#.add(1, 'days')
    Organization.generateReport(yesterday, today)
      .catch((err) ->
        Logger.errorToSlack "Failed to produce a daily report", err
      )
      .done(
        (reports) ->
          numberDone = reports.length
          report = dailyReport reports, today, yesterday
          Logger.logToChannel report,
                              'bizness-time'
          Logger.logToChannel "Daily report generated for
                               #{numberDone} employees",
                              'ibizan-diagnostics'
      )


  # Ibizan will export a Payroll Report every other Sunday night.
  generatePayrollReportJob = schedule.scheduleJob '0 20 * * 0', ->
    if not Organization.ready()
      Logger.warn "Don\'t make scheduled payroll report,
                  Organization isn\'t ready yet"
      return
    else if not Organization.calendar.isPayWeek()
      Logger.warn "Don\'t run scheduled payroll reminder,
                   it isn't a pay-week."
      return
    twoWeeksAgo = moment().subtract(2, 'weeks')
    today = moment()
    Organization.generateReport(twoWeeksAgo, today, true)
      .catch((err) ->
        Logger.errorToSlack "Failed to produce a salary report", err
      )
      .done(
        (reports) ->
          numberDone = reports.length
          Logger.logToChannel "Salary report generated for
                               #{numberDone} employees",
                              'ibizan-diagnostics'
      )

  robot.router.post '/ibizan/diagnostics/payroll', (req, res) ->
    body = req.body
    if body.token is process.env.SLASH_PAYROLL_TOKEN
      if not isAdminUser body.user_name
        res.status 403
        res.json {
          "text": strings.adminonly
        }
      else
        response_url = body.response_url
        if response_url
          comps = body.text || []
          start = if comps[0] then moment(comps[0]) else moment().subtract(2, 'weeks')
          end = if comps[1] then moment(comps[1]) else moment()
          Organization.generateReport(start, end, true)
          .catch(
            (err) ->
              Logger.errorToSlack "Failed to produce a salary report", err
              Logger.log "POSTing to #{response_url}"
              payload =
                text: 'Failed to produce a salary report'
              robot.http(response_url)
              .header('Content-Type', 'application/json')
              .post(JSON.stringify(payload))
          )
          .done(
            (reports) ->
              numberDone = reports.length
              Logger.log "Payroll has been generated"
              Logger.log "POSTing to #{response_url}"
              payload =
                text: "Salary report generated for #{numberDone} employees"
              robot.http(response_url)
              .header('Content-Type', 'application/json')
              .post(JSON.stringify(payload)) (err, response, body) ->
                if err
                  response.send "Encountered an error :( #{err}"
                  return
                if res.statusCode isnt 200
                  response.send "Request didn't come back HTTP 200 :("
                  return
                Logger.log body
          )
          res.status 200
          res.json {
            "text": "Generating payroll..."
          }
        else
          res.status 500
          res.json {
            "text": "No return url provided by Slack"
          }
    else
      res.status 401
      res.json {
        "text": "Bad token in Ibizan configuration"
      }

  robot.respond /payroll (.*) (.*)|payroll (.*)|payroll/i, (res) ->
    user = Organization.getUserBySlackName res.message.user.name
    Logger.debug "matches: #{res.match[1]} #{res.match[2]} #{res.message.user.name}"
    if res.match[1] and not res.match[2]
      user.directMessage "You must provide both a start and end date."
      Logger.addReaction 'x', res.message
    else if isAdminUser res.message.user.name
      start = if res.match[1] then moment(res.match[1]) else moment().subtract(2, 'weeks')
      end = if res.match[2] then moment(res.match[2]) else moment()
      Organization.generateReport(start, end, true)
      .catch(
        (err) ->
          response = "Failed to produce a salary report: #{err}"
          user.directMessage response, Logger
          Logger.error response
      )
      .done(
        (reports) ->
          numberDone = reports.length
          response = "Payroll has been generated for #{numberDone} employees
                      from #{start.format('dddd MMMM D YYYY')}
                      to #{end.format('dddd MMMM D YYYY')}"
          user.directMessage response, Logger
          Logger.log response
      )
      Logger.addReaction 'dog2', res.message
    else
      user.directMessage strings.adminonly
      Logger.addReaction 'x', res.message

  # Users should receive a DM “chime” every other Friday afternoon to
  # inform them that payroll runs on Monday, and that unaccounted-for
  # time will not be paid.
  reminderJob = schedule.scheduleJob '0 13 * * 5', ->
    if not Organization.ready()
      Logger.warn "Don\'t run scheduled payroll reminder,
                  Organization isn\'t ready yet"
      return
    else if not Organization.calendar.isPayWeek()
      Logger.warn "Don\'t run scheduled payroll reminder,
                   it isn't a pay-week."
      return
    for user in Organization.users
      user.directMessage "As a reminder, payroll will run on Monday.
                          Unrecorded time will not be paid.",
                         Logger
