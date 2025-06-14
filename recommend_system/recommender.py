from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MultiLabelBinarizer
import numpy as np
from scipy.sparse import csr_matrix


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
        self.id_to_index = dict(zip(products["id"], range(len(products))))

        text_data = products[["title", "description"]].agg(" ".join, axis=1)

        text_matrix = csr_matrix(self.vectorizer.fit_transform(text_data))

        category_matrix = csr_matrix(self.mlb.fit_transform(products["category_ids"]))

        text_sim = cosine_similarity(text_matrix, dense_output=False)
        category_sim = cosine_similarity(category_matrix, dense_output=False)

        self.sim_matrix = text_sim.multiply(self.text_weight) + category_sim.multiply(self.category_weight)

    def recommend(self, product_id, top_k=5):
        if self.sim_matrix is None or product_id not in self.id_to_index:
            return []

        idx = self.id_to_index[product_id]
        sim_scores = self.sim_matrix[idx].toarray().flatten()

        similar_indices = np.argsort(sim_scores)[::-1][1:min(top_k + 1, len(sim_scores))]

        return self.products['id'].iloc[similar_indices].tolist()
