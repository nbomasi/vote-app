# Professional Node.js Application

A professional, production-ready Node.js application built with Express, PostgreSQL, and AWS services.

## Project Structure

```
app/
├── backend/              # Backend application code
│   ├── config/          # Configuration files
│   │   └── database.js  # PostgreSQL connection with Secrets Manager
│   ├── routes/           # API routes
│   │   ├── auth.js      # Authentication endpoints
│   │   └── api.js       # Protected API endpoints
│   ├── migrations/       # Database migration files
│   ├── server.js         # Express server entry point
│   ├── package.json      # Backend dependencies
│   └── Dockerfile        # Container configuration
├── frontend/             # Frontend application code
│   ├── index.html       # Main HTML file
│   ├── styles.css       # Styling
│   └── app.js           # Frontend JavaScript
├── scripts/              # Deployment scripts
│   ├── application_start.sh
│   ├── application_stop.sh
│   ├── install.sh
│   └── validate_service.sh
├── buildspec.yml        # CodeBuild configuration
├── appspec.yml          # CodeDeploy configuration
└── README.md            # This file
```

## Architecture

This application is designed to run on AWS infrastructure:

- **RDS PostgreSQL**: Highly available database
- **AWS Secrets Manager**: Secure credential management
- **EC2 Auto Scaling Group**: Scalable compute
- **Application Load Balancer**: Traffic distribution
- **CloudFront CDN**: Content delivery
- **S3 Buckets**: 
  - Static content bucket for frontend files (`frontend/`)
  - Artifacts bucket for CI/CD builds (`backend/`)
- **CodePipeline**: Automated CI/CD deployment

## Features

- ✅ Secure JWT-based authentication
- ✅ Email/password signup and signin
- ✅ PostgreSQL database integration
- ✅ AWS Secrets Manager for credentials
- ✅ Professional, responsive UI
- ✅ Interactive counter feature
- ✅ RESTful API endpoints
- ✅ Health check endpoint

## Prerequisites

- Node.js 18+
- PostgreSQL database (RDS)
- AWS Secrets Manager secret with database credentials
- AWS IAM role with Secrets Manager read permissions

## Environment Variables

Create a `.env` file in the `backend/` directory or set environment variables:

```bash
PORT=3000
NODE_ENV=production
AWS_REGION=us-east-1
DB_SECRET_NAME=rds-db-credentials
JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=7d
DB_SSL=true
```

## Database Setup

1. Create the required tables by running the migration files in `backend/migrations/`:

```sql
-- Run backend/migrations/001_create_users_table.sql
-- Run backend/migrations/002_create_counter_table.sql
```

2. Ensure your RDS PostgreSQL instance is accessible
3. Store database credentials in AWS Secrets Manager with this format:

```json
{
  "host": "your-rds-endpoint.rds.amazonaws.com",
  "port": 5432,
  "dbname": "your_database",
  "username": "your_username",
  "password": "your_password"
}
```

## Local Development

### Backend

1. Navigate to backend directory:
```bash
cd app/backend
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables (see above)

4. Start the server:
```bash
npm start
```

### Frontend

The frontend files are served statically by the Express server. No separate build step is required.

### Full Application

1. Start the backend server (from `app/backend/`):
```bash
npm start
```

2. Open `http://localhost:3000` in your browser

## Deployment

This application is designed to be deployed via AWS CodePipeline:

1. **Frontend Files** (`frontend/`): Automatically uploaded to S3 content bucket
2. **Backend Code** (`backend/`): Packaged and deployed via CodeDeploy to EC2 instances
3. **Database Migrations**: Run manually or via deployment scripts

The `buildspec.yml` automatically separates:
- **Static files** (`frontend/`) → S3 Content Bucket
- **Dynamic files** (`backend/`) → S3 Artifacts Bucket → CodeDeploy

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Create new account
- `POST /api/auth/signin` - Sign in

### API (requires authentication)
- `GET /api/counter` - Get counter value
- `PUT /api/counter` - Update counter value
- `GET /api/health` - Health check

## Security

- Passwords are hashed using bcrypt
- JWT tokens for authentication
- Database credentials stored in AWS Secrets Manager
- HTTPS enforced in production
- Input validation on all endpoints

## File Organization

### Backend (`backend/`)
All server-side code including:
- Express server
- API routes
- Database configuration
- Migrations
- Package dependencies

### Frontend (`frontend/`)
All client-side code including:
- HTML files
- CSS stylesheets
- JavaScript files
- Static assets

This separation makes it easy to:
- Identify frontend vs backend code
- Deploy static files to S3/CDN separately
- Scale frontend and backend independently
- Maintain clear code organization

## License

ISC
