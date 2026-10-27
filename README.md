<div align="center">

# 🏥 HIPAA / HITRUST-Compliant Healthcare Cloud Infrastructure
### Enterprise Zero-Trust Data Architecture for Protected Health Information (PHI)

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](#)
[![Compliance HIPAA](https://img.shields.io/badge/Compliance-HIPAA_Security_Rule-red?style=for-the-badge&logo=mediamarkt&logoColor=white)](#)
[![Compliance HITRUST](https://img.shields.io/badge/Compliance-HITRUST_CSF-orange?style=for-the-badge)](#)
[![Azure Database](https://img.shields.io/badge/Azure-PostgreSQL_Flexible_Server-0078D4?style=for-the-badge&logo=postgresql&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](#)

<p align="center">
  <b>Hardened, regulatory-compliant healthcare cloud foundation on Microsoft Azure designed for Electronic Health Record (EHR) systems, medical imaging pipelines, and secure PHI analytics.</b>
</p>

</div>

---

## 📌 Compliance Architecture Diagram

```mermaid
flowchart TD
    subgraph IdentityCompliance ["🛡️ Compliance & Governance Boundary"]
        RBAC["Entra ID RBAC\n(PIM / JIT Access)"]
        HSM["🔐 Azure Key Vault HSM\n(Purge Protection & 90d Soft-Delete)"]
        AuditLaw["📋 HIPAA Audit Logs\n(730-Day Retention WORM)"]
    end

    subgraph HealthcareVNet ["🏥 Healthcare Isolated VNet (10.210.0.0/16)"]
        subgraph AppSubnet ["💻 App Service Tier (10.210.1.0/24)"]
            App["Microservices / FHIR API\n(VNet Integrated)"]
        end

        subgraph DbSubnet ["🗄️ Delegated Database Subnet (10.210.2.0/24)"]
            PSQLPrimary["🐘 Azure PostgreSQL Flexible Server\nPrimary Zone 1 (CMK Encryption)"]
            PSQLStandby["🐘 Zone-Redundant Standby\nStandby Zone 2 (RTO < 60s)"]
        end

        subgraph PrivateLinkSubnet ["🔗 Private Endpoint Subnet (10.210.3.0/24)"]
            StoragePrivateLink["Storage Private Link Endpoint"]
        end
    end

    subgraph StorageTier ["📦 Medical Audit & PHI Storage"]
        ImmutableStorage["Immutable Blob Storage (GRS)\n(WORM Policy & Versioning)"]
    end

    App -->|Zero Public IP / TLS 1.3| PSQLPrimary
    PSQLPrimary <==>|Synchronous Replication| PSQLStandby
    App --> StoragePrivateLink --> ImmutableStorage
    HSM -->|Customer Managed Keys (CMK)| PSQLPrimary
    HSM -->|Customer Managed Keys (CMK)| ImmutableStorage
    HealthcareVNet -.->|All Audit Logs Streamed| AuditLaw
```

---

## 🔒 Rigorous Healthcare Compliance Controls

- 🩺 **HIPAA Security Rule & HITECH Adherence:** Complete encryption in transit (TLS 1.3 mandatory) and encryption at rest with 4096-bit Customer-Managed Keys (CMK) stored in Azure Key Vault HSM.
- 🗄️ **Zero-Public-IP Database Exposure:** PostgreSQL Flexible Server is deployed inside a dedicated, delegated subnet with Private DNS Zone resolution.
- 📜 **Immutable WORM Audit Retention:** Audit trails and diagnostic events are committed to WORM (Write Once, Read Many) storage with a mandatory 730-day (2-year) retention schedule.
- 🔄 **Zone-Redundant High Availability:** Automatic zone-redundant failover between Availability Zone 1 and Availability Zone 2 with zero data loss (RPO = 0, RTO < 60s).
- 🛡️ **Shift-Left Compliance Auditing:** Automated Checkov scans enforce CIS Azure Benchmarks and HIPAA controls on every pull request.

---

## 📂 Directory Tree

```tree
healthcare-platform-infra/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml      # CI workflow with HIPAA compliance scanning
├── .gitignore                    # Local state and credentials filter
├── main.tf                       # PostgreSQL, Key Vault HSM, Storage & Networking
├── variables.tf                  # Infrastructure parameters and sizing
├── outputs.tf                    # FQDNs, vault URIs, and resource IDs
├── versions.tf                   # Provider definitions & remote state
├── terraform.tfvars.example      # Production configuration template
└── README.md                     # Compliance & architecture guide
```

---

## 🚀 Quickstart Deployment

```bash
# 1. Initialize Terraform
terraform init

# 2. Inspect plan for security & compliance checks
terraform plan -out=healthcare.tfplan

# 3. Apply infrastructure
terraform apply healthcare.tfplan
```

---

## 📄 License
Released under the [MIT License](LICENSE).
