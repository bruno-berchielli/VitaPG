# frozen_string_literal: true

module Destinations
  # Write-free storage access check (HEAD bucket).
  class Tester < ApplicationService
    Result = Data.define(:success, :message) do
      def success? = success
    end

    attr_reader :destination

    def initialize(destination)
      @destination = destination
    end

    def call
      destination.adapter.verify_access!
      Result.new(success: true, message: "Bucket accessible")
    rescue Aws::Errors::ServiceError, Seahorse::Client::NetworkingError, ArgumentError => e
      Result.new(success: false, message: e.message.to_s.first(500))
    end
  end
end
