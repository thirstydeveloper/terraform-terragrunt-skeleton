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

.PHONY: check-init-admin-drift
check-init-admin-drift:
	$(eval DRIFT_ID=$(shell aws cloudformation detect-stack-drift \
		--stack-name ${ADMIN_INIT_STACK_NAME} | jq -r .StackDriftDetectionId \
	))
	$(eval POLL_COMMAND= \
		aws cloudformation describe-stack-drift-detection-status \
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

import-terragrunt-changeset.json:
	@aws cloudformation create-change-set \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
		--change-set-name ${ADMIN_INIT_STACK_NAME}-import-terragrunt \
		--change-set-type IMPORT \
		--template-body file://init/admin/init-admin-account.cf.yml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			ParameterKey=AdminAccountId,UsePreviousValue=True \
			ParameterKey=StateBucketName,UsePreviousValue=True \
			ParameterKey=StateLogBucketName,UsePreviousValue=True \
			ParameterKey=LockTableName,UsePreviousValue=True \
		--resources-to-import "[ \
			{ \
				\"ResourceType\":\"AWS::S3::Bucket\", \
				\"LogicalResourceId\":\"TerraformStateBucket\", \
				\"ResourceIdentifier\": { \
					\"BucketName\": \"${STATE_BUCKET_NAME}\" \
				} \
			}, \
			{ \
				\"ResourceType\":\"AWS::S3::Bucket\", \
				\"LogicalResourceId\":\"TerraformStateLogBucket\", \
				\"ResourceIdentifier\": { \
					\"BucketName\": \"${STATE_LOG_BUCKET_NAME}\" \
				} \
			}, \
			{ \
			\"ResourceType\":\"AWS::DynamoDB::Table\", \
				\"LogicalResourceId\":\"TerraformStateLockTable\", \
				\"ResourceIdentifier\": { \
					\"TableName\": \"${LOCK_TABLE_NAME}\" \
				} \
			} \
		]" | tee import-terragrunt-changeset.json

.PHONY: prepare-import-terragrunt
prepare-import-terragrunt: import-terragrunt-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .Id import-terragrunt-changeset.json))
	aws cloudformation wait change-set-create-complete \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	@aws cloudformation describe-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
		| jq '{ Changes, Status, StatusReason }'

.PHONY: execute-import-terragrunt
execute-import-terragrunt: import-terragrunt-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .Id import-terragrunt-changeset.json))
	aws cloudformation execute-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	@rm import-terragrunt-changeset.json
	aws cloudformation wait stack-import-complete \
		--stack-name ${ADMIN_INIT_STACK_NAME}

.PHONY: discard-import-terragrunt
discard-import-terragrunt: import-terragrunt-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .Id import-terragrunt-changeset.json))
	aws cloudformation delete-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	rm import-terragrunt-changeset.json

.PHONY: import-terragrunt
import-terragrunt: execute-import-terragrunt
	$(eval CHANGE_SET_ID=$(shell jq -r .Id import-terragrunt-changeset.json))
	aws cloudformation execute-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	@rm import-terragrunt-changeset.json
	aws cloudformation wait stack-import-complete \
		--stack-name ${ADMIN_INIT_STACK_NAME}

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
	rm import-terragrunt-changeset.json
