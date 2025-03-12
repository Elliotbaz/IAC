#!/bin/bash

exec 2>"/var/log/send-notification.log"

if [ "$AWS" == "1" ]; then
    export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
    export AWS_DEFAULT_REGION=${AWS_REGION}
    set -x
    _msg_already_sent="/var/run/dcv_msg_sent"
    _ip_address="$(curl -s http://checkip.amazonaws.com)"
    _region="$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)"
    _subject="DCV Session is ready."
    _message="
    Dear User,
    your DCV session is ready.
    Please connect to https://${_ip_address}:8443
    and login with your credentials.
    Thanks,
    Best Regards.
    "
else
    :
fi

# wait until DCV session is started
while true; do
    ps -ef | grep Xdcv | grep xauth 2>&1 >/dev/null && break
    sleep 2
done

if [ "$AWS" == "1" ]; then
    _topic_arn="$(/usr/local/bin/aws secretsmanager get-secret-value \
                              --secret-id dcv-session-ready-notifycation \
                              --query SecretString --output text 2>/dev/null)"
    if [ -n "${_topic_arn}" ]; then
        # publish the notification
        if [ ! -r "${_msg_already_sent}" ]; then
            /usr/local/bin/aws sns publish --message "${_message}" \
                          --subject "DCV Session is ready!" \
                          --topic-arn "${_topic_arn}" \
                          --region "${_region}" && touch "${_msg_already_sent}"
        fi
    fi
else
    echo "Message can be sent here ..."
fi
