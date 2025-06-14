from typing import Annotated
from fastapi import FastAPI, HTTPException, Query, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.ext.asyncio import create_async_engine
from schemas import ProductOut
from recommender import ProductRecommender
import os
import sys
import asyncio
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from sqlmodel import text, bindparam
import pandas as pd

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL") or ""

engine = create_async_engine(DATABASE_URL, pool_size=10, max_overflow=20)

recommender = ProductRecommender(text_weight=0.6, category_weight=0.4, model_name="vinai/phobert-base")

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
        await load_data()
    yield


app = FastAPI(lifespan=lifespan)


@app.get("/api/recommend/{product_id}", response_model=list[ProductOut])
async def get_recommendations(
    session: SessionDep,
    product_id: int,
    top_k: int = Query(5, ge=1, le=20),
):
    recommended_ids = recommender.recommend(product_id, top_k=top_k)
    statement = """
        SELECT
        p.id,
        p.title,
        p.description,
        p.sold,
        p.price,
        img.url AS image_url,
        AVG(r.rating) AS avg_rating
        FROM products p
        LEFT JOIN LATERAL (
            SELECT url FROM product_images
            WHERE product_id = p.id
            ORDER BY id ASC
            LIMIT 1
        ) img ON true
        LEFT JOIN reviews r ON r.product_id = p.id
        WHERE p.id in :recommended_ids
        GROUP BY p.id, img.url
    """
    products = (
        (await session.exec(
            statement=text(statement).bindparams(bindparam("recommended_ids", expanding=True)),
            params={"recommended_ids": recommended_ids}
        ))
        .unique()
        .all()
    )

    result = []
    for product in products:
        avg_rating = product.avg_rating if product.avg_rating else 0
        image_url = product.image_url if product.image_url else ""
        result.append(
            ProductOut(
                id=product.id,
                title=product.title,
                sold=product.sold,
                price=product.price,
                description=product.description,
                rating=avg_rating,
                cover=image_url,
            )
        )
    return result


@app.post(
    "/api/recommend/refresh",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(verify_token)],
)
async def refresh():
    await load_data()


def read_sql_query(conn, stmt):
    return pd.read_sql(stmt, conn)


async def load_data():
    stmt = """
    SELECT
        p.id, p.title as title, p.description,
        ARRAY_AGG(pc.category_id) AS category_ids
    FROM products p
    LEFT JOIN product_categories pc ON pc.product_id = p.id
    GROUP BY p.id
    """

    async with engine.connect() as conn:
        products = await conn.run_sync(read_sql_query, stmt)

    recommender.fit(products)
