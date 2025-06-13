from typing import Annotated
from fastapi import FastAPI, HTTPException, Query, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.orm import joinedload
from models import Product
from schemas import ProductOut
from recommender import ProductRecommender
import os
import sys
import asyncio
from dotenv import load_dotenv
from contextlib import asynccontextmanager


if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL") or ""

engine = create_async_engine(DATABASE_URL, pool_size=10, max_overflow=20)

recommender = ProductRecommender(text_weight=0.3, category_weight=0.7)

security = HTTPBearer()
ACCESS_TOKEN = os.getenv("ACCESS_TOKEN")

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != ACCESS_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing token",
        )

async def get_session():
    async with AsyncSession(engine) as session:
        yield session
        
SessionDep = Annotated[AsyncSession, Depends(get_session)]

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with AsyncSession(engine) as session:
        await load_data(session)
    yield

app = FastAPI(lifespan=lifespan)

@app.get("/api/recommend/{product_id}", response_model=list[ProductOut])
async def get_recommendations(
    session: SessionDep,
    product_id: int,
    top_k: int = Query(5, ge=1, le=20),
):
    recommended_ids = recommender.recommend(product_id, top_k=top_k)
    statement = select(Product).options(
        joinedload(Product.reviews), joinedload(Product.images), joinedload(Product.categories)
    ).where(Product.id.in_(recommended_ids))
    products = (await session.exec(statement)).unique().all()

    result = []
    for product in products:
        avg_rating = (
            sum([r.rating for r in product.reviews]) / len(product.reviews)
            if product.reviews else 0
        )
        image_url = product.images[0].url if product.images else None
        result.append(ProductOut(
            id=product.id,
            title=product.title,
            sold=product.sold,
            price=product.price,
            description=product.description,
            rating=avg_rating,
            cover=image_url,
        ))
    return result

@app.post("/api/recommend/refresh", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(verify_token)])
async def refresh(session: SessionDep):
    await load_data(session)
    

async def load_data(session: AsyncSession):
    result = await session.exec(
        select(Product).options(joinedload(Product.categories))  # Eagerly load categories
    )
    products = result.unique().all()
    recommender.fit(products)
        
