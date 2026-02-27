# Troubleshooting Playbook

> Add entries as you encounter and solve issues. Use the **Symptom → Diagnosis → Fix** format.

### Symptom: `ModuleNotFoundError` when starting uvicorn

**Diagnosis:** Virtual environment not activated, or dependency not installed.

**Fix:**
```bash
source .venv/bin/activate
pip install -r requirements.txt
```

---

### Symptom: 422 Unprocessable Entity on POST requests

**Diagnosis:** Request body does not match the Pydantic schema. Check the response body `detail` array for which fields failed validation.

**Fix:** Compare your request body against the Pydantic model in `app/schemas/`.