from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MultiLabelBinarizer
import numpy as np

class ProductRecommender:
    def __init__(self, text_weight=0.7, category_weight=0.3):
        self.text_weight = text_weight
        self.category_weight = category_weight

    def fit(self, products):
        self.products = products
        self.id_index_map = {p["id"]: i for i, p in enumerate(products)}

        texts = [f"{p['title']} {p['description']}" for p in products]
        self.tfidf = TfidfVectorizer().fit_transform(texts)

        self.mlb = MultiLabelBinarizer()
        self.cat_matrix = self.mlb.fit_transform([p["category_ids"] for p in products])

    def recommend(self, product_id, top_k=5):
        if product_id not in self.id_index_map:
            return []

        idx = self.id_index_map[product_id]

        text_sim = cosine_similarity(self.tfidf.getrow(idx), self.tfidf).flatten()
        cat_sim = cosine_similarity(self.cat_matrix[idx:idx+1], self.cat_matrix).flatten()

        sim_score = self.text_weight * text_sim + self.category_weight * cat_sim

        top_indices = np.argsort(sim_score)[::-1]
        top_indices = [i for i in top_indices if self.products[i]["id"] != product_id]

        return [self.products[i]["id"] for i in top_indices[:top_k]]
