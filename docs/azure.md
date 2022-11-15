# Setting up an Azure file share

This doc goes over the steps required to set up an Azure file share to be used with Flight Storage.

## Create a storage account

From the Azure dashboard ([link](https://portal.azure.com/)), select `Storage accounts` from the `Azure services` menu.

Create a storage account. The following settings are the recommended settings; if you know what you are doing, most of them can be changed to suit your preferences.

### Basics
- Select a subscription and resource group to create the storage account under. Create a new resource group if required.
- Choose a `Storage account name` and keep note of it, as this is a required Flight Storage credential.
- Pick a region (which region is specific to your preferences).
- Pick a performance setting (if in doubt, use `Standard`).
- Pick a redundancy setting (if in doubt, use defaults).

### Advanced
- Required secure transfer for REST API operations

### Networking
- Enable public access from all networks
  - You may use either of the other options, although there will be further configuration required to get them working. Public access from all networks will still require a valid secret access key.
 
 ### Data protection
- Keep defaults

### Encryption
- Keep defaults

---

Click 'Create'.

## Create a file share

Flight Storage makes use of file share objects within Azure. To create a file share: go to your storage account's dashboard, click `File shares` in the sidebar, and then `+ File share` in the top menu. Pick a name for the file share (and keep note of it), pick a storage tier (recommended: `Transaction optimized`), and click `Create`.

## Fetch an access key

Azure storage accounts make use of secret access keys to limit access to valid users. To fetch an access key: go to your storage account's dashboard, click `Access keys` in the sidebar, and note down one of the two default access keys on the page (required credential for Flight Storage).

## Configure the Azure provider in Flight Storage

Once you have completed the creation steps, you are ready to configure Flight Storage to use your Azure file share. Run `bin/storage configure` (source) / `flight storage configure` (package), and enter the credentials that you saved earlier.

Once you have entered your credentials, run `bin/storage list` (source) / `flight storage list` (package) to ensure that your credentials are correct. If you get an output matching that of your file shares contents, you have successfully set up Flight Storage with the Azure provider.
