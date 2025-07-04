class Article < ApplicationRecord
  has_neighbors :embedding

  def embed
    url = "https://api.openai.com/v1/embeddings"
    headers = {
      "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
      "Content-Type" => "application/json"
    }
    data = {
      input: content,
      model: "text-embedding-3-small"
    }

    response = Net::HTTP.post(URI(url), data.to_json, headers).tap(&:value)
    JSON.parse(response.body)["data"].map { |v| v["embedding"] }
  end

  def save_embedding
    self.embedding = embed.first
    save!
  end

  def find_nearest
    nearest_neighbors(:embedding, distance: "cosine").first(5)
  end
end
