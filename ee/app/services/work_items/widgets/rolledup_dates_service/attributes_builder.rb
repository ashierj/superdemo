# frozen_string_literal: true

module WorkItems
  module Widgets
    module RolledupDatesService
      class AttributesBuilder
        def self.build(work_item, params)
          new(work_item, params).build
        end

        def initialize(work_item, params)
          @work_item = work_item
          @params = params
        end

        def build
          start_date_attributes.merge(due_date_attributes)
        end

        private

        attr_reader :work_item, :params

        def start_date_attributes
          attributes = {}

          if params.key?(:start_date_fixed)
            attributes[:start_date_fixed] = params[:start_date_fixed]
            attributes[:start_date] = params[:start_date_fixed] if params[:start_date_is_fixed]
          end

          if params.key?(:start_date_is_fixed)
            attributes[:start_date_is_fixed] = params[:start_date_is_fixed]

            unless params[:start_date_is_fixed]
              finder.minimum_start_date.first.then do |result|
                attributes.merge!(
                  {
                    start_date: result&.start_date,
                    start_date_is_fixed: false,
                    start_date_sourcing_milestone_id: result&.start_date_sourcing_milestone_id,
                    start_date_sourcing_work_item_id: result&.start_date_sourcing_work_item_id
                  })
              end
            end
          end

          attributes
        end

        def due_date_attributes
          attributes = {}

          if params.key?(:due_date_fixed)
            attributes[:due_date_fixed] = params[:due_date_fixed]
            attributes[:due_date] = params[:due_date_fixed] if params[:due_date_is_fixed]
          end

          if params.key?(:due_date_is_fixed)
            attributes[:due_date_is_fixed] = params[:due_date_is_fixed]

            unless params[:due_date_is_fixed]
              finder.maximum_due_date.first.then do |result|
                attributes.merge!(
                  due_date: result&.due_date,
                  due_date_is_fixed: false,
                  due_date_sourcing_milestone_id: result&.due_date_sourcing_milestone_id,
                  due_date_sourcing_work_item_id: result&.due_date_sourcing_work_item_id
                )
              end
            end
          end

          attributes
        end

        def finder
          @finder ||= WorkItems::Widgets::RolledupDatesFinder.new(work_item)
        end
      end
    end
  end
end
