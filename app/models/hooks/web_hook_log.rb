# frozen_string_literal: true

class WebHookLog < ApplicationRecord
  include Presentable
  include DeleteWithLimit
  include CreatedAtFilterable
  include PartitionedTable

  OVERSIZE_REQUEST_DATA = { 'oversize' => true }.freeze

  attr_accessor :interpolated_url

  self.primary_key = :id

  partitioned_by :created_at, strategy: :monthly, retain_for: 3.months

  belongs_to :web_hook

  serialize :request_headers, Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :request_data, Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :response_headers, Hash # rubocop:disable Cop/ActiveRecordSerialize

  validates :web_hook, presence: true

  before_save :obfuscate_basic_auth
  before_save :redact_user_emails
  before_save :set_url_hash, if: -> { interpolated_url.present? }

  def self.recent
    where(created_at: 2.days.ago.beginning_of_day..Time.zone.now)
      .order(created_at: :desc)
  end

  # Delete a batch of log records. Returns true if there may be more remaining.
  def self.delete_batch_for(web_hook, batch_size:)
    raise ArgumentError, 'batch_size is too small' if batch_size < 1

    where(web_hook: web_hook).limit(batch_size).delete_all == batch_size
  end

  def success?
    response_status =~ /^2/
  end

  def internal_error?
    response_status == WebHookService::InternalErrorResponse::ERROR_MESSAGE
  end

  def oversize?
    request_data == OVERSIZE_REQUEST_DATA
  end

  def request_headers
    super unless web_hook.token?
    super if self[:request_headers]['X-Gitlab-Token'] == _('[REDACTED]')

    self[:request_headers].merge('X-Gitlab-Token' => _('[REDACTED]'))
  end

  def url_current?
    # URL hash hasn't been set, so we must assume there's no prior value to
    # compare to.
    return true if url_hash.nil?

    Gitlab::CryptoHelper.sha256(web_hook.interpolated_url) == url_hash
  end

  private

  def obfuscate_basic_auth
    self.url = Gitlab::UrlSanitizer.sanitize_masked_url(url)
  end

  def redact_user_emails
    self.request_data.deep_transform_values! do |value|
      URI::MailTo::EMAIL_REGEXP.match?(value.to_s) ? _('[REDACTED]') : value
    end
  end

  def set_url_hash
    self.url_hash = Gitlab::CryptoHelper.sha256(interpolated_url)
  end
end
