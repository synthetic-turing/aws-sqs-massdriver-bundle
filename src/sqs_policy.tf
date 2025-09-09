data "aws_iam_policy_document" "sqs_sns_policy" {
  statement {
    sid    = "AllowSNSMessageDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "sqs:SendMessage"
    ]
    resources = [aws_sqs_queue.main.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["*"] # This will be restricted by the SNS subscription
    }
  }
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id
  policy    = data.aws_iam_policy_document.sqs_sns_policy.json
}
