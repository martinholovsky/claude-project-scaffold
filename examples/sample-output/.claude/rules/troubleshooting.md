# Troubleshooting Playbook

> **When to use:** Debugging known issues, investigating error patterns,
> before spending time on a problem that may already be solved.
>
> **Read first for:** Any error investigation, failed builds, broken connectivity.

## 1. FastAPI / Uvicorn

### Symptom: `ModuleNotFoundError` when starting uvicorn

**Diagnosis:** Virtual environment not activated, or dependency not installed.

**Fix:**
```bash
source .venv/bin/activate
pip install -r requirements.txt
```

---

### Symptom: 422 Unprocessable Entity on POST requests

**Diagnosis:** Request body does not match the Pydantic schema. FastAPI returns 422
with field-level validation errors in the response body.

**Fix:** Check the response body `detail` array for which fields failed validation.
Compare your request body against the Pydantic model in `app/schemas/`.

---

## 2. Database

### Symptom: {describe database issue}

**Diagnosis:** {root cause}

**Fix:**
```bash
# commands to resolve
```

---

## 3. Authentication

*Add entries as you encounter auth-related issues.*

---

## 4. Testing

### Symptom: Tests pass locally but fail in CI

**Diagnosis:** Usually an environment difference (missing env var, database state, timezone).

**Fix:** Ensure CI sets the same environment variables as local `.env`. Check for
test isolation — tests should not depend on execution order.

---

*Add entries as you encounter and solve issues. Use the Symptom -> Diagnosis -> Fix format.*
