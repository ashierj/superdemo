# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::GitRepository, feature_category: :design_management do
  let_it_be(:project) { create(:project) }
  let(:git_repository) { described_class.new(project) }

  shared_examples 'returns parsed git attributes that enable LFS for all file types' do
    it do
      expect(subject.patterns).to be_a_kind_of(Hash)
      expect(subject.patterns).to have_key('/designs/*')
      expect(subject.patterns['/designs/*']).to eql(
        { "filter" => "lfs", "diff" => "lfs", "merge" => "lfs", "text" => false }
      )
    end
  end

  describe "#info_attributes" do
    subject { git_repository.info_attributes }

    include_examples 'returns parsed git attributes that enable LFS for all file types'
  end

  describe '#attributes_at' do
    subject { git_repository.attributes_at }

    include_examples 'returns parsed git attributes that enable LFS for all file types'
  end

  describe '#gitattribute' do
    it 'returns a gitattribute when path has gitattributes' do
      expect(git_repository.gitattribute('/designs/file.txt', 'filter')).to eq('lfs')
    end

    it 'returns nil when path has no gitattributes' do
      expect(git_repository.gitattribute('/invalid/file.txt', 'filter')).to be_nil
    end
  end

  describe '#copy_gitattributes' do
    it 'always returns regardless of whether given a valid or invalid ref' do
      expect(git_repository.copy_gitattributes('master')).to be true
      expect(git_repository.copy_gitattributes('invalid')).to be true
    end
  end

  describe '#attributes' do
    it 'confirms that all files are LFS enabled' do
      %w[png zip anything].each do |filetype|
        path = "/#{DesignManagement.designs_directory}/file.#{filetype}"
        attributes = git_repository.attributes(path)

        expect(attributes['filter']).to eq('lfs')
      end
    end
  end
end
