# frozen_string_literal: true

module ChatQaEvaluationHelpers
  TMP_REPORT_PATH = "tmp/duo_chat"
  ANTHROPIC_TIMEOUT = 50.seconds

  PROMPT = <<~PROMPT

  Human: You are a teacher grading a quiz.
  You are given a question, the context the question is about, and the student's answer.
  You are asked to score the student's answer as either CORRECT or INCORRECT, based on the context.

  <question>
  %<question>s
  </question>

  <context>
  %<context>s
  </context>

  <student_answer>
  %<duo_chat_answer>s
  </student_answer>

  Use the following format to output your answer:

  <format>
  Grade: If the student answer is correct or not. Write CORRECT or INCORRECT
  Explanation: Step-by-step explanation on why a particular grade has been awarded
  </format>

  Grade the student answers based ONLY on their factual accuracy.
  If the student answers the student does not have access to context, the answer is always INCORRECT.
  Ignore differences in punctuation and phrasing between the student answer and true answer.
  It is OK if the student answer contains more information than the true answer,
  as long as it does not contain any conflicting statements.

  Begin!


  Assistant:
  PROMPT

  def evaluate_without_reference(user, resource, question, context)
    response = chat(user, resource, { content: question, cache_response: false, request_id: "12345" })

    result = {
      question: question,
      resource: resource.to_reference(full: true),
      answer: response[:response_modifier].response_body,
      evaluations: []
    }

    test_prompt = format(PROMPT, {
      question: question,
      context: context,
      duo_chat_answer: result[:answer]
    })

    result[:evaluations].push(evaluate_with_claude(user, test_prompt))
    result[:evaluations].push(evaluate_with_vertex(user, test_prompt))

    print_evaluation(result)
    save_evaluation(result)

    result
  end

  def save_evaluation(result)
    save_path = File.join(ENV.fetch('CI_PROJECT_DIR', ''), TMP_REPORT_PATH)
    file_path = File.join(save_path, "qa_#{Time.current.to_i}.json")
    FileUtils.mkdir_p(File.dirname(file_path))

    puts "Saving to #{file_path}"

    File.write(file_path, ::Gitlab::Json.pretty_generate(result))
  end

  def print_evaluation(result)
    puts "----------------------------------------------------"
    puts "------------ Evaluation report (begin) -------------"
    puts "Question: #{result[:question]}\n"
    puts "Resource: #{result[:resource]}\n"
    puts "Chat answer: #{result[:answer]}\n\n"

    result[:evaluations].each do |eval|
      puts "-------------------- Evaluation --------------------"
      puts eval[:model]
      puts eval[:response]
    end

    puts "------------- Evaluation report (end) --------------"
    puts "----------------------------------------------------"
  end

  def evaluate_with_claude(user, test_prompt)
    anthropic_response = Gitlab::Llm::Anthropic::Client.new(user).complete(prompt: test_prompt, temperature: 0.1,
      timeout: ANTHROPIC_TIMEOUT)

    {
      model: Gitlab::Llm::Anthropic::Client::DEFAULT_MODEL,
      response: anthropic_response["completion"]
    }
  end

  def evaluate_with_vertex(user, test_prompt)
    vertex_response = Gitlab::Llm::VertexAi::Client.new(user).text(content: test_prompt)

    {
      model: Gitlab::Llm::VertexAi::ModelConfigurations::Text::NAME,
      response: vertex_response&.dig("predictions", 0, "content").to_s.strip
    }
  end

  def chat(user, resource, options)
    message_attributes = options.extract!(:content, :request_id, :client_subscription_id).merge(
      user: user,
      resource: resource,
      ai_action: 'chat',
      role: ::Gitlab::Llm::AiMessage::ROLE_USER
    )

    ai_prompt_message = ::Gitlab::Llm::AiMessage.for(action: 'chat').new(message_attributes)
    ai_completion = ::Gitlab::Llm::CompletionsFactory.completion!(ai_prompt_message, options)
    response_modifier = ai_completion.execute

    {
      response_modifier: response_modifier
    }
  end
end
