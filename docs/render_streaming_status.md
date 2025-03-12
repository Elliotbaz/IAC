# Render Streaming Status


## Builder Instance
We build the Render Streaming server images on a dedicated EC2 instance that we refer to as the "Builder". It has all of the tooling and permissions necessary to download Unity builds from an S3 bucket and then package them into a Docker image that uses DCV Server to stream an Ubuntu Gnome desktop to run the Unity executable. The command to run the game includes the user and experience identifiers that are passed to 

### You can demo the game running in containers at :
https://dcv-builder.intraversedev.com:8443/

You will need to use the operating system credentials:
- User: user
- Password: dcv

We still need to build the solution that prepares the game for the user. For now


## Todo
- Upgrade to the latest game release.
- Update the DCV server config to the latest optimizations for display and 

## Known Problems to Fix
Some of these issues may already have fixes that I am unaware of and some of them may be unique to the Load Balancer and Container Cluster. 
- **Game Stability.** In the cluster, the game fails to fully load before quickly exiting. This does not happen when pointing a DNS record directly at a server instance that is running the container. 
- **Display Quality.** The display renders with significant pixelation. I think there may be some resolution configuration that fixed this at some point but I'm not sure if that fixes what I'm seeing. (*NOTE: This is only affecting a direct connection through the Chrome browser. It will not occur when we use the SDK from the Frontend*)
- **Unhealthy Tasks Don't Die.** Sometimes the Render Streaming sessions end but the task stays in the Target Group. We need to add a health check so that these tasks get removed when their sessions stop so that users don't get forwarded to dead sessions.

## Problems that we already have fixes for
Some of the issues with the environment have fixes that we have already resolved in sandbox environments that need to be committed and deployed to the development environment.
- **Automatic Login Configuration.** When a user navigates to a Streaming Server environment, the desktop Operating System requires them to log in. We have a config in a development sandbox that skips this and takes them straight to the game.
- **Forcing GPU Hardware.** The Nvidia drivers share compute jobs with the CPU of the virtual machine. We have found that the performance is better when we force it to only use the GPU. There is a config for this in one of the development sandboxes that should help fix a lot of performance and quality issues.
- **Resolution Optimization.** There is a resolution config in the dev sandbox that improves the display.


## Likely Causes to Investigate
- **Load Balancer Security Group Permissions.** The Load Balancers may be blocking the request and/or response between the Render Streaming server tasks and Unity Cloud. This would explain why the game runs stable on an unsecured EC2 instance, but never fully loads when behind a Load Balancer. 
- **ASG / ECS Security Group Permissions**. The same could be true of the Security Groups that control the traffic for the server environments. 

## Instructions for 