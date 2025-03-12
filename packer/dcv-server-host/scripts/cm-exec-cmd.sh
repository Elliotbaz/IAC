#!/bin/bash

# Function to display help menu
show_help() {
    echo "Usage: $0 [OPTION]"
    echo "This script provides various commands to manage the DCV server and its sessions. Most of these commands are wrappers for DCV commands for familiarity and convenience."
    echo "Options:"
    echo "  list-sessions   List DCV sessions"
    echo "  create-session  Create a new DCV session"
    echo "  close-session   Stop a DCV session"
    echo "  restart-dcv     Restart the DCV server"
    echo "  dcv-status      Check the status of DCV server"
    echo "  nvidia-smi      Run nvidia-smi command"
    echo "  run-game        Run the game"
    echo "  kill-game       Finds the IntraverseClient.x86_64 process and kills it"
    echo "  enter-shell     Enter an interactive shell in the container"
    echo "  run-cmd         Run a command in the container"
    echo "  help            Show this help message"
}

# Function to get the latest task ARN for the specific service
get_task_arn() {
    # Set the AWS region
    AWS_REGION="us-east-1"

    # Set cluster and container names
    CLUSTER_NAME="intraverse-dev-dcv"
    CONTAINER_NAME="dcv"

    # Set the service name
    SERVICE_NAME="intraverse-utils-dcv"

    # Get the latest task ARN for the specific service
    TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query 'taskArns[0]' --output text)
    # TASK_ARN=arn:aws:ecs:us-east-1:585415957264:task/intraverse-dev-dcv/d255a674b3554d539db495f31690ec76
    # TASK_ARN=arn:aws:ecs:us-east-1:585415957264:task/intraverse-dev-dcv/8c27b397d1e84f5e92f303f95628d504
}

# Function to enter shell
enter_shell() {
    echo "Entering shell..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "/bin/bash"
}

# Function to list DCV sessions
list_dcv_sessions() {
    echo "Listing DCV sessions..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "/usr/bin/dcv list-sessions"
}

# Function to create a DCV session
create_dcv_session() {
    echo "Creating DCV session..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command '/usr/bin/dcv create-session --type=virtual --storage-root=%home% --owner "user" --user "user" "usersession"'
}

# Function to stop a DCV session
close_dcv_session() {
    echo "Stopping DCV session..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "/usr/bin/dcv close-session usersession"
}

# Function to restart DCV
restart_dcv() {
    echo "Restarting DCV..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "/usr/bin/systemctl restart dcvserver"
}

# Function to check the status of DCV
dcv_status() {
    echo "Checking the status of DCV..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "/usr/bin/systemctl status dcvserver"
}

# Function to run nvidia-smi
run_nvidia_smi() {
    echo "Running nvidia-smi..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "nvidia-smi"
}

# Function to run the game
run_game() {
    echo "Running the game..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "/usr/local/bin/run_game.sh"
}

# Function to kill the game
kill_game() {
    echo "Killing the game..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "pkill -9 -f IntraverseClient.x86_64"
}

launch_app() {
    echo "Launching app..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command '/usr/bin/dcv create-session --init /usr/local/bin/calc_test.sh --type=virtual --storage-root=%home% --owner "user" --user "user" "usersession"'
}

# Function to run a command
run_cmd() {
    echo "Running command..."
    get_task_arn
    aws ecs execute-command \
        --cluster $CLUSTER_NAME \
        --task $TASK_ARN \
        --container $CONTAINER_NAME \
        --interactive \
        --command "$2"
}

# Main script logic
case "$1" in
    enter-shell)
        enter_shell
        ;;
    run-cmd)
        run_cmd
        ;;
    list-sessions)
        list_dcv_sessions
        ;;
    create-session)
        create_dcv_session
        ;;
    close-session)
        close_dcv_session
        ;;
    restart-dcv)
        restart_dcv
        ;;
    dcv-status)
        dcv_status
        ;;
    nvidia-smi)
        run_nvidia_smi
        ;;
    run-game)
        run_game
        ;;
    kill-game)
        kill_game
        ;;
    launch-app)
        launch_app
        ;;
    help|*)
        show_help
        ;;
esac
