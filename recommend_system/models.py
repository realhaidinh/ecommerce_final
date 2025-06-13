from sqlalchemy import Column, Integer, String, Text, Float, ForeignKey, Table
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

product_category = Table(
    "product_categories",
    Base.metadata,
    Column("product_id", Integer, ForeignKey("products.id")),
    Column("category_id", Integer, ForeignKey("categories.id"))
)

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True)
    title = Column(String)
    description = Column(Text)
    sold = Column(Integer)
    price = Column(Integer)
    categories = relationship("Category", secondary=product_category)
    ratings = relationship("Rating")
    images = relationship("ProductImage")

class Category(Base):
    __tablename__ = "categories"
    id = Column(Integer, primary_key=True)
    title = Column(String)

    products = relationship("Product", secondary=product_category, viewonly=True)

class Rating(Base):
    __tablename__ = "reviews"
    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    rating = Column(Float)

    product = relationship("Product", viewonly=True)

class ProductImage(Base):
    __tablename__ = "product_images"
    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    url = Column(String)

    product = relationship("Product", viewonly=True)
