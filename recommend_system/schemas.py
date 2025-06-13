from pydantic import BaseModel
from typing import Optional

from models import ProductImage

class Image(BaseModel):
    url: str

class ProductOut(BaseModel):
    id: int
    title: str
    description: str
    sold: int
    price: int
    rating: Optional[float] = None
    images: list[Image]

    class Config:
        orm_mode = True
