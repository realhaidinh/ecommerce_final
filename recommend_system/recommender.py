from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MultiLabelBinarizer
import numpy as np
from scipy.sparse import csr_matrix
from transformers import AutoTokenizer, AutoModel
import torch
import torch.nn.functional as F
import py_vncorenlp
import os

save_dir = os.path.expanduser("~/.cache/vncorenlp")
py_vncorenlp.download_model(save_dir=save_dir)

class ProductRecommender:
    def __init__(self, model_name, text_weight=0.7, category_weight=0.3, ):
        self.text_weight = text_weight
        self.category_weight = category_weight
        self.mlb = MultiLabelBinarizer()
        self.products = None
        self.id_to_index = None
        self.sim_matrix = None
        self.tokenizer = AutoTokenizer.from_pretrained(model_name)
        self.model = AutoModel.from_pretrained(model_name)
        self.rdrsegmenter = py_vncorenlp.VnCoreNLP(annotators=["wseg"], save_dir=save_dir)
        self.model.eval()
    def get_phobert_embedding(self, text):
        sentence = self.rdrsegmenter.word_segment(text)
        input_ids = torch.tensor([self.tokenizer.encode(sentence)])
        with torch.no_grad():
            outputs = self.model(input_ids)
        embedding = outputs.last_hidden_state.mean(dim=1).squeeze().numpy()
        return embedding
    
    def fit(self, products):
        self.products = products
        self.id_to_index = dict(zip(products["id"], range(len(products))))

        text_data = products[["title", "description"]].agg(" ".join, axis=1)

        text_matrix = np.array([self.get_phobert_embedding(text) for text in text_data])
        text_matrix = csr_matrix(text_matrix)
        
        category_matrix = self.mlb.fit_transform(products["category_ids"])
        category_matrix = csr_matrix(category_matrix)

        text_sim = cosine_similarity(text_matrix, dense_output=False)
        category_sim = cosine_similarity(category_matrix, dense_output=False)

        self.sim_matrix = text_sim.multiply(self.text_weight) + category_sim.multiply(self.category_weight)

    def recommend(self, product_id, top_k=5):
        if self.sim_matrix is None or product_id not in self.id_to_index:
            return []

        idx = self.id_to_index[product_id]
        sim_scores = self.sim_matrix[idx].toarray().flatten()

        sorted_indices = np.argsort(sim_scores)[::-1]
        sorted_indices = [i for i in sorted_indices if i != idx]
        top_indices = sorted_indices[:top_k]

        return self.products['id'].iloc[top_indices].tolist()
