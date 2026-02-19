# Application Structure Reference

This document provides a clear overview of the application structure with frontend and backend separation.

## Directory Structure

```
app/
├── backend/                    # Backend Application (Node.js/Express)
│   ├── config/
│   │   └── database.js        # PostgreSQL connection via AWS Secrets Manager
│   ├── routes/
│   │   ├── auth.js            # Authentication routes (signup/signin)
│   │   └── api.js             # Protected API routes (counter, etc.)
│   ├── migrations/
│   │   ├── 001_create_users_table.sql
│   │   └── 002_create_counter_table.sql
│   ├── server.js              # Express server entry point
│   ├── package.json           # Backend dependencies
│   └── Dockerfile            # Container configuration
│
├── frontend/                   # Frontend Application (Static Files)
│   ├── index.html             # Main HTML file
│   ├── styles.css             # CSS styling
│   └── app.js                 # Frontend JavaScript
│
├── scripts/                    # Deployment Scripts
│   ├── application_start.sh   # Start application
│   ├── application_stop.sh    # Stop application
│   ├── install.sh             # Install dependencies
│   └── validate_service.sh    # Validate service health
│
├── buildspec.yml              # CodeBuild configuration
├── appspec.yml                # CodeDeploy configuration
├── README.md                  # Main documentation
├── ARCHITECTURE_INTEGRATION.md # Architecture guide
└── STRUCTURE.md               # This file
```

## File Organization

### Backend (`backend/`)
All server-side code:
- **Server**: Express.js application
- **Routes**: API endpoints (auth, counter)
- **Config**: Database connection configuration
- **Migrations**: SQL migration files
- **Dependencies**: Node.js packages (pg, express, jwt, etc.)

### Frontend (`frontend/`)
All client-side code:
- **HTML**: User interface markup
- **CSS**: Styling and layout
- **JavaScript**: Client-side logic and API calls

### Scripts (`scripts/`)
Deployment automation:
- **Install**: Sets up dependencies
- **Start/Stop**: Manages application lifecycle
- **Validate**: Health checks

## Key References

### Backend Server References
- `backend/server.js` serves static files from `../frontend/`
- Routes are defined in `backend/routes/`
- Database config in `backend/config/database.js`

### Build Process
- `buildspec.yml` separates:
  - `frontend/` → `artifacts/static/` (S3 Content Bucket)
  - `backend/` → `artifacts/dynamic/` (S3 Artifacts Bucket)

### Deployment
- `appspec.yml` defines deployment to `/var/www/app/`
- Scripts in `scripts/` handle installation and startup
- Backend runs from `/var/www/app/backend/`
- Frontend files served from `/var/www/app/frontend/`

## Benefits of This Structure

1. **Clear Separation**: Easy to identify frontend vs backend code
2. **Independent Deployment**: Frontend can be deployed to S3/CDN separately
3. **Scalability**: Frontend and backend can scale independently
4. **Maintainability**: Clear organization makes code easier to maintain
5. **Team Collaboration**: Frontend and backend teams can work independently

## Development Workflow

### Backend Development
```bash
cd app/backend
npm install
npm start
```

### Frontend Development
- Edit files in `app/frontend/`
- Changes are served by the Express server
- No build step required (static files)

### Full Stack Development
```bash
# Start backend (serves frontend automatically)
cd app/backend
npm start

# Access at http://localhost:3000
```

## Deployment Workflow

1. **CodeBuild** (`buildspec.yml`):
   - Installs backend dependencies
   - Separates frontend and backend files
   - Creates deployment packages

2. **S3 Upload**:
   - Frontend files → S3 Content Bucket
   - Backend package → S3 Artifacts Bucket

3. **CodeDeploy** (`appspec.yml`):
   - Deploys backend to EC2
   - Frontend files available via backend server or S3/CDN

## Environment Variables

Set in EC2 instances or deployment configuration:
```bash
PORT=3000
NODE_ENV=production
AWS_REGION=us-east-1
DB_SECRET_NAME=rds-db-credentials
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d
DB_SSL=true
```
