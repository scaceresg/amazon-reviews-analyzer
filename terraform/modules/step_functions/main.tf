# Skeleton: orchestration with Step Functions + EventBridge Scheduler.
# Resources to define:
#   - aws_sfn_state_machine.pipeline   (ingestion -> silver -> bedrock batch -> gold -> refresh)
#   - aws_scheduler_schedule.pipeline  (EventBridge Scheduler; scheduled or on-demand trigger)
