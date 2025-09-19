#!/bin/bash

# Dirt App - Supabase Setup Script
# This script helps set up a new Supabase project with our schema

echo "🚀 Setting up Dirt App Supabase project..."

# Install Supabase CLI if not installed
if ! command -v supabase &> /dev/null; then
    echo "Installing Supabase CLI..."
    brew install supabase/tap/supabase
fi

# Initialize Supabase project
if [ ! -f "supabase/config.toml" ]; then
    echo "Initializing Supabase project..."
    supabase init
fi

# Start Supabase services
echo "Starting Supabase services..."
supabase start

# Apply migrations
echo "Applying migrations..."
for migration in migrations/*.sql; do
    echo "Applying migration: $migration"
    supabase db reset --db-url "postgresql://postgres:postgres@localhost:54322/postgres" -f "$migration"
    if [ $? -ne 0 ]; then
        echo "❌ Error applying migration: $migration"
        exit 1
    fi
done

echo "✅ Setup complete!"
echo "Supabase URL: http://localhost:54321"
echo "Studio URL: http://localhost:54323"
echo "Kong URL: http://localhost:8000"

echo "\nNext steps:"
echo "1. Open Supabase Studio at http://localhost:54323"
echo "2. Go to Authentication > Providers and enable email/password and any social logins"
echo "3. Go to Storage > Policies and verify the storage policies"
echo "4. Run 'supabase status' to check the running services"
