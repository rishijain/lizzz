class GenerateSummaryJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)
    return unless article

    examples = article.find_nearest
    prompt = Agent::Prompt.summary_prompt(article.content, examples)
    summary = Agent::Llm.new.chat(prompt)

    summary_agent = Agent::GenerateSummary.new
    summary_agent.generate_reviewed_summary(summary, examples)
  rescue => e
    Rails.logger.error "GenerateSummaryJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
