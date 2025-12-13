from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

app = FastAPI()

@app.get("/api/health")
async def health_check():
    return {"status": "ok"}

app.mount("/", StaticFiles(directory="static", html=True), name="static")
