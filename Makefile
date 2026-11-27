ADMIN_INIT_STACK_NAME := tf-admin-init
STATE_BUCKET_NAME := terraform-skeleton-state
STATE_LOG_BUCKET_NAME := terraform-skeleton-state-logs
STATE_AUDIT_LOG_BUCKET_NAME := terraform-skeleton-state-audit-logs

# Use a known profile to ensure account ID is correct
ADMIN_ACCOUNT_ID := $(shell \
	aws --profile tf-admin-account sts get-caller-identity | jq -r .Account \
)

BACKEND_ROLE_PATH := terraform/TerraformBackend
BACKEND_ROLE_ARN := arn:aws:iam::${ADMIN_ACCOUNT_ID}:role/${BACKEND_ROLE_PATH}

UNIT_DIRS := $(shell find live -name terragrunt.hcl \
	-not -path */.terragrunt-cache/* -exec dirname {} \; \
)

MODULE_DIRS := $(shell find modules -name '*.tf' -not -path '*/.terraform/*' \
	-exec dirname {} \; | sort -u \
)

VENV := .venv
PYTEST := $(VENV)/bin/pytest

CFN := aws cloudformation
CFN_START_DRIFT_DETECTION := $(CFN) detect-stack-drift --stack-name
CFN_STATUS_DRIFT_DETECTION := $(CFN) describe-stack-drift-detection-status \
	--stack-drift-detection-id

define wait_cfn_drift_detect_job
	@while [[ \
		"$$($(CFN_STATUS_DRIFT_DETECTION) $(1) | jq -r .DetectionStatus)" == \
		"DETECTION_IN_PROGRESS" \
	]]; do \
		echo "Detection in progress. Waiting 3 seconds..."; \
		sleep 3; \
	done
endef

define show_cfn_drift
	$(eval DRIFT_ID=$(shell $(CFN_START_DRIFT_DETECTION) $(1) \
		| jq -r .StackDriftDetectionId))
	$(call wait_cfn_drift_detect_job,${DRIFT_ID})
	@$(CFN_STATUS_DRIFT_DETECTION) $(DRIFT_ID) | jq '{ \
		DetectionStatus, \
		StackDriftStatus, \
		DriftedStackResourceCount \
	}'
endef

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
			StateAuditLogBucketName=${STATE_AUDIT_LOG_BUCKET_NAME}
	aws cloudformation update-termination-protection \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
		--enable-termination-protection

.PHONY: check-init-admin-drift
check-init-admin-drift:
	$(call show_cfn_drift,${ADMIN_INIT_STACK_NAME})

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
			} \
		]" | tee import-terragrunt-changeset.json

.PHONY: prepare-cfn-import-terragrunt
prepare-cfn-import-terragrunt: import-terragrunt-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .Id import-terragrunt-changeset.json))
	aws cloudformation wait change-set-create-complete \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	@aws cloudformation describe-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME} \
		| jq '{ Changes, Status, StatusReason }'

.PHONY: discard-cfn-import-terragrunt
discard-cfn-import-terragrunt: import-terragrunt-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .Id import-terragrunt-changeset.json))
	aws cloudformation delete-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	@rm import-terragrunt-changeset.json

.PHONY: cfn-import-terragrunt
cfn-import-terragrunt: import-terragrunt-changeset.json
	$(eval CHANGE_SET_ID=$(shell jq -r .Id import-terragrunt-changeset.json))
	aws cloudformation wait change-set-create-complete \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	aws cloudformation execute-change-set \
		--change-set-name ${CHANGE_SET_ID} \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	@rm import-terragrunt-changeset.json
	aws cloudformation wait stack-import-complete \
		--stack-name ${ADMIN_INIT_STACK_NAME}
	$(call show_cfn_drift,${ADMIN_INIT_STACK_NAME})

.PHONY: test-backend-assume
test-backend-assume:
	aws sts assume-role \
		--role-arn ${BACKEND_ROLE_ARN} \
		--role-session-name $(shell whoami)

.PHONY: init-all
init-all:
	for d in ${UNIT_DIRS}; do \
		pushd $$d; \
		terragrunt init; \
		popd; \
	done

.PHONY: test
test: test-modules test-config

# Unit tests for terraform modules (terraform test). No AWS credentials needed.
.PHONY: test-modules
test-modules:
	@set -e; for d in ${MODULE_DIRS}; do \
		echo "=== $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$d test; \
		rm -f $$d/.terraform.lock.hcl; \
	done

# Tests for the terragrunt config layer (terragrunt render + pytest).
# Needs AWS credentials for get_aws_account_id(); skipped otherwise.
.PHONY: test-config
test-config: $(PYTEST)
	$(PYTEST) tests

$(PYTEST): tests/requirements.txt
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install -q -r tests/requirements.txt
	@touch $(PYTEST)

.PHONY: clean
clean:
	rm import-terragrunt-changeset.json
