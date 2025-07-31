from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import requests
import os
from dotenv import load_dotenv

router = APIRouter()

class GeocodeRequest(BaseModel):
    address: str


# load backend/.env
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))            # calls the .env in the backend folder only

@router.post("/manual_geocode")
def manual_geocode(req: GeocodeRequest):
    GOOGLE_API_KEY = os.getenv("BACKEND_GOOGLE_API_KEY")
    if not GOOGLE_API_KEY:
        raise RuntimeError("Missing BACKEND_GOOGLE_API_KEY in .env")

    url = f"https://maps.googleapis.com/maps/api/geocode/json?address={req.address}&key={GOOGLE_API_KEY}"
    response = requests.get(url)
    data = response.json()

    if data["status"] != "OK":
        raise HTTPException(status_code=400, detail=f"Geocoding failed: {data['status']}")

    location = data["results"][0]["geometry"]["location"]
    return {"lat": location["lat"], "lng": location["lng"]}