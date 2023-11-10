import aws_cdk as core
import aws_cdk.assertions as assertions

from lz_2023.lz_2023_stack import Lz2023Stack

# example tests. To run these tests, uncomment this file along with the example
# resource in lz_2023/lz_2023_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = Lz2023Stack(app, "lz-2023")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
