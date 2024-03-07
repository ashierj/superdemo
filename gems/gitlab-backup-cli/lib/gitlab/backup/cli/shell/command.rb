# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Shell
        # Abstraction to control shell command execution
        # It provides an easier API to common usages
        class Command
          attr_reader :cmd_args, :env

          # Result data structure from running a command
          #
          # @attr [String] stdout
          # @attr [String] stderr
          # @attr [Process::Status] status
          # @attr [Float] duration
          Result = Struct.new(:stdout, :stderr, :status, :duration, keyword_init: true)

          # Result data structure from running a command in single pipeline mode
          #
          # @attr [String] stderr
          # @attr [Process::Status] status
          # @attr [Float] duration
          SinglePipelineResult = Struct.new(:stderr, :status, :duration, keyword_init: true)

          # @example Usage
          #   Shell.new('echo', 'Some amazing output').capture
          # @param [Array<String>] cmd_args
          # @param [Hash<String,String>] env
          def initialize(*cmd_args, env: {})
            @cmd_args = cmd_args
            @env = env
          end

          # Execute a process and return its output and status
          #
          # @return [Command::Result] Captured output from executing a process
          def capture
            start = Time.now
            stdout, stderr, status = Open3.capture3(env, *cmd_args)
            duration = Time.now - start

            Result.new(stdout: stdout, stderr: stderr, status: status, duration: duration)
          end

          # Run single command in pipeline mode with optional input or output redirection
          #
          # @param [IO|String|Array] input stdin redirection
          # @param [IO|String|Array] output stdout redirection
          # @return [Command::SinglePipelineResult]
          def run_single_pipeline!(input: nil, output: nil)
            start = Time.now
            # Open3 writes on `err_write` and we receive from `err_read`
            err_read, err_write = IO.pipe

            # Pipeline accepts custom {Process.spawn} options
            # stderr capture is always performed, stdin and stdout redirection
            # are performed only when either `input` or `output` are present
            options = { err: err_write } # redirect stderr to IO pipe
            options[:in] = input if input # redirect stdin
            options[:out] = output if output # redirect stdout

            status_list = Open3.pipeline(cmd_args, **options)
            duration = Time.now - start

            err_write.close # close the pipe before reading
            stderr = err_read.read
            err_read.close # close after reading to avoid leaking file descriptors

            SinglePipelineResult.new(stderr: stderr, status: status_list[0], duration: duration)
          end
        end
      end
    end
  end
end
