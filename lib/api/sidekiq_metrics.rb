# frozen_string_literal: true

require 'sidekiq/api'

module API
  class SidekiqMetrics < ::API::Base
    before { authenticated_as_admin! }

    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

    helpers do
      def queue_metrics
        hash = {}
        Gitlab::Redis::Queues.instances.each_value do |v| # rubocop:disable Cop/RedisQueueUsage -- allow iteration over shard instances
          queue_metrics_from_shard(v.sidekiq_redis).each do |queue_name, queue_details|
            if hash[queue_name].nil?
              hash[queue_name] = queue_details
            else
              hash[queue_name][:backlog] += queue_details[:backlog]
              hash[queue_name][:latency] = [queue_details[:latency], hash[queue_name][:latency]].max
            end
          end
        end
        hash
      end

      def queue_metrics_from_shard(pool)
        Sidekiq::Client.via(pool) do
          ::Gitlab::SidekiqConfig.routing_queues.each_with_object({}) do |queue_name, hash|
            queue = Sidekiq::Queue.new(queue_name)
            hash[queue.name] = {
              backlog: queue.size,
              latency: queue.latency.to_i
            }
          end
        end
      end

      def process_metrics
        Gitlab::Redis::Queues.instances.values.flat_map do |v| # rubocop:disable Cop/RedisQueueUsage -- allow iteration over shard instances
          process_metrics_from_shard(v.sidekiq_redis)
        end
      end

      def process_metrics_from_shard(pool)
        Sidekiq::Client.via(pool) do
          Sidekiq::ProcessSet.new(false).map do |process|
            {
              hostname: process['hostname'],
              pid: process['pid'],
              tag: process['tag'],
              started_at: Time.at(process['started_at']),
              queues: process['queues'],
              labels: process['labels'],
              concurrency: process['concurrency'],
              busy: process['busy']
            }
          end
        end
      end

      def job_stats
        stats = {
          processed: 0,
          failed: 0,
          enqueued: 0,
          dead: 0
        }

        Gitlab::Redis::Queues.instances.each_value do |shard| # rubocop:disable Cop/RedisQueueUsage -- allow iteration over shard instances
          job_stats_from_shard(shard.sidekiq_redis).each { |k, v| stats[k] += v }
        end

        stats
      end

      def job_stats_from_shard(pool)
        Sidekiq::Client.via(pool) do
          stats = Sidekiq::Stats.new
          {
            processed: stats.processed,
            failed: stats.failed,
            enqueued: stats.enqueued,
            dead: stats.dead_size
          }
        end
      end
    end

    desc 'Get the Sidekiq queue metrics'
    get 'sidekiq/queue_metrics' do
      { queues: queue_metrics }
    end

    desc 'Get the Sidekiq process metrics'
    get 'sidekiq/process_metrics' do
      { processes: process_metrics }
    end

    desc 'Get the Sidekiq job statistics'
    get 'sidekiq/job_stats' do
      { jobs: job_stats }
    end

    desc 'Get the Sidekiq Compound metrics. Includes queue, process, and job statistics'
    get 'sidekiq/compound_metrics' do
      { queues: queue_metrics, processes: process_metrics, jobs: job_stats }
    end
  end
end
