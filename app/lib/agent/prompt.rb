
  class Agent::Prompt
    def self.summary_prompt(content, examples)
      <<~PROMPT
        You are an expert summarizer. Your task is to create a concise summary of the provided content.

        This is the content you need to summarize:
        <----- Content start ----->
        #{content}
        <----- Content end ----->

        To maintain the tone and style, please refer to the following examples:
        <----- Examples start ----->
        #{example_information(examples)}
        <----- Examples end ----->
      PROMPT
    end

    def self.review_prompt(summary, examples, feedback = "")
      <<~PROMPT
        You are an expert summarizer and excel at reviewing content. Your task is to review the summary based on the examples provided.
        You will be given a summary, and sometimes feedback. You will use examples to understand the desired tone and style. Your review should focus on clarity, coherence, and adherence to the provided examples.
        If you do not find the summary satisfactory, provide generate a revised summary based on the feedback provided and what you think is satisfactory.

        This is the summary you need to review:
        <----- Content start ----->
        #{summary}
        <----- Content end ----->

        To maintain the tone and style, please refer to the following examples:
        <----- Examples start ----->
        #{example_information(examples)}
        <----- Examples end ----->

        If feedback is provided, consider it while reviewing the summary and generating a revised summary:
        <----- Feedback start ----->
        #{feedback}
        <----- Feedback end ----->

        If you find any issues with the summary, please provide feedback and a new summary which is as per the provided feedback.
        If the summary is satisfactory, simply confirm that it meets the requirements.
        The response should be in json format with the following structure:
        <------ Response format start ----->
        If the snippet is accurate and acceptable, respond ONLY with:
        {"satisfactory": true}

        If it needs edits, respond ONLY with:
        {"satisfactory": false, "revised_summary": "...", "feedback": "..."}
        <------ Response format end ----->
      PROMPT
    end

    def self.regenerate_prompt(summary, feedback, examples)
      <<~PROMPT
        You are an expert at the english language. Your task is to rewrite a summary considering the feedback provided.

        This is the existing summary you need to rewrite:
        <----- Content start ----->
        #{summary}
        <----- Content end ----->

        Here is the feedback you need to consider:
        <----- Feedback start ----->
        #{feedback}
        <----- Feedback end ----->

        To maintain the tone and style, please refer to the following examples:
        <----- Examples start ----->
        #{example_information(examples)}
        <----- Examples end ----->
      PROMPT
    end

    private

    def self.example_information(examples)
      examples.map.with_index do |example, index|
        <<~EXAMPLE_INFORMATION
          Example ##{index + 1}:
          #{example.content}
        EXAMPLE_INFORMATION
      end.join("\n\n")
    end
  end
