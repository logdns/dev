#!/usr/bin/env python3
"""Generate a compact Karing custom diversion import from mydiy.conf.

The source Shadowrocket file contains `.list` Rule Sets, but Karing's custom
Rule Set import accepts only `.srs` or `.json`. This script keeps known Karing
built-in ACLs as `rule_set_build_in`, and expands small custom `.list` files
into ordinary domain/IP rules.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.request
from collections import OrderedDict
from dataclasses import dataclass, field
from pathlib import Path


SOURCE_URL = "https://raw.githubusercontent.com/logdns/dev/master/ios/shadowrocket/mydiy.conf"

BUILTIN_RULESETS = {
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/LocalAreaNetwork.list": [
        ("direct_ip", "acl:LocalAreaNetwork"),
    ],
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/UnBan.list": [
        ("direct_domain", "acl:UnBan"),
    ],
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/BanAD.list": [
        ("block", "acl:BanAD"),
    ],
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/BanProgramAD.list": [
        ("block", "acl:BanProgramAD"),
    ],
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ChinaDomain.list": [
        ("direct_domain", "acl:ChinaDomain"),
    ],
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ChinaMedia.list": [
        ("direct_domain", "acl:ChinaMedia"),
    ],
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ChinaCompanyIp.list": [
        ("direct_ip", "acl:ChinaCompanyIp"),
    ],
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ChinaIp.list": [
        ("direct_ip", "acl:ChinaIp"),
    ],
}

EXPANDED_RULESETS = {
    "https://raw.githubusercontent.com/DuskWander87/shadowrocket-config/main/rules/Reject.list",
    "https://raw.githubusercontent.com/DuskWander87/shadowrocket-config/main/rules/ChinaDirect.list",
}

ACTION_TO_BUCKET = {
    "REJECT": "block",
    "REJECT-DROP": "block",
    "REJECT-NO-DROP": "block",
    "DIRECT": "direct",
    "PROXY": "proxy",
    "Proxy": "proxy",
}

RULE_TO_FIELD = {
    "DOMAIN-SUFFIX": "domain_suffix",
    "DOMAIN": "domain",
    "DOMAIN-KEYWORD": "domain_keyword",
    "IP-CIDR": "ip_cidr",
    "IP-CIDR6": "ip_cidr",
}


@dataclass
class RuleBucket:
    name: str
    outbound: str
    fields: dict[str, OrderedDict[str, None]] = field(
        default_factory=lambda: {
            "rule_set_build_in": OrderedDict(),
            "domain_suffix": OrderedDict(),
            "domain": OrderedDict(),
            "domain_keyword": OrderedDict(),
            "ip_cidr": OrderedDict(),
        }
    )

    def add(self, field_name: str, value: str) -> None:
        value = value.strip()
        if value:
            self.fields[field_name][value] = None

    def to_json(self) -> dict[str, object] | None:
        result: dict[str, object] = {
            "name": self.name,
            "outbound": self.outbound,
            "switch": True,
            "or": True,
        }
        for field_name, values in self.fields.items():
            if values:
                result[field_name] = list(values.keys())
        if len(result) == 4:
            return None
        return result


def fetch_text(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="ignore")


def get_rule_section(text: str) -> list[str]:
    lines: list[str] = []
    in_rule = False
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line == "[Rule]":
            in_rule = True
            continue
        if line.startswith("[") and line.endswith("]"):
            in_rule = False
        if in_rule:
            lines.append(raw_line)
    return lines


def parse_line(line: str) -> list[str]:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return []
    return [part.strip() for part in stripped.split(",")]


def route_value(bucket_key: str, rule_type: str) -> str | None:
    if bucket_key == "block":
        return "block"
    field_name = RULE_TO_FIELD.get(rule_type)
    if bucket_key == "direct" and field_name == "ip_cidr":
        return "direct_ip"
    if bucket_key == "direct":
        return "direct_domain"
    if bucket_key == "proxy" and field_name == "ip_cidr":
        return "proxy_ip"
    if bucket_key == "proxy":
        return "proxy_domain"
    return None


def add_rule(
    buckets: dict[str, RuleBucket],
    rule_type: str,
    value: str,
    action: str,
    unsupported: list[str],
) -> None:
    bucket_key = ACTION_TO_BUCKET.get(action)
    if bucket_key is None:
        unsupported.append(f"unsupported action: {rule_type},{value},{action}")
        return

    if rule_type == "GEOIP":
        target = "direct_ip" if bucket_key == "direct" else "proxy_ip"
        buckets[target].add("rule_set_build_in", f"geoip:{value.lower()}")
        return

    field_name = RULE_TO_FIELD.get(rule_type)
    if field_name is None:
        unsupported.append(f"unsupported rule type: {rule_type},{value},{action}")
        return

    target = route_value(bucket_key, rule_type)
    if target is None:
        unsupported.append(f"unsupported route: {rule_type},{value},{action}")
        return
    buckets[target].add(field_name, value)


def parse_ruleset(
    buckets: dict[str, RuleBucket],
    url: str,
    action: str,
    unsupported: list[str],
) -> None:
    if url in BUILTIN_RULESETS:
        for bucket_name, builtin_name in BUILTIN_RULESETS[url]:
            buckets[bucket_name].add("rule_set_build_in", builtin_name)
        return

    if url not in EXPANDED_RULESETS:
        unsupported.append(f"skipped non-Karing ruleset URL: {url}")
        return

    for line in fetch_text(url).splitlines():
        parts = parse_line(line)
        if not parts:
            continue
        if len(parts) < 2:
            unsupported.append(f"invalid expanded ruleset line: {url}: {line}")
            continue
        add_rule(buckets, parts[0], parts[1], action, unsupported)


def build_payload(source_text: str) -> tuple[dict[str, object], list[str]]:
    buckets = {
        "block": RuleBucket("🚫 DIY-广告拦截", "block"),
        "direct_domain": RuleBucket("🎯 DIY-域名直连", "direct"),
        "direct_ip": RuleBucket("🧭 DIY-IP直连", "direct"),
        "proxy_domain": RuleBucket("🌍 DIY-域名代理", "currentSelected"),
        "proxy_ip": RuleBucket("🌐 DIY-IP代理", "currentSelected"),
    }
    unsupported: list[str] = []

    for line in get_rule_section(source_text):
        parts = parse_line(line)
        if not parts:
            continue
        rule_type = parts[0]
        if rule_type == "RULE-SET":
            if len(parts) < 3:
                unsupported.append(f"invalid RULE-SET line: {line}")
                continue
            parse_ruleset(buckets, parts[1], parts[2], unsupported)
            continue
        if rule_type == "FINAL":
            unsupported.append("FINAL,PROXY is not imported; set Karing final manually to current selected")
            continue
        if rule_type == "USER-AGENT":
            unsupported.append("USER-AGENT is not supported by Karing custom diversion import")
            continue
        if len(parts) < 3:
            unsupported.append(f"invalid rule line: {line}")
            continue
        add_rule(buckets, rule_type, parts[1], parts[2], unsupported)

    ordered_keys = ["block", "direct_domain", "direct_ip", "proxy_domain", "proxy_ip"]
    rules = [buckets[key].to_json() for key in ordered_keys]
    return {"rules": [rule for rule in rules if rule is not None]}, unsupported


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Karing custom diversion JSON for mydiy.")
    parser.add_argument("--source", default=SOURCE_URL, help="Shadowrocket mydiy.conf URL or local path")
    parser.add_argument("--output", default="mydiy-karing-diversion.json", help="Output JSON path")
    parser.add_argument("--unsupported", default="mydiy-karing-unsupported.txt", help="Unsupported-rule report path")
    args = parser.parse_args()

    source_path = Path(args.source)
    if source_path.exists():
        source_text = source_path.read_text(encoding="utf-8", errors="ignore")
    else:
        source_text = fetch_text(args.source)

    payload, unsupported = build_payload(source_text)
    Path(args.output).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    Path(args.unsupported).write_text("\n".join(unsupported) + "\n", encoding="utf-8")

    counts = []
    for rule in payload["rules"]:
        item_count = sum(len(value) for value in rule.values() if isinstance(value, list))
        counts.append(f"{rule['name']}: {item_count}")
    print("Generated", args.output)
    print("Rules:", len(payload["rules"]))
    print("Items:", "; ".join(counts))
    print("Unsupported notes:", len(unsupported), f"({args.unsupported})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
