# Render Streaming Design and Planning

## Prior Findings Summary
A research effort was commissioned by a previous team that based their findings on the following blog in the AWS public knowledgebase:

[How to run 3D interactive applications with NICE DCV in AWS Batch](https://aws.amazon.com/blogs/compute/how-to-run-3d-interactive-applications-with-nice-dcv-in-aws-batch/)

It was found that after deploying a custom render streaming solution and optimizing for cost and performance, the potential for savings were tremendous.

It was also noted that building a robust, secure, and scalable solution in production would require a substantial engineering cost as well as some degree of ongoing maintenance.

## Proof of Concept
In order to begin to prove out the validity of these claims, we developed a simple demo of Intraverse in a custom environment.

### Findings Summary
- The Linux build from Unity Cloud runs fine.
- It works on mobile. It's actually better than the current Vagon interface both in terms of user experience and performance. The Vagon solution is basically unplayable on mobile, whereas the custom Nice DCV solution is viable and acceptable.
- The performance is better.
- The cost is lower.
- It gives us greater insight into troubleshooting issues with the ability to add and customize our own monitoring, logging and automation.
- We have more control over how we customize and optimize the infrastructure architecture.

## Minimum Viable Product
While we ultimately want to develop a solution that is fully containerized for faster scaling and better automation, there is a path to deploy a viable solution on a much shorter timeline that does not necessarily duplicate most of the work done if planned properly. I am proposing we do this in stages so that we can get away from Vagon as quickly as possibly while developing most of the same tools and interfaces that will also end up powering the long term fully optimized solution.

### Known Requirements
- **Deployment Pipeline**. A deployment pipeline that builds streaming server images whenever unity builds are released. 
- **Server User Automation.** Automation of server-side user creation and external authentication with the user management API and database. Users need to be able to use their existing authentication method and have their server user and session automatically created and authenticated without additional clicks.
> ***NOTE:*** We should consider [NICE DCV Session Manager](https://docs.aws.amazon.com/dcv/latest/sm-admin/what-is-sm.html) and the scope of its functionality for user sessions and automation as well as user cleanup. Does this solution cover these requirements effectively?
- **Environment Autoscaling.** Make sure the capacity can scale without any manual installation steps. Environments need to come online in response to pre-defined capacity thresholds and wait for users to be paired with them.
- **Load Balancing.** Our environments need to be protected behind a load balaner or stack of load balancers for performance and for security.
- **Transient user cleanup.** If mulitple tenants are paired to common server environments, then we need to automate the destruction of their user once their session is ended.
- **Monitoring and Logging.** Instance metrics and server logs need to be captured and stored for analysis for troubleshooting and optimization for cost and performance and later for security compliance and incident response.

## Monitoring and Logging

### What do we want to know?
The following are some questions we might ask to gain insight into the overall optimal configuration of resources both in terms of specification as well as automation.
- How many user sessions shoule we allow per machine?
- What instance type should we use?
- What thresholds should we set for CPU usage? At what point should we trigger scale-in and scale-out events?
- What thresholds should we set for memeory usage?
- What thresholds should we set for network packets?
> ***NOTE:*** This question is also related to the topic of load balancing. Can a single application load balancer handle all of our traffic or do we need to put a network load balancer in front of multiple application load balancers?
- 

## Networking and Load Balancing
At the very least, we need to protect our environments behind at least one application load balancer. My intuition is that we will need to run multiple ALBs behind a Network LB at some point 

## Containerization and Automation
The article above outlines how to build server environments into Docker container images and automate their deployments with AWS Batch service. This will significantly increase the the speed and performance of deploying server capacity while also improving automation to further drive down costs. 

### Known Requirements
- **Image Builder Instance.** Launch an EC2 instance to build a DCV container image.
- **User Credentials Secrets** Store user’s credentials and notification data in AWS Secrets Manager service.
- **Instance Roles and Policies.** The builder instance and the ECS capacity instances need a role with policies for the required authorization.
- **Container Image Repository.** Create a repository on Amazon ECR.
- **Build a DCV Server Image.** Use the builder instance to build and push images to ECR.
- **Set up an SNS Topic.**
- **Configure AWS Batch.**


## Stress and Load Testing
We need a way to simulate load to take steps to prepare for major scaling events.

## Ongoing Cost and Performance Optimization
This will be an ongoing process of collecting data from resource metrics and logs and improving our automation as well as consulting with the engineering teams to communicate code quality improvements that will increase performance, security and cost optimization.

## Security Compliance
What security compliance standards are we considering and what is our timeline for engaging an auditor?

## Penetration Testing
In security, it's not a matter of "if" incidents happen. It's a matter of "when" they happen. Working with security analysts who specialize in penetration tests as well as posting bug bounties online allows us to take an active and preemptive strategy to stay ahead of attackers by patching vulnerabilities as well as keeping a strong defensive posturing so that we are prepared to respond and to mitigate issues.