from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from maps_client import autocomplete_places, geocode_query, place_details

router = APIRouter(prefix="/api")


class ManualGeocodeRequest(BaseModel):
    address: str


class PlaceDetailsRequest(BaseModel):
    place_id: str
    session_token: str | None = None


@router.post("/geocode_address")
def geocode_address(req: ManualGeocodeRequest):
    address = (req.address or "").strip()
    if not address:
        raise HTTPException(status_code=400, detail="Missing 'address'")
    return geocode_query(address)


@router.get("/places_autocomplete")
def places_autocomplete(
    query: str = Query(..., min_length=1),
    session_token: str | None = None,
):
    cleaned = query.strip()
    if len(cleaned) < 2:
        return {"suggestions": []}
    return {"suggestions": autocomplete_places(cleaned, session_token)}


@router.get("/place_details")
def get_place_details(
    place_id: str = Query(...),
    session_token: str | None = None,
):
    cleaned = place_id.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail="Missing 'place_id'")
    return place_details(cleaned, session_token)


@router.post("/place_details")
def post_place_details(req: PlaceDetailsRequest):
    cleaned = (req.place_id or "").strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail="Missing 'place_id'")
    return place_details(cleaned, req.session_token)


@router.post("/manual_geocode", include_in_schema=False)
def manual_geocode_alias(req: ManualGeocodeRequest):
    return geocode_address(req)
