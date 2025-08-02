# Dirt App - Backend

This directory contains the backend implementation for the Dirt app, built with Supabase.

## 🏗️ Project Structure

```
Backend/
├── migrations/           # Database migrations
│   ├── 20240802000000_initial_schema.sql
│   └── 20240802000001_rls_policies.sql
├── setup_supabase.sh    # Local development setup script
└── README.md           # This file
```

## 🚀 Getting Started

### Prerequisites

- Docker (for local Supabase)
- Supabase CLI
- Node.js 16+ (for local development)

### Local Development Setup

1. **Install Supabase CLI**
   ```bash
   brew install supabase/tap/supabase
   ```

2. **Start Supabase services**
   ```bash
   cd DirtApp/Backend
   chmod +x setup_supabase.sh
   ./setup_supabase.sh
   ```

3. **Access Supabase Studio**
   Open http://localhost:54323 in your browser to access the Supabase dashboard.

## 📋 Database Schema

### Core Tables

- `users`: Anonymous user accounts
- `reviews`: User-submitted reviews
- `tags`: Categorization for reviews
- `flags`: User reports for content moderation
- `moderation_actions`: Admin actions on content
- `alerts`: User notification preferences

## 🔒 Security

- Row Level Security (RLS) is enabled on all tables
- Anonymous authentication is supported
- All sensitive operations require authentication
- Image uploads are secured with signed URLs

## 🌐 API Endpoints

The following endpoints are available via Supabase:

- `POST /auth/v1/*`: Authentication endpoints
- `POST /rest/v1/*`: Database endpoints
- `POST /storage/v1/*`: File storage endpoints

## 🛠️ Development Workflow

1. Make changes to the migration files
2. Test locally using `setup_supabase.sh`
3. Create a new migration for production:
   ```bash
   supabase migration new your_migration_name
   ```
4. Test the migration locally
5. Deploy to production

## 📚 Documentation

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

## 📄 License

This project is proprietary and confidential.
