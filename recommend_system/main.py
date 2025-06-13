from fastapi import FastAPI, HTTPException, Query, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, joinedload
from sqlalchemy.sql import func
from models import Base, Product, Rating
from schemas import ProductOut
from recommender import ProductRecommender
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

app = FastAPI()
recommender = ProductRecommender(text_weight=0.7, category_weight=0.3)

security = HTTPBearer()
ACCESS_TOKEN = os.getenv("ACCESS_TOKEN")  # 🔐 Store securely in .env in production

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != ACCESS_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing token",
        )

@app.on_event("startup")
def startup():
    db = SessionLocal()
    load_data(db)

@app.get("/api/recommend/{product_id}", response_model=list[ProductOut])
def get_recommendations(
    product_id: int,
    top_k: int = Query(5, ge=1, le=20),
):
    db = SessionLocal()
    try:
        recommended_ids = recommender.recommend(product_id, top_k=top_k)

        products = db.query(Product)\
            .options(joinedload(Product.images))\
            .filter(Product.id.in_(recommended_ids)).all()

        avg_ratings = (
            db.query(Rating.product_id, func.avg(Rating.rating).label("avg_rating"))
            .filter(Rating.product_id.in_(recommended_ids))
            .group_by(Rating.product_id)
            .all()
        )
        rating_map = {pid: avg for pid, avg in avg_ratings}

        id_to_product = {p.id: p for p in products}
        result = []
        for pid in recommended_ids:
            p = id_to_product.get(pid)
            if p:
                cover_url = p.images[0].url if p.images else None
                result.append(ProductOut(
                    id=p.id,
                    title=p.title,
                    description=p.description,
                    average_rating=rating_map.get(p.id),
                    cover_image_url=cover_url
                ))
        return result
    finally:
        db.close()

@app.post("/api/recommend/refresh", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(verify_token)])
def refresh():
    db = SessionLocal()
    load_data(db)
    

def load_data(db):
    try:
        products = db.query(Product).options(joinedload(Product.categories)).all()
        product_data = []
        for p in products:
            product_data.append({
                "id": p.id,
                "title": p.title or "",
                "description": p.description or "",
                "category_ids": [c.id for c in p.categories]
            })
        recommender.fit(product_data)
    finally:
        db.close()