# Setting up Flight Storage with your Dropbox account

This doc goes over the steps required to set up a Dropbox account to be used with Flight Storage.

## Create an app

From the Dropbox app page ([link](https://www.dropbox.com/developers/apps/)), click `Create app`.

The following settings are the recommended settings; if you know what you are doing, most of them can be changed to suit your preferences.

### Create a new app on the DBX Platform

1. Choose an API - Scoped access

1. Choose the type of access you need - Full Dropbox

1. Name your app - Can be any name, "Flight Storage" is recommended.

### Settings

The only relevant information here is **Generate access token** under the `OAuth 2` section. Click the `Generate` button and note the generated code as this is a required credential for Flight Storage. This code will expire 4 hours after generation; you will need to return to this page to generate a new code when it does.

### Permissions

This tab has a large number of checkbox options to give Flight Storage access to various aspects of your Dropbox account. The only options which must be selected are:

* `account_info.read` (Selected by default)

* `files.metadata.read`

* `files.content.write`

* `files.content.read`

---

Click `Submit`

## Configure the Dropbox provider in Flight Storage

Once you have completed the creation steps, you are ready to configure Flight Storage to use your Dropbox account. Run `bin/storage configure` (source) / `flight storage configure` (package), and enter the code that you saved earlier.

Once you have entered the code, run `bin/storage list` (source) / `flight storage list` (package) to ensure that your code is correct. If you get an output matching that of your account contents, you have successfully set up Flight Storage with your Dropbox account.
