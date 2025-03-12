resource "aws_iam_role" "unity_team" {
  name = "intraverse-unity-team-role"
    description = "This is the role for the unity team developers to assume in order to read objects from the addressables bucket in s3 in production."
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

# Read access to the addressables bucket
resource "aws_iam_policy" "unity_team_s3_read_access" {
  name        = "intraverse-unity-team-s3-read-access"
    description = "This policy allows the unity team to read from the addressables bucket in s3."
    policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::addressables-prod",
        "arn:aws:s3:::addressables-prod/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "unity_team_s3_read_access" {
    role       = aws_iam_role.unity_team.name
    policy_arn = aws_iam_policy.unity_team_s3_read_access.arn
}

# # permissions to list all of the buckets
# resource "aws_iam_policy" "unity_team_s3_list_access" {
#   name        = "intraverse-unity-team-s3-list-access"
#     description = "This policy allows the unity team to list all of the buckets in s3."
#     policy      = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:ListAllMyBuckets"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "unity_team_s3_list_access" {
#     role       = aws_iam_role.unity_team.name
#     policy_arn = aws_iam_policy.unity_team_s3_list_access.arn
# }
