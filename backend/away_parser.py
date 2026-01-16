from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import requests
import spacy
import os
import traceback
import re
from dotenv import load_dotenv

router = APIRouter(prefix="/api")

# Load local .env only in dev (Cloud Run ignores this)
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

GOOGLE_API_KEY = os.getenv("BACKEND_GOOGLE_API_KEY") or os.getenv("GOOGLE_MAPS_API_KEY")
APIFY_API_TOKEN = os.getenv("APIFY_API_TOKEN")
if not GOOGLE_API_KEY:
    raise RuntimeError("Missing BACKEND_GOOGLE_API_KEY or GOOGLE_MAPS_API_KEY in environment")
if not APIFY_API_TOKEN:
    raise RuntimeError("Missing APIFY_API_TOKEN in environment")

# --- spaCy model: try transformer first, fall back to small if unavailable ---
try:
    nlp = spacy.load("en_core_web_trf")
except Exception:
    try:
        nlp = spacy.load("en_core_web_sm")
    except Exception as e:
        # If neither model is available, give a clear error.
        raise RuntimeError(
            "No spaCy model found. Install en_core_web_sm or en_core_web_trf."
        ) from e

class ParseRequest(BaseModel):
    url: str  # expects Instagram URL

def extract_shortcode(url: str) -> str | None:
    """
    Extracts the shortcode from a valid Instagram URL (/reel/, /p/, /tv/).
    """
    match = re.search(r"(?:/reel/|/p/|/tv/)([A-Za-z0-9_-]{5,})", url)
    return match.group(1) if match else None

def get_caption(url: str) -> str:
    """
    Fetch Instagram post caption using Apify Instagram Post Scraper.
    Raises ValueError if URL is invalid or API fails.
    """
    # Run the Apify actor
    run_url = "https://api.apify.com/v2/acts/apidojo~instagram-post-scraper/runs"
    headers = {"Authorization": f"Bearer {APIFY_API_TOKEN}", "Content-Type": "application/json"}
    payload = {"postUrl": url}
    
    response = requests.post(run_url, json=payload, headers=headers)
    if response.status_code != 201:
        raise ValueError(f"Failed to start Apify run: {response.text}")
    
    run_id = response.json()["data"]["id"]
    
    # Poll for completion
    import time
    for _ in range(30):  # Wait up to 30 * 5s = 150s
        status_response = requests.get(f"https://api.apify.com/v2/acts/apidojo~instagram-post-scraper/runs/{run_id}", headers=headers)
        status = status_response.json()["data"]["status"]
        if status == "SUCCEEDED":
            break
        elif status in ["FAILED", "ABORTED"]:
            raise ValueError(f"Apify run failed: {status}")
        time.sleep(5)
    else:
        raise ValueError("Apify run timed out")
    
    # Get results
    dataset_url = f"https://api.apify.com/v2/acts/apidojo~instagram-post-scraper/runs/{run_id}/dataset/items"
    dataset_response = requests.get(dataset_url, headers=headers)
    if dataset_response.status_code != 200:
        raise ValueError(f"Failed to get dataset: {dataset_response.text}")
    
    data = dataset_response.json()
    if not data:
        raise ValueError("No data returned from Apify")
    
    caption = data[0].get("caption", "")
    return caption

def get_location_data(text: str) -> list[str]:
    """
    Extract likely place mentions from caption using spaCy NER and simple grouping.
    We keep only short GPE/LOC/FAC spans and group near-adjacent entities.
    """
    doc = nlp(text)
    ents = [
        e for e in doc.ents
        if e.label_ in ("GPE", "LOC", "FAC")
        and len(e.text.split()) <= 5
        and not any(char in e.text for char in "#|")
    ]
    # Keep in appearance order
    ents = sorted(ents, key=lambda e: e.start_char)

    # Group entities that are within 5 characters
    groups = []
    for ent in ents:
        if not groups:
            groups.append([ent])
        else:
            prev = groups[-1][-1]
            if ent.start_char - prev.end_char <= 5:
                groups[-1].append(ent)
            else:
                groups.append([ent])

    # Build deduplicated spans
    spans = []
    for grp in groups:
        start = grp[0].start_char
        end = grp[-1].end_char
        span_text = text[start:end].strip().strip(",")
        if span_text and span_text not in spans:
            spans.append(span_text)
    return spans

def geocode_name(name: str) -> dict | None:
    """
    Geocode a place name via Google Geocoding and split city/country.
    """
    try:
        resp = requests.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            params={"address": name, "key": GOOGLE_API_KEY},
            timeout=15,
        )
        data = resp.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"Geocoding request failed: {e}")

    if data.get("status") != "OK" or not data.get("results"):
        return None

    place = data["results"][0]
    full_address = place["formatted_address"]

    parts = [p.strip() for p in full_address.split(",")]
    country = parts[-1] if len(parts) >= 1 else ""
    city_raw = parts[-2] if len(parts) >= 2 else ""
    city = re.sub(r"^\d+\s*", "", city_raw)

    return {
        "name": name,
        "address": full_address,
        "city": city,
        "country": country,
        "lat": place["geometry"]["location"]["lat"],
        "lng": place["geometry"]["location"]["lng"],
    }

def dedupe_locations(locations: list[dict]) -> list[dict]:
    """
    Remove duplicates by (name, address) pair and skip names containing '#' or '|'.
    """
    filtered = []
    seen = set()
    for loc in locations:
        name = loc["name"]
        if "#" in name or "|" in name:
            continue
        key = (name.lower(), loc["address"].lower())
        if key in seen:
            continue
        seen.add(key)
        filtered.append(loc)
    return filtered

@router.post("/parse_instagram_post")
def parse_instagram_post(req: ParseRequest):
    """
    Body: { "url": "<instagram link>" }
    Returns: { "caption": str, "locations": [{ name,address,city,country,lat,lng }...] }
    """
    # Basic URL guard so manual address payloads don’t hit this route by mistake
    if not req.url or not (req.url.startswith("http://") or req.url.startswith("https://")):
        raise HTTPException(
            status_code=400,
            detail="Body must include 'url' (Instagram link). For address geocoding, call POST /api/geocode_address with {'address': '...'}",
        )

    try:
        caption = get_caption(req.url)
        names = get_location_data(caption)
        geocoded = [g for g in (geocode_name(n) for n in names) if g]
        unique = dedupe_locations(geocoded)
        return {"caption": caption, "locations": unique}

    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {e}")
