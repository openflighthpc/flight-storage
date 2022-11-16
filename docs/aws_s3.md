# Setting up an AWS S3 bucket

This doc goes over the steps required to set up an AWS S3 bucket to be used with Flight Storage.

## Create a bucket

From the AWS S3 page ([link](https://aws.amazon.com/s3/)), select `Get started with Amazon S3`. Sign in with your AWS credentials and select `Create bucket`.

The following settings are the recommended settings; if you know what you are doing, most of them can be changed to suit your preferences.

### General configuration

* Bucket name - The name of your bucket. Note this as it is a required credential for Flight Storage.
* AWS Region - The region for your bucket. Consider the map of AWS regions (found [here](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)) and choose an appropriate region. Take note of the region code (e.g. `eu-west-2`) as this is a required credential for Flight Storage.
* Copy settings from existing bucket - If you've already made a bucket and want to create a bucket with the same settings, use this option. If this is your first time creating a bucket, ignore this option.

### Object Ownership

* ACLs disabled

### Block Public Access settings for this bucket

* Block *all* public access

### Bucket Versioning

* Disable

### Tags

If you plan to make a large number of buckets, you can use tags to help organise them.

### Advanced settings

* Object Lock - Disable

---

Click `Create bucket`

## Obtaining an Access Key

When logged in to the AWS console, choose `Security Credentials` from your account's dropdown selection in the top right corner. Under `AWS IAM credentials` select `Create access key`. **Do not close the pop-up until you have retrieved your secret access key, as this may not be obtained later**. Take note of the Access Key ID and Secret Access Key, as these are required credentials for Flight Storage.

## Configure the S3 provider in Flight Storage

Once you have completed the creation steps, you are ready to configure Flight Storage to use your AWS S3 bucket. Run `bin/storage configure` (source) / `flight storage configure` (package), and enter the credentials that you saved earlier.

Once you have entered your credentials, run `bin/storage list` (source) / `flight storage list` (package) to ensure that your credentials are correct. If you get an output matching that of your bucket contents, you have successfully set up Flight Storage with the AWS S3 provider.
