# Intraverse Infrastructure

## Ultimate Vision for IaC in Broad Terms
- I want to be able to express and manage most all of the resources that make sense through code commits, whether it's deploying stacks of resources through CI/CD or by importing out-of-band changes into the codebase.
- I want to be able to detect when someone makes changes to infrastructure through drift detection and conrrect it as needed whether by updating the code to reflect the improvements or rolling back mistakes by applying what the state expects.
- I want to be able to reuse code modules while also versioning them to avoid nasty and untimely upgrades as we develop improvements and need to carefully plan for promotion of changes to production stacks.

## Current Efforts

### GitHub Actions OIDC
I have implemented an early version of a pattern of infrastructure management and trust relationships between accounts and with GitHub. I'll document a more detailed workflow soon, but here it is broadly speaking so I can quickly remember next time I make progress.\
- GitHub now has an identity provider in the AWS management account.
- The GitHub IDP has a role attached with policies that allow management of terraform state in a central S3 bucket.
- Terraform state is managed in a single bucket, where state files for each memeber account will be divided into their own directory.
- There is a GitHub Actions workflow that requests to assume the GitHub Actions role in the management account.
- The TerraZero_QA member account has an assume role that trusts the GitHub Actions IdP role in the management account.
- The TerraZero_QA folder in this repo has a provider block that specifies to use this role.
- GitHub actions first assumes the IdP role to get a short-lived token through an OIDC flow with the AWS management account. 
- Because of the trust relationship with the QA member account, it is able to manage resources allowed in that memeber account role policy as well as modify state in the central bucket.

#### Next Steps
- Clean up all of the naming conventions to make sure they will be readable as we add more member accounts to this flow.
- Create a reusable module and version it so that we have control over when to promote different environments to newer versions.
- Put branch restrictions on the repo, since this will give anyone with access to the repo to modify infrastructure resources through merges and pull requests.
- Start adding policies and member accounts.

### Terraform Roles
I'm currently working on getting trust relationships established that carfully allow Terraform agents to assume the appropriate role with properly configured permissions. I'm also storing state in a central bucket in the management acount to limit access and to simplify management. This means that each role needs certain allow actions on certain objects in the bucket in the management account while also being able to manage resources in their respective memeber account. 

### Unity Team Roles
I'm creating a role that will provide properly-configured permissions to the memebers of the Unity team. Right now, everyone on the team uses the `OrganizationAccountAccessRole`. They need permissions to read from certain S3 buckets asap. I'm going to copy the permissions from this familiar policy to create the initial role. Over time, I will gather a list of actions taken by members of the team through CloudTrail and then start popping unused actions and resources off of the role until we start getting pushback from the team.

> If you don't find yourself adding permissions back, you're not deleting enough permissions.

#### Role Specs
```hcl
resource "aws_iam_role" "trusted_role" {
  name = "your-role-name"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::097157727296:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

```

### Render Streaming
As Elliot experiments with POCs to gather information about what our capabilities are, I'm going back and codifying and automating the viable bits as they come together. We have so far determined that Linux is not only compatible, it is superior in nearly ever way. We have also determined that we need GPU architecture to run the game. Our next step is to test out how builds run in containers.

## Next Steps / Future Plans
### Ideally, we want to:
- Move to Linux
- Move to containers
- Build in autoscaling
- Import most of the existing resources in to IaC
- 

## Other Suggestions

I also want to add CloudFront distributions to the addressables buckets and a WAF/Web ACL to whatever load balancers we put in front of our container clusters.

I also like the idea of using Kubernetes to orchestrate container services, even through something like OpenShift where we can manage all of the application deployment code in Helm charts. That could be overkill for this project at this point, but something to keep in mind.

We need a backups account for data protection in the case of a malicious encryption incident. We need to start thinking about disaster recovery plans, too.

We need to get everyone moved over to SSO through Identity Manager. This will allow us to enforce MFA and have better control over user permissions.

