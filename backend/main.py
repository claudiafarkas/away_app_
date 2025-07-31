from fastapi import FastAPI
from manual_geocode import router as manual_geocode_router
from away_parser import router as parser_router
# from parser import router as parser_router 

# Optional: include other routers like parser if needed
# from parser import router as parser_router



app = FastAPI()

# Register routers
app.include_router(manual_geocode_router)
app.include_router(parser_router)
# app.include_router(parser_router)