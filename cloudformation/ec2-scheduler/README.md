#####The CCS DaaS EC2 scheduler is an optional, There is SandMan is available and already using on few ADO's MLMS, MNPS
* https://github.cms.gov/CCSVDC-Infrastructure/sandman/blob/master/docs/user_manual/index.rst

# Stack AWS Cloudformation: Start/Stop Amazon EC2 instances using AWS Lambda


###### Usage
* Access your AWS account and go to [Amazon S3](https://console.aws.amazon.com/s3/);
* Create a Bucket or use the existing bucket, and click on it;
* Upload the **ec2-startstop.yml** and **ec2-startstop.zip**;
* Click on the **ec2-startstop.yml**, and then on **Properties**;
* Copy the link presented to you, e.g. https://s3.amazonaws.com/S3_BUCKET_NAME/ec2-startstop.yml
* Now, go to [AWS Cloudformation](https://console.aws.amazon.com/cloudformation/);
* Click on **Create Stack**;
    * In the field **Specify an Amazon S3 template URL**, insert the link for your template (copied before), and click next;
    * Put the information needed: in **S3BucketName**, put the name of your Bucket, created/chosen earlier;
    * When launched, resources will be created automatically;
    * After everything is created, go to the Console and verify;

###### CW Event scheduler

* Stop tagged Instances at 5PM EST from Monday to Friday:
```
      cron(0 22 ? * MON-FRI * )
```
* Start tagged Instances at 8:00 AM EST from Monday to Friday:
```
      cron(0 13 ? * MON-FRI * )
```  

After you finish, insert the Tag **AutoStartStop**, with Value **TRUE** on the Amazon EC2 instances that will be part of the Stop/Start. In case any Amazon EC2 instance don't have this Tag, without the Value **TRUE**, it won't be in the Start/Stop execution.  
**TAGS ARE CASE-SENSITIVE!!!**

```
