# Ibizan
_Dog-themed Employee Time Tracking Slack Bot_

Ibizan is a chat bot built on the [Hubot](https://github.com/github/hubot) framework, contracted by [Fangamer](http://fangamer.com/). Ibizan is dedicated to providing an intuitive and interactive interface to managing a timesheet.

## Running ibizan Locally

After cloning the repo and setting the created folder to your current directory, you can test Ibizan hubot by running the following command:

    ./bin/hubot -a slack

This will install dependencies and run the bot. However, it will not work without setting up your configuration (below).

## Configuration

You must set up your configuration before running Ibizan or else it will not start.

### Hubot Slack Token

    HUBOT_SLACK_TOKEN=<your token>

### Google Sheets Spreadsheet

In its current form, Ibizan punch functionality is tightly coupled to the layout of the spreadsheet it pulls from. This will be addressed in future versions.

Create a spreadsheet on Google Sheets that has the following layout:

#### Worksheet 1
* Name - Payroll Reports
* Column Headers:
  * Payroll Date - [Date] MM/DD/yyyy
  * Employee Name - [String]
  * Paid Hours - [Number]
  * Unpaid Hours - [Number]
  * Logged Hours - [Number]
  * Vacation Hours - [Number]
  * Sick Hours - [Number]
  * Overtime Hours - [Number]
  * Holiday Hours - [Number]
* Note: The contents of this sheet are auto-generated, but the name and headers are not.

#### Worksheet 2
* Name - Projects
* Column Headers:
  * Project - [String]
  * Week Starting - [Date]
  * Total # of Hours [Number]
* Note: The contents of this sheet are auto-generated, but the name and headers are not.

#### Worksheet 3
* Name - Raw Data
* Column Headers:
  * Date Entered - [Date]
  * Employee - [String]
  * In - [Date]
  * Out - [Date]
  * Elapsed Time - [Date]
  * Block - [Date]
  * Notes - [String]
  * Project 1 - [String]
  * Project 2 - [String]
  * Project 3 - [String]
  * Project 4 - [String]
  * Project 5 - [String]
  * Project 6 - [String]
* Note: The contents of this sheet are auto-generated, but the name and headers are not.

#### Worksheet 4
* Name - Employees
* Column Headers:
  * Slack User Name - [String]
  * Employee Name - [String]
  * Salary? - [Boolean]
  * Active Hours (Begin) - [Date]
  * Active Hours (End) - [Date]
  * Time Zone - [String]
  * Total Vacation Days Available - [Number]
  * Total Vacation Days Logged - [Number]
  * Total Sick Days Available - [Number]
  * Total Sick Days Logged - [Number]
  * Total Unpaid Days Logged - [Number]
  * Total Overtime - [Number]
  * Total Logged Hours - [Number]
  * Average Hours Logged / Week - [Number]
* Note: The contents of this sheet are auto-generated, but the name and headers are not.

#### Worksheet 5
* Name - Variables
* Column Headers:
  * Vacation Hours (for Salaried Employees)
  * Sick Hours (for Salaried Employees)
  * Time Logging Channel
  * Hounding Channel
  * Exemptions
  * Work Holidays
  * Date 
* Note: The contents of this sheet are auto-generated, but the name and headers are not.

### Google Drive API Service Account

1. Follow the instructions [here](https://developers.google.com/identity/protocols/OAuth2ServiceAccount)
2. When given the opportunity to download your keys (you only can do this once), download it as JSON and save it in the config/ folder. You may need to create this folder.
3. Share your spreadsheet (the one you created before) with the email address given in the downloaded JSON.