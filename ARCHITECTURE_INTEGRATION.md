# Architecture Integration Guide

This document explains how the application integrates with the AWS architecture defined in the main architecture diagram.

## Application Overview

This professional Node.js application is designed to run on the AWS infrastructure with the following components:

### Database Layer
- **RDS PostgreSQL**: Highly available database for user data and application state
- **AWS Secrets Manager**: Secure storage and retrieval of database credentials
- The application automatically retrieves credentials from Secrets Manager on startup

### Application Layer
- **EC2 Instances**: Runs the Node.js application in private subnets
- **Auto Scaling Group**: Ensures high availability and scalability
- **Application Load Balancer**: Routes traffic to EC2 instances

### Content Delivery
- **CloudFront CDN**: Serves static content from S3
- **S3 Content Bucket**: Stores static files (`/assets/*` from `public/` directory)
- **S3 Artifacts Bucket**: Stores build artifacts for CodeDeploy

### CI/CD Pipeline
- **CodeCommit**: Source code repository
- **CodePipeline**: Orchestrates the deployment process
- **CodeBuild**: Builds and packages the application
- **CodeDeploy**: Deploys to EC2 instances

## File Separation Strategy

### Frontend Files (S3 Content Bucket)
Files in the `frontend/` directory are considered static and should be uploaded to the S3 content bucket:
- `frontend/index.html`
- `frontend/styles.css`
- `frontend/app.js`
- Any other static assets

These files are served via CloudFront CDN for optimal performance.

### Backend Files (S3 Artifacts Bucket)
Application code and configuration files in the `backend/` directory are packaged for CodeDeploy:
- `backend/server.js`
- `backend/config/`
- `backend/routes/`
- `backend/migrations/`
- `backend/package.json` and `backend/package-lock.json`
- `backend/Dockerfile`
- `appspec.yml`
- `scripts/`

These are packaged into `deployment-package.zip` and stored in the artifacts bucket for CodeDeploy.

## Build Process (CodeBuild)

The `buildspec.yml` file defines the build process:

1. **Install Phase**: Installs Node.js dependencies
2. **Pre-build Phase**: Validates application structure
3. **Build Phase**: Prepares the application
4. **Post-build Phase**: 
   - Separates frontend files into `artifacts/static/` (for S3 content bucket)
   - Packages backend files into `deployment-package.zip` (for CodeDeploy artifacts bucket)
   - Both are stored as build artifacts

## Deployment Process (CodeDeploy)

The `appspec.yml` file defines the deployment process:

1. **BeforeInstall**: Stops the existing application
2. **AfterInstall**: 
   - Installs Node.js dependencies
   - Sets up the application
3. **ApplicationStart**: Starts the Node.js server
4. **ValidateService**: Verifies the application is running

## Database Credentials

The application retrieves database credentials from AWS Secrets Manager. The secret should contain:

```json
{
  "host": "your-rds-endpoint.rds.amazonaws.com",
  "port": 5432,
  "dbname": "your_database_name",
  "username": "your_username",
  "password": "your_password"
}
```

Set the secret name via environment variable: `DB_SECRET_NAME=rds-db-credentials`

## Environment Variables

Required environment variables on EC2 instances:

```bash
PORT=3000
NODE_ENV=production
AWS_REGION=us-east-1
DB_SECRET_NAME=rds-db-credentials
JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=7d
DB_SSL=true
```

## Database Migrations

Run the migration files on your RDS PostgreSQL instance:

1. `backend/migrations/001_create_users_table.sql` - Creates users table
2. `backend/migrations/002_create_counter_table.sql` - Creates counter table

These can be run manually or automated as part of the deployment process.

## Security Considerations

1. **IAM Roles**: EC2 instances need IAM role with:
   - Secrets Manager read permissions
   - S3 read permissions (for static content if needed)

2. **Security Groups**: 
   - ALB security group allows HTTPS (443) from CloudFront/WAF
   - EC2 security group allows traffic from ALB
   - RDS security group allows PostgreSQL (5432) from EC2 security group

3. **JWT Secret**: Change `JWT_SECRET` in production - consider storing in Secrets Manager

## Application Flow

1. User requests → Route 53 → CloudFront → WAF
2. Static files (`/assets/*`) → S3 Content Bucket
3. API requests (`/api/*`) → ALB → EC2 Instances
4. EC2 Instances → Secrets Manager (get DB credentials) → RDS PostgreSQL
5. CI/CD: CodeCommit → CodePipeline → CodeBuild → S3 Artifacts → CodeDeploy → EC2

## Monitoring

The application includes a health check endpoint:
- `GET /api/health` - Returns application and database status

This can be used by:
- ALB health checks
- CloudWatch monitoring
- CodeDeploy validation

## Next Steps

1. Set up RDS PostgreSQL instance
2. Create Secrets Manager secret with database credentials
3. Run database migrations
4. Configure CodePipeline to use the `app/` directory
5. Set up S3 buckets (content and artifacts)
6. Configure CloudFront to serve static files from S3 content bucket
7. Deploy via CodePipeline
