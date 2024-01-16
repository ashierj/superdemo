# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Templates
        class GenerateCubeQuery
          def initialize(user_input)
            @user_input = user_input
          end

          def to_prompt
            <<~PROMPT
You are an assistant tasked with converting plain text questions about event data in to a structured query in JSON format. I will provide information about the permitted schema and then ask you to generate a query based on a single question.

The root-level keys and their types are:

measures: An array of measures.
dimensions: An array of dimensions.
timeDimensions: A convenient way to specify a time dimension with a filter
limit: A row limit for your query. The default value is 10000. The maximum allowed limit is 50000.
order: An object, where the keys are measures or dimensions to order by and their corresponding values are either asc or desc. The order of the fields to order on is based on the order of the keys in the object

"measures" must be one or more of the following:

"TrackedEvents.pageViewsCount" which counts the number of page views
"TrackedEvents.uniqueUsersCount" which counts the number of unique users

"dimensions" must be zero or more of the following:

"TrackedEvents.pageUrlhosts"
"TrackedEvents.pageUrlpath"
"TrackedEvents.event"
"TrackedEvents.pageTitle"
"TrackedEvents.osFamily"
"TrackedEvents.osName"
"TrackedEvents.osVersion"
"TrackedEvents.osVersionMajor"
"TrackedEvents.agentName"
"TrackedEvents.agentVersion"
"TrackedEvents.pageReferrer"
"TrackedEvents.pageUrl"
"TrackedEvents.useragent"
"TrackedEvents.derivedTstamp"
"TrackedEvents.browserLanguage"
"TrackedEvents.viewportSize"
"TrackedEvents.userId"

"timeDimensions" is an array of zero or more JSON objects with the following root keys, all of which are mandatory:

"dimension" is a single dimension from the list of acceptable dimensions above.
"dateRange" is an array of two dates between which data is returned. They MUST be in the format YYYY-MM-DD. Alternatively "date range" can be a single string to represent a date range such as "last week" or "this month".
"granularity" is the granularity of the results. Pick something sensible for this value from "hour", "day", "week" or "month"


The question you need to answer is "#{@user_input}"

Please provide the response wrapped in nothing.
            PROMPT
          end
        end
      end
    end
  end
end
