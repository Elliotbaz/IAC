# DCV Server Host

## Updating Unity Build Version

### Copy the Linux client build
You currently have to copy the latest build from the addressables bucket. It's always called `ClientBuild.zip`. When the Unity team releases a new build, they will tell you the version number. Use this in your naming convention. 

```sh
aws s3 cp s3://addressables-aux-18f71b13/StandaloneLinux64/Player/ClientBuild.zip s3://intraverse-dev-builder-objects-18f71b13/unity-builds/unity-build-1.2.4.zip
```

Actually, I think they may be pushing to this now:
```sh
aws s3 cp s3://addressables-dev/StandaloneLinux64/Player/ClientBuild.zip s3://intraverse-dev-builder-objects-18f71b13/unity-builds/unity-build-late
```

### Testing Manually on an Existing Environment
You may want to do a quick test of a Unity client build on an existing environment before you kick off a new Packer build.

1. Stop existing containers
```sh
docker stop dcv-8080 dcv-8081
```

2. Remove existing Unity client files.
```sh
sudo rm -rf /opt/dcv/game-build/*
```

3. Download the latest Unity client build
```sh
aws s3 cp s3://intraverse-dev-builder-objects-18f71b13/unity-builds/unity-build-latest.zip /opt/dcv/game-build/
s3://intraverse-dev-builder-objects-18f71b13/unity-builds/unity-build-latest.zip
```

4. Unzip the files
```sh 
sudo unzip -o /opt/dcv/game-build/unity-build-latest.zip -d /opt/dcv/game-build/
```

5. Set ownership of the game build folder recursively
```sh
sudo chown -R ubuntu:docker /opt/dcv/game-build
```

6. Set permissions on the game build folder recursively
```sh
sudo chmod -R 755 /opt/dcv/game-build
```

7. Re-run your containers

### Build a new AMI with Packer
This will launch a temporary EC2 with the necessary key and security group, upload the required files, and run the provisioning scripts before creating an AMI and then tearing down all of the infrastructure it created.
```bash
packer build dcv-server-ami.pkr.hcl
```

I have updated the Docker build to use separate build stages for the heavier base software packages and config and the more light-weight custom Intraverse software. This way if we're not updating community packages, we don't have to wait on the full build. This gives us the ability to make quick updates to our Unity build and custom scripts. The above command will create a new AMI from the latest base AMI with an updated Unity build and custom utilities.

### Update the AMI Id in the Autoscaling Group With Terraform
The DCV Server host machines are managed by an Autoscaling Group (ASG). Once the new AMI is available, you can update the value of the AMI id and apply the changes with Terraform.

After updating the AMI id in `api-infrastructure/dcv-cm-api-ec2.tf`, run the following command. Make sure to authenticate with AWS if you haven't already.

**Change into the infrastructure directory**
```sh
cd api-infrastructure
```

**Apply Terraform**
```sh
terraform apply
```

Review the plan, type "yes" and hit enter.

> *TODO: this could all be simply automated in a GitHub Actions workflow.*


### Updating Lower-level Images
The base image used by the Packer config mentioned above is built in layers. If you update the lower level images, you need to update all higher images in the stack. This is added complexity in updating base images is a trade-off in favor of speeding up and simplifying updates to the highest image in the stack. 

The expectation is that updates to the community packages and server software will be relatively rare and can tolerate a longer turn-around time by comparison with updates to the Unity build and custom utilities, which will need to be 

## Comprehensive Overview
The following concisely explains each step of the AMI build process from a high level.

> NOTE: *Most of these steps include the installation and config of software dependencies related to that particular step. There may be some dependencies that are used in later steps. Ideally, I would like for any common software dependencies to be listed in each script but installed in one place. For now, this structure has been helpful in understanding what each step does and why we need it. Many of them were adjusted significantly in order to meet our specific engineering requirements, so it makes sense to have them where they are in development. However, it might make more sense over time to refactor how dependencies are maintained.(One good example being the AWS CLI. It first becomes a necessary as early as the Nvidia driver download, but is used in a much more crucial capacity for later requirements)*

1. **Variables are defined.** These are the values that will be often updated per run like the version number, base AMI, game build, and description.
2. **Source values are set.** This includes the final AMI name, the base image used, instance type requirement, instance profile, etc.
3. **Run `init.sh`.** Downloads and installs OS software updates and upgrades.
4. **Upload scripts and fix permissions.** All of the provisioning scripts for both the host and the containers are version controlled in this codebase and uploaded at build time. This step uploads the current versions of these files to a designated folder and sets the ownership and permissions accordingly.
5. **Nvidia driver setup**.
    - `disable-nouveau.sh` disables the default graphics drivers so we can install Nvidia drivers then it reboots.
    - `nvidia-driver-install.sh` downloads and installs the specified Nvidia drivers.
6. **Docker setup**. Installs and configures Docker and Nvidia-Docker so that we can manage containers with support for Nvidia drivers inside the containers.
7. **Intraverse game build**. Downloads the specified Unity build for Intraverse from the bucket.
8. **DCV container build**. Builds the Docker images that will run the DCV Server environments.
9. **Download logs**. Each step of the build writes messages to a log file that we download for debugging and troubleshooting the build.


## Technical Breakdown
This is a detailed technical explanation of each step and why they are necessary.

> TODO: *Document all steps. I need to make adjustments to step 8, so I'm taking the opportunity to write this doc but all of these steps could use improvements to the documentation, whether it was lacking to start with, documented in disparate locations or have since changed and need updating.*

### 8. DCV Container Build

**Background.** I want to be able to iterate faster on the updates to the build scripts. I have reduced the time to update the AMI from 23 minutes to 9 minutes by separating the host build from the Docker image build. However, we can reduce this down to maybe 1-3 minutes by breaking the Docker image into stages. What kills us on image build time is the Nvidia drivers. The same installation process must occur on both the host and the container and it's lengthy. 

**Concerning provisioning speed.** None of this affects the launch time for providing server capacity. This whole part of the process happens during development. However, it does lead to a lot of wasted time during development where you have to wait on parts of the build to complete where no changes have been made. 

**Separating Docker builds into stages.** What I want to do is have separate stages for the base Docker image and the scripts. This way most of the software package and GPU driver setup is already built into a base image. Then if we need to iterate rapidly on the unity build version update or the stream management codebase we can start with the base image and create the final updated build in seconds. 

**Considering image size.** At some point we may want to revisit what software can be deleted in order to reduce the final image build size.

## Breaking up AMI Build Stages

### I. Software and Drivers

```sh
packer build dcv-server-ami-host-base.pkr.hcl
```

### II. Docker Base Stage

```sh
packer build dcv-server-ami-docker-base.pkr.hcl
```

### III. Docker Final Stage and Unity Build Download

> NOTE: *These two stages are so quick, I combined them.*

```sh
packer build dcv-server-ami.pkr.hcl
```

**Concerning Unity Build Download**. Now that we are using a mount for the game executable instead of copying it into the image, we can save the unity build download for the final stage. In fact, this may not even be necessary for the AMI at all. We could technically save this for the userdata script. So, rather than having to build a new AMI to update the game build, all we have to do is update the 

