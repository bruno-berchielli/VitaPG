# frozen_string_literal: true

module Backups
  # Runs an external command with a wall-clock timeout, killing the whole
  # process group on expiry so pg_dump worker processes don't outlive the run.
  # The environment hash is passed to the child only — never through ENV,
  # which would leak credentials across threads.
  class CommandRunner
    Result = Data.define(:stdout, :stderr, :exit_status, :timed_out) do
      def success? = exit_status&.zero? && !timed_out
    end

    class << self
      def run(argv, env: {}, timeout: 3600, chdir: nil)
        stdout_r, stdout_w = IO.pipe
        stderr_r, stderr_w = IO.pipe

        options = { pgroup: true, out: stdout_w, err: stderr_w }
        options[:chdir] = chdir if chdir
        pid = Process.spawn(env, *argv, **options)
        stdout_w.close
        stderr_w.close

        stdout, stderr = read_both(stdout_r, stderr_r)
        status = wait_with_timeout(pid, timeout)

        Result.new(stdout: stdout.value, stderr: stderr.value, exit_status: status&.exitstatus, timed_out: status.nil?)
      ensure
        [ stdout_r, stderr_r ].each { |io| io.close unless io.closed? }
      end

      private

      def read_both(stdout_r, stderr_r)
        [ Thread.new { stdout_r.read }, Thread.new { stderr_r.read } ]
      end

      def wait_with_timeout(pid, timeout)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

        loop do
          _, status = Process.wait2(pid, Process::WNOHANG)
          return status if status

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
            kill_process_group(pid)
            Process.wait2(pid)
            return nil
          end

          sleep 0.2
        end
      end

      def kill_process_group(pid)
        Process.kill("-TERM", pid)
        sleep 2
        Process.kill("-KILL", pid)
      rescue Errno::ESRCH
        # already gone
      end
    end
  end
end
