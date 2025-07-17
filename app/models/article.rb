class Article < ApplicationRecord
  belongs_to :blog_site
  has_neighbors :embedding

  def embed
    llm = Langchain::LLM::OpenAI.new(
            api_key: ENV["OPENAI_API_KEY"],
            default_options: { temperature: 0.7, chat_model: "text-embedding-3-small" }
    )

    response = llm.embed(text: content)
    embedding = response.embedding
  end

  def save_embedding
    self.embedding = embed.first
    save!
  end

  def find_nearest
    nearest_neighbors(:embedding, distance: "cosine").first(5)
  end
end
