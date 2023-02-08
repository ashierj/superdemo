# frozen_string_literal: true

module SendFileUpload
  def send_upload(file_upload, send_params: {}, redirect_params: {}, attachment: nil, proxy: false, disposition: 'attachment')
    content_type = content_type_for(attachment)

    if attachment
      response_disposition = ActionDispatch::Http::ContentDisposition.format(disposition: disposition, filename: attachment)

      # Response-Content-Type will not override an existing Content-Type in
      # Google Cloud Storage, so the metadata needs to be cleared on GCS for
      # this to work. However, this override works with AWS.
      redirect_params[:query] = { "response-content-disposition" => response_disposition,
                                  "response-content-type" => content_type }
      # By default, Rails will send uploads with an extension of .js with a
      # content-type of text/javascript, which will trigger Rails'
      # cross-origin JavaScript protection.
      send_params[:content_type] = 'text/plain' if File.extname(attachment) == '.js'

      send_params.merge!(filename: attachment, disposition: disposition)
    end

    if image_scaling_request?(file_upload)
      location = file_upload.file_storage? ? file_upload.path : file_upload.url
      headers.store(*Gitlab::Workhorse.send_scaled_image(location, params[:width].to_i, content_type))
      head :ok
    elsif file_upload.file_storage?
      send_file file_upload.path, send_params
    elsif file_upload.class.proxy_download_enabled? || proxy
      headers.store(*Gitlab::Workhorse.send_url(file_upload.url(**redirect_params)))
      head :ok
    else
      redirect_to cdn_fronted_url(file_upload, redirect_params)
    end
  end

  def cdn_fronted_url(file, redirect_params)
    if file.respond_to?(:cdn_enabled_url)
      result = file.cdn_enabled_url(request.remote_ip, redirect_params[:query])
      Gitlab::ApplicationContext.push(artifact_used_cdn: result.used_cdn)
      result.url
    else
      file.url(**redirect_params)
    end
  end

  def content_type_for(attachment)
    return '' unless attachment

    guess_content_type(attachment)
  end

  def guess_content_type(filename)
    types = MIME::Types.type_for(filename)

    if types.present?
      types.first.content_type
    else
      "application/octet-stream"
    end
  end

  private

  def image_scaling_request?(file_upload)
    (avatar_safe_for_scaling?(file_upload) || pwa_icon_safe_for_scaling?(file_upload)) &&
      scaling_allowed_by_feature_flags?(file_upload)
  end

  def pwa_icon_safe_for_scaling?(file_upload)
    file_upload.try(:image_safe_for_scaling?) &&
      mounted_as_pwa_icon?(file_upload) &&
      valid_image_scaling_width?(Appearance::ALLOWED_PWA_ICON_SCALER_WIDTHS)
  end

  def avatar_safe_for_scaling?(file_upload)
    file_upload.try(:image_safe_for_scaling?) &&
      mounted_as_avatar?(file_upload) &&
      valid_image_scaling_width?(Avatarable::ALLOWED_IMAGE_SCALER_WIDTHS)
  end

  def mounted_as_avatar?(file_upload)
    file_upload.try(:mounted_as)&.to_sym == :avatar
  end

  def mounted_as_pwa_icon?(file_upload)
    file_upload.try(:mounted_as)&.to_sym == :pwa_icon
  end

  def valid_image_scaling_width?(allowed_scalar_widths)
    allowed_scalar_widths.include?(params[:width]&.to_i)
  end

  def scaling_allowed_by_feature_flags?(file_upload)
    Feature.enabled?(:dynamic_image_resizing, type: :ops)
  end
end
