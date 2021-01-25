STATE_BUCKET_NAME := terraform-skeleton-state
STATE_LOG_BUCKET_NAME := terraform-skeleton-state-logs
LOCK_TABLE_NAME := terraform-skeleton-state-locks
# Use a known profile to ensure account ID is correct
ADMIN_ACCOUNT_ID := $(shell aws --profile tf-admin-account sts get-caller-identity | jq -r .Account)

.PHONY: init-admin
init-admin:
	aws cloudformation deploy \
		--template-file init/admin/init-admin-account.cf.yml \
		--stack-name tf-admin-init \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			AdminAccountId=${ADMIN_ACCOUNT_ID} \
			StateBucketName=${STATE_BUCKET_NAME} \
			StateLogBucketName=${STATE_LOG_BUCKET_NAME} \
			LockTableName=${LOCK_TABLE_NAME}
