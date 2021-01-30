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
