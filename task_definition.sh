#!/bin/sh

export get_current_task_id=$(~/.local/bin/aws ecs list-tasks --cluster $cluster_name --desired-status RUNNING --family $task_family | jq -r ".taskArns[0]")

# Create the new revision
export new_task_revision=$(~/.local/bin/aws ecs register-task-definition --family $task_family --task-role-arn $task_role_arn --network-mode bridge --container-definitions "[{\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"$log_group\",\"awslogs-region\":\"$aws_region\"}},\"name\":\"$container_name\",\"image\":\"$aws_ecr_uri/$image_name:$BUILD_NUMBER\",\"memoryReservation\":$soft_limit,\"portMappings\":[{\"hostPort\":0,\"protocol\":\"tcp\",\"containerPort\":$container_port}],\"essential\":true}]" --cpu $task_cpu --memory $task_memory --tags "[{\"key\":\"ClusterName\",\"value\":\"$cluster_name\"},{\"key\":\"ServiceName\",\"value\":\"$service_name\"}]" | jq --raw-output '.taskDefinition.revision')


#below command stops the running task
~/.local/bin/aws ecs stop-task --cluster $cluster_name --task $get_current_task_id

# to update the service with new revision
~/.local/bin/aws ecs update-service --cluster $cluster_name --service $service_name --task-definition $task_family:$new_task_revision --desired-count $desired_count | jq --raw-output '.service.taskDefinition'
