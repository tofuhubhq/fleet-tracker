# 🚚 Fleet Tracker

Fleet Tracker is a Supabase-powered platform designed to manage and monitor fleets of vehicles. It provides a structured database schema to represent organizations, units, and the vehicles they operate.

## 📦 Tech Stack

- **Supabase** (PostgreSQL + Auth + Storage)
- **OpenTofu/Terraform** for infrastructure provisioning
- **Supabase CLI** for migrations and deployment
- **PostgreSQL** as the core data layer

---

## 🗂️ Database Schema Overview

### Tables:

#### `organizations`
Stores top-level entities representing companies or clients that own fleets.

#### `organization_units`
Subdivisions under each organization (e.g., departments, branches, or regional units).

#### `makers`
Vehicle manufacturers or brands.

#### `profiles`
User profiles associated with the platform. Likely tied to Supabase Auth users.

#### `vehicles`
Records of vehicles in the fleet.

| Column              | Type         | Description                          |
|---------------------|--------------|--------------------------------------|
| `id`                | `int8`       | Primary key                          |
| `created_at`        | `timestamptz`| Timestamp when the record was added |
| `plate_number`      | `text`       | Vehicle's license plate              |
| `maker_id`          | `int8`       | Foreign key to `makers`             |
| `organization_unit_id` | `int8`    | Foreign key to `organization_units` |

---

## 🚀 Quick Start

### 1. Deploy with Terraform

```bash
# Set required variables
export TF_VAR_supabase_token=your_token
export TF_VAR_supabase_org_id=your_org_id
export TF_VAR_supabase_region=your_region
export TF_VAR_supabase_db_password=your_password

# Deploy
tofu init
tofu apply
