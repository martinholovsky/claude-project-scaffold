# API Contracts

> Document your actual API endpoints here.

## Base URL

- **Local dev:** `http://localhost:8000/api/v1`
- **Production:** `https://api.example.com/api/v1`

## Authentication

All protected endpoints require `Authorization: Bearer <jwt>` header.

## Endpoints

*Add your real endpoints below as you build them:*

```
GET  /api/v1/resources          # List (paginated)
POST /api/v1/resources          # Create
GET  /api/v1/resources/{id}     # Get one
PATCH /api/v1/resources/{id}    # Update
```
