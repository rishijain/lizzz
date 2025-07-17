a = Article.last
examples = a.find_nearest
p = Agent::Prompt.summary_prompt(a.content, examples)
summary = Agent::Llm.new.chat(p)
MAX_RETRY = 3

ag = Agent::GenerateSummary.new
ag.generate_review(summary, examples)
