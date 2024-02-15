# frozen_string_literal: true

module Types
  module Security
    class PipelineSecurityReportFindingSortEnum < BaseEnum
      graphql_name 'PipelineSecurityReportFindingSort'
      description 'Pipeline security report finding sort values'

      value 'SEVERITY_DESC', value: 'severity_desc', description: 'Severity in descending order.'
      value 'SEVERITY_ASC', value: 'severity_asc', description: 'Severity in ascending order.'
    end
  end
end
