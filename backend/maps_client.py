import os
import re
from urllib.parse import unquote, parse_qs, urlparse

import requests
from dotenv import load_dotenv
from fastapi import HTTPException

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))


def google_api_key() -> str:
    key = (
        os.getenv("BACKEND_GOOGLE_API_KEY")
        or os.getenv("GOOGLE_MAPS_API_KEY")
        or os.getenv("GOOGLE_API_KEY")
    )
    if not key:
        raise HTTPException(
            status_code=500,
            detail="Server is missing BACKEND_GOOGLE_API_KEY",
        )
    return key


def google_error_detail(action: str, data: dict) -> str:
    status = data.get("status") or "UNKNOWN"
    message = (data.get("error_message") or "").strip()
    detail = f"{action} failed: {status}"
    if message:
        detail = f"{detail} ({message})"
    return detail


def city_country_from_components(components: list | None, formatted: str = "") -> tuple[str, str]:
    city = ""
    country = ""
    admin = ""
    for component in components or []:
        types = component.get("types") or []
        name = component.get("long_name") or ""
        if "locality" in types or "postal_town" in types:
            city = city or name
        elif "administrative_area_level_2" in types and not city:
            city = name
        elif "administrative_area_level_1" in types:
            admin = name
        elif "country" in types:
            country = name
    if not city:
        city = admin
    if city and country:
        return city, country

    parts = [p.strip() for p in (formatted or "").split(",") if p.strip()]
    country = country or (parts[-1] if parts else "")
    city_raw = city or (parts[-2] if len(parts) >= 2 else "")
    city = re.sub(r"^\d+\s*", "", city_raw)
    return city, country


def location_payload(
    *,
    name: str,
    formatted: str,
    lat: float,
    lng: float,
    place_id: str | None = None,
    components: list | None = None,
) -> dict:
    city, country = city_country_from_components(components, formatted)
    return {
        "name": name,
        "address": formatted,
        "city": city,
        "country": country,
        "lat": lat,
        "lng": lng,
        "place_id": place_id,
    }


def normalize_location_query(raw: str) -> str:
    text = (raw or "").strip()
    if not text:
        return text

    lower = text.lower()
    is_maps_link = any(
        token in lower
        for token in (
            "google.com/maps",
            "maps.google.",
            "maps.app.goo.gl",
            "goo.gl/maps",
        )
    )
    if not is_maps_link:
        return text

    resolved = text
    if "goo.gl" in lower or "maps.app.goo.gl" in lower:
        try:
            resp = requests.head(text, allow_redirects=True, timeout=8)
            resolved = str(resp.url or text)
        except requests.RequestException:
            resolved = text

    place_match = re.search(r"/place/([^/@]+)", resolved)
    if place_match:
        return unquote(place_match.group(1).replace("+", " ")).replace("-", " ")

    parsed = urlparse(resolved)
    query = parse_qs(parsed.query)
    for key in ("q", "query", "destination"):
        if query.get(key):
            return unquote(query[key][0].replace("+", " "))

    coord_match = re.search(r"@(-?\d+\.\d+),(-?\d+\.\d+)", resolved)
    if coord_match:
        return f"{coord_match.group(1)},{coord_match.group(2)}"

    return text


def geocode_query(address: str) -> dict:
    query = normalize_location_query(address)
    try:
        resp = requests.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            params={"address": query, "key": google_api_key()},
            timeout=15,
        )
        data = resp.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"Geocoding request failed: {e}") from e

    status = data.get("status")
    results = data.get("results") or []
    if status != "OK" or not results:
        raise HTTPException(status_code=400, detail=google_error_detail("Geocoding", data))

    places = []
    for place in results[:5]:
        loc = (place.get("geometry") or {}).get("location") or {}
        formatted = place.get("formatted_address") or query
        name = query
        places.append(
            location_payload(
                name=name,
                formatted=formatted,
                lat=loc.get("lat"),
                lng=loc.get("lng"),
                place_id=place.get("place_id"),
                components=place.get("address_components"),
            )
        )
    primary = {
        **places[0],
        "results": places,
    }
    return primary


def autocomplete_places(query: str, session_token: str | None = None) -> list[dict]:
    query = normalize_location_query(query)
    params = {
        "input": query,
        "key": google_api_key(),
    }
    if session_token:
        params["sessiontoken"] = session_token
    try:
        resp = requests.get(
            "https://maps.googleapis.com/maps/api/place/autocomplete/json",
            params=params,
            timeout=15,
        )
        data = resp.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"Places autocomplete failed: {e}") from e

    status = data.get("status")
    if status == "ZERO_RESULTS":
        return []
    if status != "OK":
        # Fall back to geocoding so a Places-only outage still yields suggestions.
        try:
            geo = geocode_query(query)
            return [
                {
                    "place_id": item.get("place_id"),
                    "primary_text": item.get("name") or query,
                    "secondary_text": item.get("address") or "",
                    "description": item.get("address") or query,
                }
                for item in geo.get("results") or [geo]
            ]
        except HTTPException:
            raise HTTPException(status_code=400, detail=google_error_detail("Places autocomplete", data))

    suggestions = []
    for prediction in data.get("predictions") or []:
        structured = prediction.get("structured_formatting") or {}
        suggestions.append(
            {
                "place_id": prediction.get("place_id"),
                "primary_text": structured.get("main_text") or prediction.get("description") or query,
                "secondary_text": structured.get("secondary_text") or "",
                "description": prediction.get("description") or query,
            }
        )
    return suggestions


def place_details(place_id: str, session_token: str | None = None) -> dict:
    params = {
        "place_id": place_id,
        "fields": "name,formatted_address,geometry,address_component,place_id",
        "key": google_api_key(),
    }
    if session_token:
        params["sessiontoken"] = session_token
    try:
        resp = requests.get(
            "https://maps.googleapis.com/maps/api/place/details/json",
            params=params,
            timeout=15,
        )
        data = resp.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"Place details request failed: {e}") from e

    result = data.get("result") or {}
    loc = (result.get("geometry") or {}).get("location") or {}
    if data.get("status") != "OK" or loc.get("lat") is None or loc.get("lng") is None:
        raise HTTPException(status_code=400, detail=google_error_detail("Place details", data))

    formatted = result.get("formatted_address") or ""
    name = result.get("name") or formatted
    return location_payload(
        name=name,
        formatted=formatted,
        lat=loc.get("lat"),
        lng=loc.get("lng"),
        place_id=result.get("place_id") or place_id,
        components=result.get("address_components"),
    )
