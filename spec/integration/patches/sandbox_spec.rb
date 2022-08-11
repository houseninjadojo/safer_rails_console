# frozen_string_literal: true

describe "Integration: patches/sandbox" do
  context "auto_rollback" do
    it "automatically executes rollback and begins a new transaction after executing a invalid SQL statement" do
      run_console_commands('Model.create!', 'Model.where(invalid: :statement)', 'Model.create!')

      # Run a new console session to ensure the database changes were not saved
      result = run_console_commands('puts "Model Count = #{Model.count}"') # rubocop:disable Lint/InterpolationCheck
      expect(result.stdout).to include('Model Count = 0')
    end
  end

  context "read_only" do
    it "enforces a read_only transaction" do
      # Run a console session that makes some database changes
      run_console_commands('Model.create!', 'Model.create!')

      # Run a new console session to ensure the database changes were not saved
      result = run_console_commands('puts "Model Count = #{Model.count}"') # rubocop:disable Lint/InterpolationCheck
      expect(result.stdout).to include('Model Count = 0')
    end

    it "lets the user know that an operation could not be completed" do
      result = run_console_commands('Model.create!')
      expect(result.stdout).to include('An operation could not be completed due to read-only mode.')
    end
  end

  context "active_job" do
    it "activejob - uses test queue adapter" do
      # Run a console session that enqueues a job
      run_console_commands('CoolJob.perform_later', 'CoolJob.perform_later')
      
      # Run a new console session to ensure the jobs were not enqueued
      result = run_console_commands('puts "ActiveJob Jobs Enqueued = #{ActiveJob::Base.queue_adapter.enqueued_jobs.size}"') # rubocop:disable Lint/InterpolationCheck
      expect(result.stdout).to include('ActiveJob Jobs Enqueued = 0')
    end

    it "sidekiq - uses testing module" do
      # Run a console session that enqueues a job
      run_console_commands('CoolJob.perform_async', 'CoolJob.perform_async')
      
      # Run a new console session to ensure the jobs were not enqueued
      result = run_console_commands('puts "Sidekiq Jobs Enqueued = #{Sidekiq::Worker.jobs.count}"') # rubocop:disable Lint/InterpolationCheck
      expect(result.stdout).to include('Sidekiq Jobs Enqueued = 0')
    end
  end

  def run_console_commands(*commands)
    commands += ['exit']
    run_console('--sandbox', input: commands.join("\n"))
  end
end
