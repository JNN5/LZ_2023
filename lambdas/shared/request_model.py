from typing import Optional
from pynamodb.models import Model
from pynamodb.attributes import UnicodeAttribute, TTLAttribute, MapAttribute, NumberAttribute, ListAttribute


class RequestModel(Model):
    class Meta:
        region = "ap-southeast-1"
        table_name = "lz_servicenow_requests"
        encrypted_fields = None

    ticket_id = UnicodeAttribute(hash_key=True)
    workflow = UnicodeAttribute(range_key=True)
    requester = UnicodeAttribute(null=False)
    requested_for = UnicodeAttribute(null=True)
    requested_at = UnicodeAttribute(null=True)
    app_type = UnicodeAttribute(null=False)
    app_size = UnicodeAttribute(null=False)

    @classmethod
    def setup_model(cls, tablename: Optional[str] = None):
        if tablename is not None:
            cls.Meta.table_name = tablename
        if not cls.exists():
            cls.create_table(wait=True, billing_mode="PAY_PER_REQUEST")
        return cls