# Buildspec.yml Explanation

This document explains how the buildspec.yml works and answers common questions.

## Build Process Overview

### 1. Install Phase
**Command**: `npm install` (in `backend/` directory)
- Installs Node.js dependencies for the backend
- No build command needed - Node.js runs directly

### 2. Pre-build Phase
**Purpose**: Validation checks
- Verifies `backend/server.js` exists
- Verifies `frontend/` directory exists
- Verifies `backend/routes/` directory exists

### 3. Build Phase
**Command**: None (just organization)
- No actual building happens
- Node.js application doesn't require compilation
- Just prepares and organizes files

### 4. Post-build Phase
**Commands**: File organization
- Creates `artifacts/` directory
- Copies `frontend/` → `artifacts/frontend/`
- Copies `backend/` → `artifacts/backend/`
- Copies `scripts/` and `appspec.yml`

## S3 Upload Process

**Important**: The buildspec.yml does NOT upload files to S3 directly.

### How It Works:
1. **CodeBuild** (buildspec.yml):
   - Organizes files into `artifacts/frontend/` and `artifacts/backend/`
   - Outputs artifacts as specified in the `artifacts:` section

2. **CodePipeline** (automatic):
   - Automatically zips the artifacts
   - Uploads to S3 Artifacts Bucket
   - Makes artifacts available to subsequent stages

3. **S3 Content Bucket Upload**:
   - This happens in a separate CodePipeline stage (S3 Deploy action)
   - Uses the `artifacts/frontend/**` files from CodeBuild output
   - **Configure this in CodePipeline (AWS Console/CloudFormation), NOT in any file in your repository**
   - See `CODEPIPELINE_S3_UPLOAD.md` for configuration details

4. **CodeDeploy**:
   - Uses `artifacts/backend/**` files from S3 Artifacts Bucket
   - Deploys to EC2 instances

## Why No Zip Command?

**CodePipeline automatically zips artifacts**, so:
- ❌ Don't create zip files in buildspec.yml
- ✅ Just organize files in directories
- ✅ CodePipeline handles zipping and S3 upload

## Why Maintain Frontend/Backend Structure?

Instead of `artifacts/static/` and `artifacts/dynamic/`, we use:
- `artifacts/frontend/` - Clear, matches source structure
- `artifacts/backend/` - Clear, matches source structure

**Benefits**:
- Easier to understand and maintain
- Matches the source code structure
- Clear separation of concerns

## Artifacts Section

```yaml
artifacts:
  files:
    - artifacts/frontend/**    # Static files for S3 Content Bucket
    - artifacts/backend/**     # Application code for CodeDeploy
    - artifacts/scripts/**    # Deployment scripts
    - artifacts/appspec.yml   # CodeDeploy configuration
```

CodePipeline will:
1. Zip all these files automatically
2. Upload to S3 Artifacts Bucket
3. Make available to subsequent pipeline stages

## Complete Flow

```
CodeCommit
    ↓
CodeBuild (buildspec.yml)
    ├── Installs dependencies
    ├── Validates structure
    └── Organizes artifacts/
        ├── frontend/  → S3 Content Bucket (via S3 Deploy action)
        └── backend/   → S3 Artifacts Bucket → CodeDeploy → EC2
```

## Configuration in CodePipeline

**Important**: The S3 Content Bucket upload is **NOT executed by any file in your codebase**. It's configured as a CodePipeline action in AWS.

To upload frontend to S3 Content Bucket, add an **S3 Deploy** action in CodePipeline:
- Source: CodeBuild output artifacts
- Source path: `artifacts/frontend/**`
- Destination: S3 Content Bucket
- **Location**: AWS CodePipeline Console, CloudFormation, or CLI (NOT in repository files)

See `CODEPIPELINE_S3_UPLOAD.md` for detailed configuration instructions.
