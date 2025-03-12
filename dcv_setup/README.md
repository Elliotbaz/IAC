# TerraZero NICE DCV SET UP

## Concept on how it works
- the cloud formation pulls from S3 `unity-elliot-test` and the `dcv_setup.zip` files
- docker gets installed on the newly lunched ec2 instance and docker gets installed
- the files pulled gets unzipped in the ec2 and the bash script `dcv-container-build.sh` runs

This script does all the configuration related to setting up nice dcv containers. it also creates an init.sh script in docker that we would be using 
to initialize our dcv session with the flags appropriately. 


NOTE: This configuration in this scripts does not create a session, it only lunches ec2 and prepares everything we need to get docker running with dcv, so all you need to do to get a session is simply do in the docker is dcv create-session --owner dcv session-name-here 
