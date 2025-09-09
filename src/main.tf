locals {
  fifo_ext                = ".fifo"
  is_fifo                 = var.queue.type == "fifo"
  is_multi_region         = false
  name                    = var.md_metadata.name_prefix
  dlq_name                = "${var.md_metadata.name_prefix}-dlq"
  dlq_name_with_extension = local.is_fifo ? "${local.dlq_name}${local.fifo_ext}" : local.dlq_name
  name_with_extension     = local.is_fifo ? "${local.name}${local.fifo_ext}" : local.name
  kms_key_id              = local.is_multi_region ? module.kms_key[0].key_arn : null
}

resource "aws_sqs_queue" "main" {
  name                        = local.name_with_extension
  fifo_queue                  = local.is_fifo
  sqs_managed_sse_enabled     = local.is_multi_region ? null : true
  content_based_deduplication = false
  visibility_timeout_seconds  = var.queue.visibility_timeout_seconds
  message_retention_seconds   = var.queue.message_retention_seconds
  max_message_size            = var.queue.max_message_size
  kms_master_key_id           = local.kms_key_id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

}

resource "aws_sqs_queue" "dlq" {
  name                        = local.dlq_name_with_extension
  fifo_queue                  = local.is_fifo
  sqs_managed_sse_enabled     = local.is_multi_region ? null : true
  content_based_deduplication = false
  visibility_timeout_seconds  = var.queue.visibility_timeout_seconds
  kms_master_key_id           = local.kms_key_id
  # Set to max time to allow for processing
  message_retention_seconds = 1209600

  # Set to max size in case message is rejected on primary queue for size
  max_message_size = 262144
}
