from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# Load local .env in dev. On Cloud Run, env vars come from the service config.
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

from manual_geocode import router as manual_geocode_router
from away_parser import router as parser_router

app = FastAPI(title="Away API")

# CORS: keep permissive while developing/TestFlight; you can restrict origins later.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # tighten later (e.g., to the domain)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount routers (each already uses prefix="/api")
app.include_router(manual_geocode_router)
app.include_router(parser_router)

# Simple health endpoint for checks/logs
@app.get("/healthz")
def healthz():
    return {"ok": True}