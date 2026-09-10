from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

# Only load .env in local development (not on Cloud Run)
if os.getenv("ENV", "dev") != "prod":
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

from manual_geocode import router as manual_geocode_router
from away_parser import router as parser_router

app = FastAPI(title="Away API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(manual_geocode_router)
app.include_router(parser_router)


@app.get("/healthz")
def healthz():
    return {"ok": True}
