# TerraZero_Dev IaC
This is the infrastructure code for the `TerraZero_Dev` account. 

## Working with a POC
Sometimes, you're going to want to quickly launch a proof of concept using simple default resources. The references to these resources are stored as variables in the `variables.tf` file. As your POC matures into a viable product, you will need to begin integrating it into a more broad and complex stack of resources. 

## Notes

### Concerning Long Term IaC Management
This is a quick and simple way to get a small devops team started. Over time, as our team grows and our needs become more complex, we will want to implement some form of CI/CD to maintain some form of sanity. Ideally, when someone wants to make changes to infrastructure, they would do it through pull requests in GitHub that either run Terraform commands through a GitHub Actions workflow or have an interface with Terraform Cloud if we decide to save our state there.

For now, the state is being stored in S3 buckets in AWS and the commands are run manually by the developer from the cli.

### Installing Terraform
Terraform is supported for Linux, Mac, and Windows. I recommend if you're on Windows to use WSL and follow the instructions for Linux. Here are the official docs:

[Official HashiCorp Terraform Installation Docs](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Change into the account directory
```bash
cd terraform/TerraZero_Dev
```

### Authenticate with AWS
At this point follow your usual authentication flow for using the AWS CLI.

### Initialize Terraform
```bash
terraform init
```

### Check for Drift in State
```bash
terraform plan
```

> NOTE: If the plan returns any planned changes, know that an apply command will attempt to make those changes to your infrastructure in the 

### Applying Changes
Once you have updated your code to reflect the infrastructure changes that you wish to make and the plan reflects what you intend to do, run the apply command.
```bash
terraform apply
```

### Importing Existing Infrastructure
This command varies from resource to resource, but you can use the import command to import existing resources into the Terraform state. You will usually do this by passing in the resource id as an argument. 

# Start Generation Here
To execute a command on a running DCV server task in AWS ECS, you can use the following command:

```bash
aws ecs execute-command --cluster <cluster-name> --task <task-id> --container <container-name> --interactive --command "<command-to-execute>"
```

Replace `<cluster-name>`, `<task-id>`, `<container-name>`, and `<command-to-execute>` with the appropriate values for your setup.

For example:
