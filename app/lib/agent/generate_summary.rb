class Agent::GenerateSummary
  def initialize
    @llm = Agent::Llm.new
    @prompt = Agent::Prompt
  end

  def generate_summary(content, examples)
    prompt = @prompt.summary_prompt(content, examples)
    @llm.chat(prompt)
  end

  def generate_reviewed_summary(summary, examples)
    max_attempts = 4
    attempt = 1
    feedback = ""
    while attempt < max_attempts
      prompt = @prompt.review_prompt(summary, examples, feedback)
      review = @llm.chat(prompt)

      review = JSON.parse(review)

      puts "1"*100
      puts "Review attempt #{attempt}"
      puts "Review response: #{review["feedback"]}"
      return summary if review["satisfactory"] == "true"

      summary = review["revised_summary"]
      feedback = review["feedback"]
      attempt += 1
      break if attempt > max_attempts
    end
    summary
  end
end
