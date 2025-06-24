terraform {
  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.5"
    }
  }
}

provider "supabase" {
  access_token = var.supabase_token
}

variable "supabase_token" {
  type = string
  description = "Supabase personal access token"
}

variable "supabase_org_id" {
  type = string
  description = "Supabase organization ID"
}

variable "supabase_project_name" {
  type    = string
  default = "my-project"
}

variable "supabase_region" {
  type    = string
  default = ""
}

variable "supabase_db_password" {
  type    = string
  default = "somedefaultpassword"
}

resource "supabase_project" "example" {
  organization_id   = var.supabase_org_id
  name              = var.supabase_project_name
  region            = var.supabase_region
  database_password = var.supabase_db_password
}

output "project_id" {
  value = supabase_project.example.id
}

resource "supabase_settings" "example" {
  project_ref = supabase_project.example.id
  api = jsonencode({
    db_schema = "public,storage,graphql_public"
  })
}

resource "null_resource" "wait_for_project_ready" {
  depends_on = [supabase_project.example]

  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Waiting for Supabase project to become ACTIVE..."

      for i in {1..30}; do
        STATUS=$(curl -s -H "Authorization: Bearer ${var.supabase_token}" \
          https://api.supabase.io/v1/projects/${supabase_project.example.id} \
          | jq -r '.status')

        echo "   ➤ Current status: $STATUS"

        if [ "$STATUS" = "ACTIVE_HEALTHY" ]; then
          echo "✅ Supabase project is ready."
          exit 0
        fi

        sleep 10
      done

      echo "❌ Timed out waiting for Supabase project to be ready."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "wait_for_postgres_ready" {
  depends_on = [null_resource.wait_for_project_ready]

  provisioner "local-exec" {
    environment = {
      PGPASSWORD = var.supabase_db_password
      SUPABASE_HOST = "aws-0-${var.supabase_region}.pooler.supabase.com"
    }

    command = <<EOT
      echo "⏳ Waiting for Postgres database (via Shared Pooler) to accept connections..."

      for i in {1..30}; do
        pg_isready -h "$SUPABASE_HOST" \
                   -p 5432 \
                   -U postgres \
                   -d postgres

        if [ $? -eq 0 ]; then
          echo "✅ Postgres is ready!"
          exit 0
        fi

        sleep 5
      done

      echo "❌ Timed out waiting for Postgres to be ready."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}


resource "null_resource" "run_migrations" {
  depends_on = [null_resource.wait_for_postgres_ready]

  provisioner "local-exec" {
    environment = {
      SUPABASE_ACCESS_TOKEN = var.supabase_token
      SUPABASE_DB_PASSWORD  = var.supabase_db_password
      SUPABASE_DB_HOST      = "aws-0-${var.supabase_region}.pooler.supabase.com"
      SUPABASE_DB_USER      = "postgres.${supabase_project.example.id}"
    }

    command = <<-EOF
      echo "📦 Running migrations for Supabase project: ${supabase_project.example.id}"

      DB_URL="postgres://$SUPABASE_DB_USER:$SUPABASE_DB_PASSWORD@$SUPABASE_DB_HOST:5432/postgres"

      npx supabase db push --db-url "$DB_URL"

      echo "✅ Migrations applied successfully."
    EOF

    interpreter = ["/bin/bash", "-c"]
  }
}




