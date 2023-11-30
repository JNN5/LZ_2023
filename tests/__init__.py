import os
import sys


sys.path.append(os.path.join(os.path.dirname(__file__), "../lambdas"))
sys.path.append(os.path.join(os.path.dirname(__file__), "../lambdas/shared"))


os.environ["POWERTOOLS_SERVICE_NAME"] = "Test-Service"
os.environ["POWERTOOLS_METRICS_NAMESPACE"] = "Test-Metric-Namespace"