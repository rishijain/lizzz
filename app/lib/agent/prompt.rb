
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

    def self.review_prompt(summary, examples)
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
