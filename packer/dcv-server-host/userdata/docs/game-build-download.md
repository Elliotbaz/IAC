# Downloading the Unity Build from S3

This script is designed to download, unzip, and prepare a game build, likely for deployment in a Docker container. Here's a breakdown of what the script does and some considerations:

### Detailed Breakdown:

1. **Logging Setup**:
   - Defines a `log` function to timestamp and log messages to `/var/log/userdata.log`.

2. **Unzip Installation**:
   - Installs `unzip` if not already installed, which is necessary for extracting the game build.

3. **Directory Creation**:
   - Creates the directory `/opt/dcv/game-build` where the game build will be unzipped.

4. **Permissions Setup**:
   - Sets permissions and ownership of the game directory to `ubuntu:docker` and ensures the directory is executable.

5. **Downloading the Game Build**:
   - Uses `aws s3 cp` to download a game build zip file from an S3 bucket. The exact bucket and path are set by environment variables (`UNITY_BUILD_BUCKET`, `UNITY_BUILD_PATH`, `UNITY_BUILD_VERSION`).

6. **Unzipping the Build**:
   - Unzips the downloaded game build file into the `/opt/dcv/game-build` directory.

7. **Final Permissions**:
   - Again, adjusts permissions to ensure the content can be accessed by the appropriate user/group.

### Key Points:

- **Automation**: This script automates the process of downloading and setting up a game build, crucial for continuous deployment or automated game server setups.

- **Environment Variables**: The script uses environment variables for flexibility, allowing different builds or versions to be specified without changing the script.

- **Security**: By setting specific permissions, it ensures that only the intended user/group (`ubuntu:docker`) can interact with the game files, which is good practice for security.

- **Error Handling**: The script uses `