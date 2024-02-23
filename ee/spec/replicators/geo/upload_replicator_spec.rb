# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::UploadReplicator, feature_category: :geo_replication do
  let(:model_record) { create(:upload, :with_file) }

  include_examples 'a blob replicator'

  describe "predownload_validation_failure" do
    context "when upload is valid and has an associated model/owner" do
      it "returns nil" do
        expect(replicator.predownload_validation_failure).to be_nil
      end
    end

    context "when upload is orphaned from its own model association" do
      before do
        # break the model association on the upload
        model_record.model_id = -1
        model_record.save!(validate: false)
        model_record.reload
      end

      it "returns an error string" do
        upload = model_record
        missing_model = "#{upload.model_type} with ID #{upload.model_id}"
        expect(replicator.predownload_validation_failure).to eq(
          "The model which owns Upload with ID #{upload.id} is missing: #{missing_model}"
        )
      end
    end
  end
end
