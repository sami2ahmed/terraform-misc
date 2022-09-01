---
# generated by https://github.com/hashicorp/terraform-plugin-docs
page_title: "confluent_identity_pool Data Source - terraform-provider-confluent"
subcategory: ""
description: |-
  
---

# confluent_identity_pool Data Source

[![Limited Availability](https://img.shields.io/badge/Lifecycle%20Stage-Limited%20Availability-%2345c6e8)](https://docs.confluent.io/cloud/current/api.html#section/Versioning/API-Lifecycle-Policy) [![Request Access To OAuth API](https://img.shields.io/badge/-Request%20Access%20To%20OAuth%20API-%23bc8540)](mailto:ccloud-api-access+iam-v2-closed-preview@confluent.io?subject=Request%20to%20join%20OAuth%20API%20Closed%20Preview&body=I%E2%80%99d%20like%20to%20join%20the%20Confluent%20Cloud%20API%20Closed%20Preview%20for%20iam/v2%20to%20provide%20early%20feedback%21%20My%20Cloud%20Organization%20ID%20is%20%3Cretrieve%20from%20https%3A//confluent.cloud/settings/billing/payment%3E.)

`confluent_identity_pool` describes an Identity Pool data source.

## Example Usage

```terraform
data "confluent_identity_pool" "example_using_id" {
  id = "pool-xyz456"
  identity_provider {
    id = "op-abc123"
  }
}

output "example_using_id" {
  value = data.confluent_identity_pool.example_using_id
}

data "confluent_identity_pool" "example_using_name" {
  display_name = "My Identity Pool"
  identity_provider {
    id = "op-abc123"
  }
}

output "example_using_name" {
  value = data.confluent_identity_pool.example_using_name
}
```

<!-- schema generated by tfplugindocs -->
## Argument Reference

The following arguments are supported:

- `id` - (Optional String) The ID of the Identity Pool, for example, `pool-xyz456`.
- `display_name` - (Optional String) A human-readable name for the Identity Pool.
- `identity_provider` (Required Configuration Block) supports the following:
  - `id` - (Required String) The ID of the Identity Provider associated with the Identity Pool, for example, `op-abc123`.

-> **Note:** Exactly one from the `id` and `display_name` attributes must be specified.

## Attributes Reference

In addition to the preceding arguments, the following attributes are exported:

The following attributes are exported:

- `id` - (Required String) The ID of the Identity Pool, for example, `pool-xyz456`.
- `identity_provider` (Required Configuration Block) supports the following:
  - `id` - (Required String) The ID of the Identity Provider associated with the Identity Pool, for example, `op-abc123`.
- `display_name` - (Required String) A human-readable name for the Identity Pool.
- `description` - (Required String) A description for the Identity Pool.
- `identity_claim` - (Required String) The JSON Web Token (JWT) claim to extract the authenticating identity to Confluent resources from (see [Registered Claim Names](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1) for more details). This appears in the audit log records, showing, for example, that "identity Z used identity pool X to access topic A".
- `filter` - (Required String) A filter expression in [Supported Common Expression Language (CEL)](https://docs.confluent.io/cloud/current/access-management/authenticate/oauth/identity-pools.html#supported-common-expression-language-cel-filters) that specifies which identities can authenticate using your identity pool (see [Set identity pool filters](https://docs.confluent.io/cloud/current/access-management/authenticate/oauth/identity-pools.html#set-identity-pool-filters) for more details).