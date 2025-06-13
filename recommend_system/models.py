from typing import List
from sqlmodel import SQLModel, Field, Relationship

class ProductImage(SQLModel, table=True):
    __tablename__ = "product_images"
    id: int = Field(default=None, primary_key=True)
    product_id: int = Field(foreign_key="products.id")
    url: str
    product: "Product" = Relationship(back_populates="images")

class Review(SQLModel, table=True):
    __tablename__ = "reviews"
    id: int = Field(default=None, primary_key=True)
    product_id: int = Field(foreign_key="products.id")
    rating: int
    product: "Product" = Relationship(back_populates="reviews")

class ProductCategories(SQLModel, table=True):
    __tablename__ = "product_categories"
    product_id: int = Field(foreign_key="products.id", primary_key=True)
    category_id: int = Field(foreign_key="categories.id", primary_key=True)

class Product(SQLModel, table=True):
    __tablename__ = "products"
    id: int = Field(default=None, primary_key=True)
    title: str
    description: str
    sold: int
    price: int
    images: List["ProductImage"] = Relationship(back_populates="product")
    reviews: List["Review"] = Relationship(back_populates="product")
    categories: List["Category"] = Relationship(back_populates="products", link_model=ProductCategories)

class Category(SQLModel, table=True):
    __tablename__ = "categories"
    id: int = Field(default=None, primary_key=True)
    title: str
    products: List["Product"] = Relationship(back_populates="categories", link_model=ProductCategories)