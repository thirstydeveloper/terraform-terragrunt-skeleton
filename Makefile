ADMIN_INIT_STACK_NAME := tf-admin-init
STATE_BUCKET_NAME := terraform-skeleton-state
STATE_LOG_BUCKET_NAME := terraform-skeleton-state-logs
LOCK_TABLE_NAME := terraform-skeleton-state-locks

# Use a known profile to ensure account ID is correct
ADMIN_ACCOUNT_ID := $(shell \
	aws --profile tf-admin-account sts get-caller-identity | jq -r .Account \
)

BACKEND_ROLE_PATH := terraform/TerraformBackend
BACKEND_ROLE_ARN := arn:aws:iam::${ADMIN_ACCOUNT_ID}:role/${BACKEND_ROLE_PATH}

DEPLOYMENT_DIRS := $(shell find deployments -name terragrunt.hcl \
	-not -path */.terragrunt-cache/* -exec dirname {} \; \
)

.PHONY: init-admin
init-admin:
	aws cloudformation deploy \
		--template-file init/admin/init-admin-account.cf.yml \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			AdminAccountId=${ADMIN_ACCOUNT_ID} \
			StateBucketName=${STATE_BUCKET_NAME} \
			StateLogBucketName=${STATE_LOG_BUCKET_NAME} \
			LockTableName=${LOCK_TABLE_NAME}
	aws cloudformation update-termination-protection \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
		--enable-termination-protection

DESCRIBE_DRIFT_DETECT_JOB := \
	aws cloudformation describe-stack-drift-detection-status

.PHONY: check-init-admin-drift
check-init-admin-drift:
	$(eval DRIFT_ID=$(shell aws cloudformation detect-stack-drift \
		--stack-name ${ADMIN_INIT_STACK_NAME} | jq -r .StackDriftDetectionId \
	))
	$(eval POLL_COMMAND=${DESCRIBE_DRIFT_DETECT_JOB} \
		--stack-drift-detection-id ${DRIFT_ID} \
	)
	@while [[ \
		"$$(${POLL_COMMAND} | jq -r .DetectionStatus)" == "DETECTION_IN_PROGRESS" \
	]]; do \
		echo "Detection in progress. Waiting 3 seconds..."; \
		sleep 3; \
	done
	@${POLL_COMMAND} | jq '{ \
		DetectionStatus, \
		StackDriftStatus, \
		DriftedStackResourceCount \
	}'

IMPORT_STATE_BUCKET_CHANGESET_NAME := ${ADMIN_INIT_STACK_NAME}-import-state-bucket

import-state-bucket-changeset.json:
	@aws cloudformation create-change-set \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
		--change-set-name ${IMPORT_STATE_BUCKET_CHANGESET_NAME} \
		--change-set-type IMPORT \
		--template-body file://init/admin/init-admin-account.cf.yml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			ParameterKey=AdminAccountId,UsePreviousValue=True \
			ParameterKey=StateBucketName,UsePreviousValue=True \
			ParameterKey=StateLogBucketName,UsePreviousValue=True \
			ParameterKey=LockTableName,UsePreviousValue=True \
		--resources-to-import "[{ \
			\"ResourceType\":\"AWS::S3::Bucket\", \
			\"LogicalResourceId\":\"TerraformStateBucket\", \
			\"ResourceIdentifier\": { \
				\"BucketName\": \"${STATE_BUCKET_NAME}\" \
			} \
		}]"
	@jq -n "{ ChangeSetId: \"${IMPORT_STATE_BUCKET_CHANGESET_NAME}\" }" > import-state-bucket-changeset.json

DESCRIBE_CHANGE_SET := aws cloudformation describe-change-set

.PHONY: describe-import-state-bucket
describe-import-state-bucket: import-state-bucket-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r \
		.ChangeSetId \
		import-state-bucket-changeset.json \
  ))
	$(eval DESCRIBE_COMMAND=${DESCRIBE_CHANGE_SET} \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
	)
	@while [[ \
			"$$(${DESCRIBE_COMMAND} | jq -r .Status)" == "CREATE_IN_PROGRESS" \
	]]; do \
		echo "Change set creating. Waiting 3 seconds..."; \
		sleep 3; \
	done
	@${DESCRIBE_COMMAND} | jq '{ Changes, Status, StatusReason }'

.PHONY: discard-import-state-bucket
discard-import-state-bucket: import-state-bucket-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .ChangeSetId import-state-bucket-changeset.json))
	aws cloudformation delete-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	rm import-state-bucket-changeset.json

.PHONY: import-state-bucket
import-state-bucket: import-state-bucket-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .ChangeSetId import-state-bucket-changeset.json))
	aws cloudformation execute-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	@rm import-state-bucket-changeset.json

.PHONY: test-backend-assume
test-backend-assume:
	aws sts assume-role \
		--role-arn ${BACKEND_ROLE_ARN} \
		--role-session-name $(shell whoami)

.PHONY: init-all
init-all:
	for d in ${DEPLOYMENT_DIRS}; do \
		pushd $$d; \
		terragrunt init; \
		popd; \
	done

.PHONY: clean
clean:
	rm import-state-bucket-changeset.json
