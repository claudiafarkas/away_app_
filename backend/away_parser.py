from fastapi import FastAPI
from fastapi import APIRouter, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import instaloader
import spacy
import requests
import os
import traceback
import re
from dotenv import load_dotenv


router = APIRouter()

# load backend/.env
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))            # calls the .env in the backend folder only

GOOGLE_API_KEY = os.getenv("BACKEND_GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    raise RuntimeError("Missing BACKEND_GOOGLE_API_KEY in .env")

nlp = spacy.load("en_core_web_trf")
L = instaloader.Instaloader()


class ParseRequest(BaseModel):
    url: str


def extract_shortcode(url: str) -> str | None:
    """
    Extracts the shortcode from a valid Instagram URL.
    """
    # Match the last part after /reel/ or /p/ or /tv/ etc.
    match = re.search(r"(?:/reel/|/p/|/tv/)([A-Za-z0-9_-]{5,})", url)
    return match.group(1) if match else None


# def get_caption(url: str) -> str:
#     """
#     Fetches Instagram post data using Instaloader.
#     """
#     shortcode = url.rstrip("/").split("/")[-1]
#     post = instaloader.Post.from_shortcode(L.context, shortcode)
#     return post.caption or ""

def get_caption(url: str) -> str:
    """
    Fetches Instagram post data using Instaloader.
    """
    shortcode = extract_shortcode(url)
    if not shortcode:
        raise ValueError("Invalid Instagram URL format. Couldn't extract shortcode.")
    
    post = instaloader.Post.from_shortcode(L.context, shortcode)
    return post.caption or ""
    

def get_location_data(text: str) -> list[str]:
    """
    Groups nearby spaCy entities (GPE, LOC, PERSON) into
    multi-word location strings when they occur close together.
    """
    doc = nlp(text)
    # 1. Checks relevant labels to look out for
    # ents = [ e for e in doc.ents
    #     if e.label_ in ("GPE", "LOC", "PERSON", "ORG", "FAC", "WORK_OF_ART", "EVENT", "LANGUAGE", "NORP", "PRODUCT", "LAW", "MONEY")
    #        and "#" not in e.text
    #        and "|" not in e.text]
    ents = [
        e for e in doc.ents
        if e.label_ in ("GPE", "LOC", "FAC")  # Stick to geographic entities
        and len(e.text.split()) <= 5  # Skip super long hashtags chains
        and not any(char in e.text for char in "#|")
    ]
    print("\nDetected Entities:", [e.text for e in ents])
    # 2. Sorts them by where they appear in the text
    ents = sorted(ents, key=lambda e: e.start_char)
    # 3. Groups them by proximity
    groups = []
    for ent in ents:
        if not groups:
            groups.append([ent])
        else:
            prev = groups[-1][-1]
            # If it's within 5 characters of the previous ent, join them
            if ent.start_char - prev.end_char <= 5:
                groups[-1].append(ent)
            else:
                groups.append([ent])
    # 4. Extract unique entities from the parsed caption and join them with commas
    spans = []
    for grp in groups:
        start = grp[0].start_char
        end = grp[-1].end_char
        span_text = text[start:end].strip().strip(",")
        if span_text and span_text not in spans:
            spans.append(span_text)
    return spans



def get_location_geocodes(name: str) -> dict | None:
    """
    Fetches location coordinates using Google Maps API and splits address into city/country.
    """
    resp = requests.get("https://maps.googleapis.com/maps/api/geocode/json", params={"address": name, "key": GOOGLE_API_KEY}).json()
    print(f"Geocoding '{name}':", resp.get("status"), resp.get("results", []))
    if resp.get("status") == "OK" and resp["results"]:
        place = resp["results"][0]
        full_address = place["formatted_address"]
        # Split address into components
        parts = [p.strip() for p in full_address.split(",")]
        country = parts[-1] if len(parts) >= 1 else ""
        city_raw = parts[-2] if len(parts) >= 2 else ""
        import re
        city = re.sub(r"^\d+\s*", "", city_raw)
        return {
          "name": name,
          "address": full_address,
          "city": city,
          "country": country,
          "lat": place["geometry"]["location"]["lat"],
          "lng": place["geometry"]["location"]["lng"],
        }
    return None



def remove_duplicate_get_location_geocodes(locations: list[dict]) -> list[dict]:
    """
    Removes duplicate geocoded locations based on their names and addresses.
    """
    filtered = []
    seen_names = set()

    for loc in locations:
        name = loc["name"]
        address = loc["address"]
        print("\nProcessing Location:", name)

        if "#" in name or "|" in name:
            print("Skipping location with invalid characters # or | :", name)
            continue
        if any(
            other["name"] == name and other["address"].lower() == address.lower()
            for other in filtered
        ):
            print("Skipping location with similar address:", loc["address"])
            continue
         # Skip repeated mentions of the same location
        if name in seen_names:
            print("Skipping duplicate location:", name)
            continue

        filtered.append(loc)
        seen_names.add(name)
    
    print("\nFiltered Locations:", filtered)
    return filtered

# get_location_geocodes = remove_duplicate_get_location_geocodes(get_location_geocodes)


@router.post("/parse_instagram_post")
def parse_instagram_post(req: ParseRequest):
    """
    Endpoint to parse Instagram post data.
    """
    try:
        cap = get_caption(req.url)
        print("\n Parsed Caption:", cap)

        names = get_location_data(cap)
        print(f"Extracted Location Names: {names}")

        geocoded = [g for g in (get_location_geocodes(n) for n in names) if g]
        print(f"Geocoded Locations: {geocoded}")

        unique_geocoded = remove_duplicate_get_location_geocodes(geocoded)
        print(f"Unique Geocoded Locations: {unique_geocoded}")
        
        return {"caption": cap, "locations": unique_geocoded}
    
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {e}")


# -----------------------------
# FastAPI application bootstrap
# -----------------------------
app = FastAPI(title="Away Parser API")

# Allow local dev frontends to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount our router under /api
app.include_router(router, prefix="/api")

@app.post("/parse_instagram_post", include_in_schema=False)
def parse_instagram_post_alias(req: ParseRequest):
    # Reuse the same handler the router uses
    return parse_instagram_post(req)

@app.get("/health")
def health():
    return {"ok": True}

# Optional: run directly via `python away_parser.py`
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("away_parser:app", host="0.0.0.0", port=8000, reload=True)
