# frozen_string_literal: true

module Backups
  # Runs an external command with a wall-clock timeout, killing the whole
  # process group on expiry (or when the caller asks to abort) so pg_dump
  # worker processes don't outlive the run. The environment hash is passed to
  # the child only — never through ENV, which would leak credentials across
  # threads.
  class CommandRunner
    Result = Data.define(:stdout, :stderr, :exit_status, :timed_out, :aborted) do
      def success? = exit_status&.zero? && !timed_out && !aborted
    end

    class << self
      # @param on_stderr_line [Proc, nil] called with each stderr line as the
      #   child produces it (pg_dump --verbose reports progress there)
      # @param abort_if [Proc, nil] polled while the child runs; a truthy
      #   value kills it and returns a result flagged as aborted
      def run(argv, env: {}, timeout: 3600, chdir: nil, on_stderr_line: nil, abort_if: nil)
        stdout_r, stdout_w = IO.pipe
        stderr_r, stderr_w = IO.pipe

        options = { pgroup: true, out: stdout_w, err: stderr_w }
        options[:chdir] = chdir if chdir
        pid = Process.spawn(env, *argv, **options)
        stdout_w.close
        stderr_w.close

        stdout = Thread.new { stdout_r.read }
        stderr = Thread.new { read_lines(stderr_r, on_stderr_line) }
        status, outcome = wait_for(pid, timeout, abort_if)

        Result.new(stdout: stdout.value, stderr: stderr.value, exit_status: status&.exitstatus,
                   timed_out: outcome == :timed_out, aborted: outcome == :aborted)
      ensure
        [ stdout_r, stderr_r ].each { |io| io.close unless io.closed? }
      end

      private

      def read_lines(io, callback)
        buffer = +""
        io.each_line do |line|
          buffer << line
          begin
            callback&.call(line.chomp)
          rescue
            # A progress observer must never kill the read loop.
          end
        end
        buffer
      end

      def wait_for(pid, timeout, abort_if)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

        loop do
          _, status = Process.wait2(pid, Process::WNOHANG)
          return [ status, :exited ] if status

          outcome =
            if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline then :timed_out
            elsif abort_if&.call then :aborted
            end

          if outcome
            kill_process_group(pid)
            Process.wait2(pid)
            return [ nil, outcome ]
          end

          sleep 0.2
        end
      end

      def kill_process_group(pid)
        Process.kill("-TERM", pid)
        sleep 2
        Process.kill("-KILL", pid)
      rescue Errno::ESRCH, Errno::EPERM
        # already gone (macOS answers EPERM for a group left with only zombies)
      end
    end
  end
end
