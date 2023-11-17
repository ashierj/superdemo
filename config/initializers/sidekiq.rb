# frozen_string_literal: true
module SidekiqLogArguments
  def self.enabled?
    Gitlab::Utils.to_boolean(ENV['SIDEKIQ_LOG_ARGUMENTS'], default: true)
  end
end

def load_cron_jobs!
  Sidekiq::Cron::Job.load_from_hash! Gitlab::SidekiqConfig.cron_jobs

  Gitlab.ee do
    Gitlab::Mirror.configure_cron_job!

    Gitlab::Geo.configure_cron_jobs!
  end
end

def enable_reliable_fetch?
  return true unless Feature::FlipperFeature.table_exists?

  Feature.enabled?(:gitlab_sidekiq_reliable_fetcher, type: :ops)
end

def enable_semi_reliable_fetch_mode?
  return true unless Feature::FlipperFeature.table_exists?

  Feature.enabled?(:gitlab_sidekiq_enable_semi_reliable_fetcher, type: :ops)
end

# Custom Queues configuration
queues_config_hash = Gitlab::Redis::Queues.redis_client_params

enable_json_logs = Gitlab.config.sidekiq.log_format != 'text'

# Sidekiq's `strict_args!` raises an exception by default in 7.0
# https://github.com/sidekiq/sidekiq/blob/31bceff64e10d501323bc06ac0552652a47c082e/docs/7.0-Upgrade.md?plain=1#L59
Sidekiq.strict_args!(false)

Sidekiq.configure_server do |config|
  config[:strict] = false
  config[:queues] = Gitlab::SidekiqConfig.expand_queues(config[:queues])

  if enable_json_logs
    config.logger.formatter = Gitlab::SidekiqLogging::JSONFormatter.new
    config[:job_logger] = Gitlab::SidekiqLogging::StructuredLogger

    # Remove the default-provided handler. The exception is logged inside
    # Gitlab::SidekiqLogging::StructuredLogger
    config.error_handlers.delete(Sidekiq::Config::ERROR_HANDLER)
  end

  Sidekiq.logger.info "Listening on queues #{config[:queues].uniq.sort}"

  config.redis = queues_config_hash

  config.server_middleware(&Gitlab::SidekiqMiddleware.server_configurator(
    metrics: Settings.monitoring.sidekiq_exporter,
    arguments_logger: SidekiqLogArguments.enabled? && !enable_json_logs,
    skip_jobs: Gitlab::Utils.to_boolean(ENV['SIDEKIQ_SKIP_JOBS'], default: true)
  ))

  config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)

  config.death_handlers << Gitlab::SidekiqDeathHandler.method(:handler)

  config.on :startup do
    # Clear any connections that might have been obtained before starting
    # Sidekiq (e.g. in an initializer).
    ActiveRecord::Base.clear_all_connections! # rubocop:disable Database/MultipleDatabases

    # Start monitor to track running jobs. By default, cancel job is not enabled
    # To cancel job, it requires `SIDEKIQ_MONITOR_WORKER=1` to enable notification channel
    Gitlab::SidekiqDaemon::Monitor.instance.start

    first_sidekiq_worker = !ENV['SIDEKIQ_WORKER_ID'] || ENV['SIDEKIQ_WORKER_ID'] == '0'
    health_checks = Settings.monitoring.sidekiq_health_checks

    # Start health-check in-process server
    if first_sidekiq_worker && health_checks.enabled
      Gitlab::HealthChecks::Server.instance(
        address: health_checks.address,
        port: health_checks.port
      ).start
    end
  end

  config.on(:shutdown) do
    Gitlab::Cluster::LifecycleEvents.do_worker_stop
  end

  if enable_reliable_fetch?
    config[:semi_reliable_fetch] = enable_semi_reliable_fetch_mode?
    Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
  end

  Gitlab::SidekiqVersioning.install!

  config[:cron_poll_interval] = Gitlab.config.cron_jobs.poll_interval
  load_cron_jobs!

  # Avoid autoload issue such as 'Mail::Parsers::AddressStruct'
  # https://github.com/mikel/mail/issues/912#issuecomment-214850355
  Mail.eager_autoload!

  # Ensure the whole process group is terminated if possible
  Gitlab::SidekiqSignals.install!(Sidekiq::CLI::SIGNAL_HANDLERS)
end

Sidekiq.configure_client do |config|
  config.redis = queues_config_hash
  # We only need to do this for other clients. If Sidekiq-server is the
  # client scheduling jobs, we have access to the regular sidekiq logger that
  # writes to STDOUT
  config.logger = Gitlab::SidekiqLogging::ClientLogger.build
  config.logger.formatter = Gitlab::SidekiqLogging::JSONFormatter.new if enable_json_logs

  config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)
end

Sidekiq::Scheduled::Poller.prepend Gitlab::Patch::SidekiqPoller
Sidekiq::Cron::Poller.prepend Gitlab::Patch::SidekiqPoller
Sidekiq::Cron::Poller.prepend Gitlab::Patch::SidekiqCronPoller
