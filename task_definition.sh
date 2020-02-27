#!/bin/bash


export get_current_task_id=$(aws ecs list-tasks --cluster $cluster_name --desired-status RUNNING --family $task_family | jq -r ".taskArns[0]")

# Create the new revision
export new_task_revision=$(aws ecs register-task-definition --family $task_family --task-role-arn $task_role_arn --network-mode bridge --container-definitions "[{\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"$LOG_GROUP\",\"awslogs-region\":\"$AWS_REGION\"}},\"name\":\"$CONTAINER_NAME\",\"environment\":[{\"name\":\"NODE_ENV\",\"value\":\"$NODE_ENV\"}],\"image\":\"$AWS_ECR_URI/$IMAGE_NAME:$BUILD_NUMBER\",\"memoryReservation\":$SOFT_LIMIT,\"portMappings\":[{\"hostPort\":0,\"protocol\":\"tcp\",\"containerPort\":$CONTAINER_PORT}],\"essential\":true}]" --cpu $TASK_CPU --memory $TASK_MEMORY --tags "[{\"key\":\"ClusterName\",\"value\":\"$cluster_name\"},{\"key\":\"ServiceName\",\"value\":\"$service_name\"}]" | jq --raw-output '.taskDefinition.revision')


#below command stops the running task
aws ecs stop-task --cluster $cluster_name --task $get_current_task_id

# to update the service with new revision
aws ecs update-service --cluster $cluster_name --service $service_name --task-definition $task_family:$new_task_revision --desired-count $DESIRED_COUNT | jq --raw-output '.service.taskDefinition'
