from dataclasses import dataclass, field


@dataclass
class DynamoDbTemplate:
    name: str
    hash_key: str = "id"
    range_key: str = ""
    attributes: list = field(default_factory=list) 
    index: list = field(default_factory=list) 
    ttl_enabled: bool = False
    stream_enabled: bool = False
    pit_recovery_enabled: bool = False
    kms_key: str = "lz-ddb-key"

    def to_json(self):
        return {
            "name": self.name,
            "hash_key": self.hash_key,
            "range_key": self.range_key,
            "attributes": [{"name":"id","type":"S"}] if self.attributes == [] else self.attributes,
            "index": self.index,
            "ttl_enabled": self.ttl_enabled,
            "stream_enabled": self.stream_enabled,
            "pit_recovery_enabled": self.pit_recovery_enabled,
            "kms_key": self.kms_key,
        }