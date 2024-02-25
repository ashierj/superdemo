# frozen_string_literal: true

FakeContext = Struct.new(:gitlab_version, :backup_basedir, keyword_init: true)

def spec_path
  Pathname.new(__dir__).join('..').expand_path
end

def temp_path
  spec_path.join('..', 'tmp').expand_path
end

def stub_env(var, return_value)
  stub_const('ENV', ENV.to_hash.merge(var => return_value))
end

def build_fake_context
  FakeContext.new(gitlab_version: '16.10', backup_basedir: temp_path.join('backups'))
end
