from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MultiLabelBinarizer
import numpy as np

class ProductRecommender:
    def __init__(self, text_weight=0.7, category_weight=0.3):
        self.text_weight = text_weight
        self.category_weight = category_weight
        self.vectorizer = TfidfVectorizer(stop_words="english")
        self.mlb = MultiLabelBinarizer()
        self.products = None
        self.id_to_index = None
        self.sim_matrix = None

    def fit(self, products):
        self.products = products
        self.id_to_index = {p.id: i for i, p in enumerate(products)}

        text_data = [f"{p.title} {p.description}" for p in products]

        text_matrix = self.vectorizer.fit_transform(text_data)

        category_ids = [[cat.id for cat in p.categories] for p in products]

        category_matrix = self.mlb.fit_transform(category_ids)

        text_sim = cosine_similarity(text_matrix)
        category_sim = cosine_similarity(category_matrix)


        self.sim_matrix = (text_sim * self.text_weight) + (category_sim * self.category_weight)

    def recommend(self, product_id, top_k=5):
        if self.sim_matrix is None or product_id not in self.id_to_index:
            return []

        idx = self.id_to_index[product_id]
        sim_scores = self.sim_matrix[idx]
        similar_indices = np.argsort(sim_scores)[::-1][1:top_k + 1]
        return [self.products[i].id for i in similar_indices]