from pydantic import BaseModel
from typing import Optional

class ProductOut(BaseModel):
    id: int
    title: str
    description: str
    average_rating: Optional[float] = None
    cover_image_url: Optional[str] = None

    class Config:
        orm_mode = True
