# Custom Trust Role for AWS Using OIDC

> NOTE: I'm going to create a ticket for this in the backlog but table it for now. Since it's a custom script we would have to put a high level of effort into engineering our own OIDC solution. I was hoping we could set up a trust role that grabs short-lived tokens the way GitHub or Terraform Cloud do, but there's more going on behind the scenes of those interfaces than I realized. In the mean time we should at least remove the long-lived AWS keys from source control, set them as environment variables in the unity cloud console and then rotate them.

## Links
[JIRA | Ticket ENG-967: SPIKE Secure Tokens & Keys](https://terrazerotech.atlassian.net/browse/ENG-967)

[AWS OIDC Trust Role - GitHub](https://github.com/appvia/terraform-aws-oidc/tree/main)

## Using Environment Variables
- Go to the Unity Cloud console.
- Select the "TZ-Dev" project.
- Go to "DevOps" service
- Expand "Build Automation".
- Go to "Configurations".
- Seelct the "Advanced Settings" tab.
- Scroll down to the "Environment Variables" section.
- Any key-value pairs you add here should be accessible in the script.

## Setting up Trust Relationships for OIDC

The preferred approach to authenticating with AWS resources is to retrieve short-lived tokens through OpenID Connect (OIDC). To do this, we need to set up a trust relationship between Unity and AWS. This way authentication tokens can be retrieved on the fly and expire after usage. This prevents the need to potentially leak sensitive keys or long-lived tokens.

[Custom IAM OIDC Integration](https://github.com/appvia/terraform-aws-oidc)

To integrate AWS IAM roles with an OpenID Connect (OIDC) identity provider (IdP) such as Unity Cloud Build, and obtain short-lived tokens for authentication, you can follow these steps:

1. **Set Up OIDC Identity Provider in AWS IAM**:
   - Go to the AWS Management Console and navigate to the IAM service.
   - In the IAM dashboard, click on "Identity providers" in the left-hand menu.
   - Choose "Add provider" and select the OpenID Connect provider type.
   - Follow the instructions to configure your Unity Cloud Build as an OIDC provider.

2. **Create an IAM Role**:
   - In the IAM dashboard, navigate to "Roles" and click on "Create role".
   - Choose the "Another AWS account" option and enter the Unity Cloud Build AWS account ID.
   - Attach a policy that grants the necessary permissions to access your S3 bucket.
   - During the role creation, choose "Require external ID" and specify a unique external ID.

3. **Configure Trust Relationship**:
   - Edit the trust relationship of the IAM role you created.
   - Add a condition that requires the existence of the OIDC token from Unity Cloud Build in the `sts:ExternalId` field.

4. **Update Your C# Script**:
   - Use the AWS SDK for .NET (such as AWSSDK.Core and AWSSDK.SecurityToken) in your C# script.
   - Implement code to assume the IAM role using the OIDC token provided by Unity Cloud Build.
   - Make sure to pass the external ID as part of the assume role request.

5. **Testing**:
   - Test your C# script locally with mocked OIDC tokens.
   - Once it works, deploy your script to Unity Cloud Build and trigger the build process.

6. **Ensure Proper Token Rotation**:
   - Since you want short-lived tokens, ensure that your script handles token expiration gracefully and retrieves new tokens as needed.
   - Unity Cloud Build should provide a mechanism to obtain fresh OIDC tokens periodically.

7. **Monitor and Logging**:
   - Implement logging and monitoring in your script to track token acquisition, role assumption, and any errors encountered during the process.

Remember to adhere to the principle of least privilege when assigning permissions to IAM roles, and regularly review and rotate credentials for security purposes.


## Code Example
```cs
using Amazon;
using Amazon.SecurityToken;
using Amazon.SecurityToken.Model;
using System;

class Program
{
    static async Task Main(string[] args)
    {
        // Your OIDC identity token obtained through your authentication flow
        string oidcToken = "YOUR_OIDC_TOKEN";

        // The ARN of the AWS IAM role you want to assume
        string roleArn = "arn:aws:iam::123456789012:role/YourRole";

        // Create an instance of the AWS Security Token Service client
        var stsClient = new AmazonSecurityTokenServiceClient();

        // Assume the role with the OIDC token
        AssumeRoleWithWebIdentityRequest assumeRequest = new AssumeRoleWithWebIdentityRequest
        {
            RoleArn = roleArn,
            WebIdentityToken = oidcToken,
            RoleSessionName = "YourSessionName" // Provide a name for the session
        };

        try
        {
            AssumeRoleWithWebIdentityResponse assumeResponse = await stsClient.AssumeRoleWithWebIdentityAsync(assumeRequest);

            // Extract temporary credentials from the response
            string accessKeyId = assumeResponse.Credentials.AccessKeyId;
            string secretAccessKey = assumeResponse.Credentials.SecretAccessKey;
            string sessionToken = assumeResponse.Credentials.SessionToken;

            // Configure AWS credentials with the temporary credentials
            var temporaryCredentials = new Amazon.Runtime.SessionAWSCredentials(accessKeyId, secretAccessKey, sessionToken);

            // Configure the AWS S3 client with the temporary credentials
            var s3Client = new AmazonS3Client(temporaryCredentials, RegionEndpoint.USWest2);

            // Example: List objects in a bucket
            ListObjectsV2Request request = new ListObjectsV2Request
            {
                BucketName = "your-bucket-name"
            };
            ListObjectsV2Response response = await s3Client.ListObjectsV2Async(request);

            // Process the response...
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error assuming role: {ex.Message}");
        }
    }
}

```